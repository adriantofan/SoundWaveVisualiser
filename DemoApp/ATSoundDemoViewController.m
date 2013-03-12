//
//  ATViewController.m
//  SoundWaveVisualiser
//
//  Created by Adrian Tofan  on 05/03/13.
//  Copyright (c) 2013 Adrian Tofan . 
// 
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.

#import "ATSoundDemoViewController.h"
#import "ATWaveFormViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "ATSoundSessionIO.h"
#import "ATWaveFormViewController.h"


#pragma mark - ATViewController
@interface ATSoundDemoViewController ()

@property (nonatomic) ATSoundSessionIO *soundSessionIO;
@property (nonatomic) ATWaveFormViewController* waveformController;
@end

@implementation ATSoundDemoViewController
@synthesize waveformController = waveformController_;
@synthesize soundSessionIO = soundSessionIO_;

-(void)dealloc{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVAudioSessionRouteChangeNotification" object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVAudioSessionInterruptionNotification" object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVAudioSessionMediaServicesWereResetNotification" object:nil];
  waveformController_ = nil;
  [soundSessionIO_ disposeSoundProcessingGraph:nil];
  soundSessionIO_ = nil;
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"waveFormControllerSegueIdentifier"]) {
    self.waveformController = segue.destinationViewController;
  }
}


- (void)viewDidLoad
{
  [super viewDidLoad];
  soundSessionIO_ = [[ATSoundSessionIO alloc] init];
  if([soundSessionIO_ prepareSoundProcessingGraph:nil]){
    [soundSessionIO_ startSoundProcessing:nil];
  }
  soundSessionIO_.inBlock = ^OSStatus(Float32* left, Float32*right, UInt32 inNumberFrames){
    //  float volume = 0.5;
    //  vDSP_vsmul(data, 1, &volume, data, 1, numFrames*numChannels);
    //  THIS.ringBuffer->AddNewInterleavedFloatData(data, numFrames, numChannels);
    Float32 *data = left;
    int i;
    updateDrawBufferSizes(); // sync allocated memory for drawbuffers
    for (i=0; i<inNumberFrames; i++)
    {
      if ((i+drawBufferIdx) >= drawBufferLen)
      {
        cycleOscilloscopeLines();
        drawBufferIdx = -i;
      }
      drawBuffers[0][i + drawBufferIdx] = data[0];
      data += 1;
    }
    drawBufferIdx += inNumberFrames;
    return noErr;
  };

}

-(void)viewWillAppear:(BOOL)animated{
  AVAudioSession *session = [ AVAudioSession sharedInstance ];
  // Register for Route Change notifications
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector(handleRouteChange:)
                                               name: AVAudioSessionRouteChangeNotification
                                             object: session];
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector(handleInterruption:)
                                               name: AVAudioSessionInterruptionNotification
                                             object: session];
  [[NSNotificationCenter defaultCenter] addObserver: self
                                           selector: @selector(handleMediaServicesWereReset:)
                                               name: AVAudioSessionMediaServicesWereResetNotification
                                             object: session];
}

-(void)viewDidDisappear:(BOOL)animated{
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVAudioSessionRouteChangeNotification" object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVAudioSessionInterruptionNotification" object:nil];
  [[NSNotificationCenter defaultCenter] removeObserver:self name:@"AVAudioSessionMediaServicesWereResetNotification" object:nil];
  [soundSessionIO_ disposeSoundProcessingGraph:nil];
  [super viewDidDisappear:animated];
}




-(void)handleMediaServicesWereReset:(NSNotification*)notification{
//  If the media server resets for any reason, handle this notification to reconfigure audio or do any housekeeping, if necessary
//    • No userInfo dictionary for this notification
//      • Audio streaming objects are invalidated (zombies)
//      • Handle this notification by fully reconfiguring audio
  NSLog(@"handleMediaServicesWereReset: %@ ",[notification name]);
}


-(void)handleInterruption:(NSNotification*)notification{
  NSInteger reason = 0;
  NSString* reasonStr=@"";
  if ([notification.name isEqualToString:@"AVAudioSessionInterruptionNotification"]) {
    //Posted when an audio interruption occurs.
     reason = [[[notification userInfo] objectForKey:@" AVAudioSessionInterruptionTypeKey"] integerValue];
    if (reason == AVAudioSessionInterruptionTypeBegan) {
//       Audio has stopped, already inactive
//       Change state of UI, etc., to reflect non-playing state
      if(soundSessionIO_.isProcessingSound)[soundSessionIO_ stopSoundProcessing:nil];
    }
    
    if (reason == AVAudioSessionInterruptionTypeEnded) {
//       Make session active
//       Update user interface
//       AVAudioSessionInterruptionOptionShouldResume option
      reasonStr = @"AVAudioSessionInterruptionTypeEnded";
      NSNumber* seccondReason = [[notification userInfo] objectForKey:@"AVAudioSessionInterruptionOptionKey"] ;
      switch ([seccondReason integerValue]) {
        case AVAudioSessionInterruptionOptionShouldResume:
//          Indicates that the audio session is active and immediately ready to be used. Your app can resume the audio operation that was interrupted.
          break;
        default:
          break;
      }
    }

    
    if ([notification.name isEqualToString:@"AVAudioSessionDidBeginInterruptionNotification"]) {
      if (soundSessionIO_.isProcessingSound) {
        
      }
//      Posted after an interruption in your audio session occurs.
//      This notification is posted on the main thread of your app. There is no userInfo dictionary.
    }
    if ([notification.name isEqualToString:@"AVAudioSessionDidEndInterruptionNotification"]) {
//      Posted after an interruption in your audio session ends.
//      This notification is posted on the main thread of your app. There is no userInfo dictionary.
    }
    if ([notification.name isEqualToString:@"AVAudioSessionInputDidBecomeAvailableNotification"]) {
//      Posted when an input to the audio session becomes available.
//      This notification is posted on the main thread of your app. There is no userInfo dictionary.
    }
    if ([notification.name isEqualToString:@"AVAudioSessionInputDidBecomeUnavailableNotification"]) {
//      Posted when an input to the audio session becomes unavailable.
//      This notification is posted on the main thread of your app. There is no userInfo dictionary.
    }
    
  };
  NSLog(@"handleInterruption: %@ reason %@",[notification name],reasonStr);
}

-(void)handleRouteChange:(NSNotification*)notification{
  AVAudioSession *session = [ AVAudioSession sharedInstance ];
  NSString* seccReason = @"";
  NSInteger  reason = [[[notification userInfo] objectForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
//  AVAudioSessionRouteDescription* prevRoute = [[notification userInfo] objectForKey:AVAudioSessionRouteChangePreviousRouteKey];
  switch (reason) {
    case AVAudioSessionRouteChangeReasonNoSuitableRouteForCategory:
      seccReason = @"The route changed because no suitable route is now available for the specified category.";
      break;
    case AVAudioSessionRouteChangeReasonWakeFromSleep:
      seccReason = @"The route changed when the device woke up from sleep.";
      break;
    case AVAudioSessionRouteChangeReasonOverride:
      seccReason = @"The output route was overridden by the app.";
      break;
    case AVAudioSessionRouteChangeReasonCategoryChange:
      seccReason = @"The category of the session object changed.";
      break;
    case AVAudioSessionRouteChangeReasonOldDeviceUnavailable:
      seccReason = @"The previous audio output path is no longer available.";
      break;
    case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
      seccReason = @"A preferred new audio output path is now available.";
      break;
    case AVAudioSessionRouteChangeReasonUnknown:
    default:
      seccReason = @"The reason for the change is unknown.";
      break;
  }
  AVAudioSessionPortDescription *input = [[session.currentRoute.inputs count]?session.currentRoute.inputs:nil objectAtIndex:0];
  if (input.portType == AVAudioSessionPortHeadsetMic) {
    
  }
}



@end
