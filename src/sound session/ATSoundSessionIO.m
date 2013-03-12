//
//  ATSoundIOSession.m
//  SoundWaveVisualiser
//
//  Created by Adrian Tofan  on 12/03/13.
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

#import "ATSoundSessionIO.h"
#import "ATDCRejectionFilter.h"
#import "ATOSSErrorHelpers.h"



#pragma mark - error helpers declaration


#pragma mark - Callbacks

static OSStatus at_inRenderCallBackProc(	void *							inRefCon,
                                     AudioUnitRenderActionFlags *	ioActionFlags,
                                     const AudioTimeStamp *			inTimeStamp,
                                     UInt32							inBusNumber,
                                     UInt32							inNumberFrames,
                                     AudioBufferList *				ioData){
  ATSoundSessionIO *SELF = (__bridge ATSoundSessionIO *)inRefCon;
  
  OSStatus err = AudioUnitRender( SELF.ioUnit, ioActionFlags, inTimeStamp, 1, inNumberFrames, ioData);
	if (err) { printf("PerformThru: error %d\n", (int)err); return err; }
  
  [SELF.leftChanelFilter  inplaceFilter:(Float32*)ioData->mBuffers[0].mData frameCount:inNumberFrames];
  if (ioData->mNumberBuffers > 1) {
    [SELF.rightChanelFilter  inplaceFilter:(Float32*)ioData->mBuffers[1].mData frameCount:inNumberFrames];
  }
  err = AudioConverterConvertComplexBuffer(SELF.audioConverter,
                                           inNumberFrames,
                                           ioData,
                                           SELF.processABL);
  if (err) {
    NSError* error =  at_checkOSStatusError(err,@"unable to AudioConverterConvertComplexBuffer");
    NSLog(@"Conversion error in render callback %@:",error);
    return err; }
  

  if (SELF.inBlock) {
    if(ioData->mNumberBuffers > 1){
      SELF.inBlock(SELF.processABL->mBuffers[0].mData,SELF.processABL->mBuffers[1].mData,inNumberFrames);
    }else{
      SELF.inBlock(SELF.processABL->mBuffers[0].mData,NULL,inNumberFrames);
    }
  }
  return noErr;
}
@interface ATSoundSessionIO(){
  AudioStreamBasicDescription inputStreamFormat_; // the input element's stream format
}
@end

@implementation ATSoundSessionIO
@synthesize inputStreamFormat = inputStreamFormat_;
@synthesize isProcessingSound = isProcessingSound_;
@synthesize ioUnit = ioUnit_;
@synthesize processingGraph = processingGraph_, processABL = processABL_;
@synthesize processStreamFormat = processStreamFormat_, audioConverter = audioConverter_;
@synthesize leftChanelFilter = leftChanelFilter_,rightChanelFilter = rightChanelFilter_;
;

-(void)dealloc{
  [[AVAudioSession sharedInstance] setActive:YES error:nil];
  if (isProcessingSound_) {
    [self stopSoundProcessing:nil];
  }
  if (processingGraph_) {
    DisposeAUGraph(processingGraph_);
  }
  if (audioConverter_) {
    AudioConverterDispose(audioConverter_);
  }
  if (processABL_) {
    for (UInt32 i=0; i<processABL_->mNumberBuffers; ++i){
      if (processABL_->mBuffers[i].mData) {
        free(processABL_->mBuffers[i].mData);
      }
    }
    free(processABL_);
  }
  ioUnit_ = NULL;
  processingGraph_ = NULL;
  audioConverter_ = NULL;
  processABL_ = NULL;
  leftChanelFilter_ = nil;
  rightChanelFilter_ = nil;

}

-(id)init{
  if (self = [super init]) {
    isProcessingSound_ = NO;
  }
  return self;
}
-(BOOL)prepareSoundProcessingGraph:(NSError**)error{
  return [self initAudioSession:error] && [self initAudioUnits:error];
}


-(BOOL)disposeSoundProcessingGraph:(NSError**)error{
  [[AVAudioSession sharedInstance] setActive:YES error:nil];
  if (isProcessingSound_) {
    [self stopSoundProcessing:error];
  }
  if (processingGraph_) {
    DisposeAUGraph(processingGraph_);
  }
  if (audioConverter_) {
    AudioConverterDispose(audioConverter_);
    audioConverter_ = NULL;
  }
  ioUnit_ = NULL;
  processingGraph_ = NULL;
  
  if (processABL_) {
    for (UInt32 i=0; i<processABL_->mNumberBuffers; ++i){
      if (processABL_->mBuffers[i].mData) {
        free(processABL_->mBuffers[i].mData);
      }
    }
    free(processABL_);
    processABL_ = NULL;
  }
  return isProcessingSound_;
}


-(BOOL)startSoundProcessing:(NSError**)error{
  __block UInt32 maxFPS;
  __block BOOL success = TRUE;
  UInt32 size = sizeof(maxFPS);
  
  void(^errorHandler)(NSError*) = ^(NSError* err){
    if (NULL != error) {
      *error = err;
    }
    success = FALSE;
    isProcessingSound_ = NO;
    if (processABL_) {
      for (UInt32 i=0; i<processABL_->mNumberBuffers; ++i){
        if (processABL_->mBuffers[i].mData) {
          free(processABL_->mBuffers[i].mData);
        }
      }
      free(processABL_);
      processABL_ = NULL;
    }
    if (audioConverter_) {
      AudioConverterDispose(audioConverter_);
      audioConverter_ = NULL;
    }
  };
  
  at_ifNotError(AudioUnitGetProperty(self.ioUnit,
                                  kAudioUnitProperty_MaximumFramesPerSlice,
                                  kAudioUnitScope_Global,
                                  0, &maxFPS,
                                  &size),
             @"unable to get maximum frames per slice in order to allocate process buffers",
             ^{
               // alocate buffers
               processABL_ = (AudioBufferList*) malloc(sizeof(AudioBufferList) + sizeof(AudioBuffer));
               processABL_->mNumberBuffers = 2;
               for (UInt32 i=0; i<processABL_->mNumberBuffers; ++i)
               {
                 processABL_->mBuffers[i].mData = (SInt32*) calloc(maxFPS, sizeof(SInt32));
                 processABL_->mBuffers[i].mDataByteSize = maxFPS * sizeof(SInt32);
                 processABL_->mBuffers[i].mNumberChannels = 1;
               }
               at_ifNotError(AUGraphStart(processingGraph_),
                          @"unable to start audio",
                          ^{
                            UInt32 size = sizeof(inputStreamFormat_);
                            at_ifNotError(AudioUnitGetProperty(ioUnit_,
                                                            kAudioUnitProperty_StreamFormat,
                                                            kAudioUnitScope_Output,
                                                            1,
                                                            &inputStreamFormat_,
                                                            &size),
                                       @"couldn't get the remote I/O unit's output client format",
                                       ^{
                                         at_ifNotError(AudioConverterNew(&inputStreamFormat_, &processStreamFormat_, &audioConverter_)
                                                    , @"couldn't setup AudioConverter",
                                                    ^{
                                                      isProcessingSound_ = YES;
                                                    },
                                                    errorHandler);
                                       },
                                       errorHandler);
                          },
                          errorHandler);
             },
             errorHandler);
  return success;
}

-(BOOL)stopSoundProcessing:(NSError**)error{
  __block BOOL success = TRUE;
  at_ifNotError(AUGraphStop(processingGraph_),
             @"unable to stop audio",
             ^{
               isProcessingSound_ = NO;
             },
             ^(NSError* err){
               success = FALSE;
               if (error) {
                 *error = err;
               }
             });
  if (audioConverter_) {
    AudioConverterDispose(audioConverter_);
    audioConverter_ = NULL;
  }
  if (processABL_) {
    for (UInt32 i=0; i<processABL_->mNumberBuffers; ++i){
      if (processABL_->mBuffers[i].mData) {
        free(processABL_->mBuffers[i].mData);
      }
    }
    free(processABL_);
    processABL_ = NULL;
  }
  return success;
}


-(BOOL)initAudioSession:(NSError**)error{
  // Configure Audio Session
  NSError *errRet;
  self.graphSampleRate = 44100.0;
  self.leftChanelFilter = [[ATDCRejectionFilter alloc] init];
  self.rightChanelFilter = [[ATDCRejectionFilter alloc] init];
  AVAudioSession *session = [ AVAudioSession sharedInstance ];
  // Request the MultiRoute category (1)
  if ([session setPreferredSampleRate:self.graphSampleRate error:&errRet] && !errRet) {
    if ([session setCategory:AVAudioSessionCategoryMultiRoute error:&errRet] && !errRet){
      //      [session setMode:AVAudioSessionModeMeasurement error:&errRet];
      if ([session setPreferredIOBufferDuration:.005 error:&errRet] && !errRet) {
        if ([session setActive:YES error:&errRet] && !errRet) {
          self.graphSampleRate = session.sampleRate;
          return TRUE;
        }
      }
    }
  }
  if (NULL != error) {
    *error = errRet;    
  }
  return FALSE;
}

-(BOOL)initAudioUnits:(NSError**)error{
  __block AUGraph processingGraph;
  // Specify audio units (2)
  
  AudioComponentDescription ioUnitDesc; // IO unit component description for RemoteIO type
  ioUnitDesc.componentType = kAudioUnitType_Output;
  ioUnitDesc.componentSubType = kAudioUnitSubType_RemoteIO;
  ioUnitDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
  ioUnitDesc.componentFlags = 0;
  ioUnitDesc.componentFlagsMask = 0;
  
  int bytesPerSampel = sizeof(AudioUnitSampleType); // 4 bytes
  // Just get a list of floats between -1.0 to 1.0
  inputStreamFormat_ = (AudioStreamBasicDescription){0};
  inputStreamFormat_.mFormatID = kAudioFormatLinearPCM;
  inputStreamFormat_.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
  inputStreamFormat_.mBytesPerPacket = bytesPerSampel;
  inputStreamFormat_.mBytesPerFrame = bytesPerSampel;
  inputStreamFormat_.mFramesPerPacket = 1;
  inputStreamFormat_.mBitsPerChannel = 8 * bytesPerSampel;
  inputStreamFormat_.mChannelsPerFrame = 2;
  inputStreamFormat_.mSampleRate = self.graphSampleRate;
  
  processStreamFormat_ = (AudioStreamBasicDescription){0};
  processStreamFormat_.mFormatID = kAudioFormatLinearPCM;
  processStreamFormat_.mFormatFlags = kAudioFormatFlagsNativeEndian | kAudioFormatFlagIsPacked | kAudioFormatFlagIsFloat | kAudioFormatFlagIsNonInterleaved;
  processStreamFormat_.mBytesPerPacket = bytesPerSampel;
  processStreamFormat_.mBytesPerFrame = bytesPerSampel;
  processStreamFormat_.mFramesPerPacket = 1;
  processStreamFormat_.mBitsPerChannel = 8 * bytesPerSampel;
  processStreamFormat_.mChannelsPerFrame = 2;
  processStreamFormat_.mSampleRate = self.graphSampleRate;
  
  
  AudioUnitElement ioUnitInputElement = 1;
  AudioUnitElement ioUnitOutputElement = 0;
  UInt32 enableInput = 1; // must enable the imput of the unit
  
  __block AURenderCallbackStruct  inRenderProc;
  inRenderProc.inputProc = &at_inRenderCallBackProc;
  inRenderProc.inputProcRefCon = (__bridge void*)self;
  __block AUNode ioNode;
  __block AudioUnit ioUnit;
  
  
  void(^failure)(NSError*) = ^(NSError *err) {
    if (NULL != error) {
      *error = err;
    }
    CAShow(processingGraph);
    if (processingGraph) {
      DisposeAUGraph(processingGraph);
    }
    ioUnit_ = NULL;
    processingGraph_ = NULL;
  };
  // Create graph, than obtain audio units (3)
  at_ifNotError(NewAUGraph(&processingGraph), @"couldn't create AUGraph with NewAUGraph", ^{
    at_ifNotError(AUGraphAddNode(processingGraph, &ioUnitDesc, &ioNode), @"unable to add AUGraphAddNode to augraph", ^{
      at_ifNotError(AUGraphOpen(processingGraph), @"Unable to instantiate audio unit in AUGraphOpen", ^{
        at_ifNotError(AUGraphNodeInfo(processingGraph, ioNode, NULL, &ioUnit), @"Unable to get ioNode from audiograph  with AUGraphNodeInfo", ^{
          at_ifNotError(AudioUnitSetProperty(ioUnit,
                                          kAudioOutputUnitProperty_EnableIO,
                                          kAudioUnitScope_Input,
                                          ioUnitInputElement,
                                          &enableInput,
                                          sizeof(enableInput)),
                     @"unable to enable recording audio AudioUnitSetProperty kAudioOutputUnitProperty_EnableIO",
                     ^{
                       at_ifNotError(AudioUnitSetProperty(ioUnit,
                                                       kAudioUnitProperty_StreamFormat,
                                                       kAudioUnitScope_Output,
                                                       ioUnitInputElement,
                                                       &inputStreamFormat_,
                                                       sizeof(inputStreamFormat_)
                                                       ),
                                  @"unable to set stream format for the input elements output scope",
                                  ^{
                                    at_ifNotError(AudioUnitSetProperty(ioUnit,
                                                                    kAudioUnitProperty_StreamFormat,
                                                                    kAudioUnitScope_Input,
                                                                    ioUnitOutputElement,
                                                                    &inputStreamFormat_,
                                                                    sizeof(inputStreamFormat_)
                                                                    ),
                                               @"unable to set stream format for the input elements output scope",
                                               ^{
                                                 at_ifNotError(AudioUnitSetProperty(ioUnit,
                                                                                 kAudioUnitProperty_SetRenderCallback,
                                                                                 kAudioUnitScope_Input,
                                                                                 ioUnitOutputElement,
                                                                                 &inRenderProc,
                                                                                 sizeof(inRenderProc)),
                                                            @"couldn't set remote i/o render callback",
                                                            ^{
                                                              at_ifNotError(AUGraphInitialize(processingGraph),
                                                                         @"unable to itialize audio graph AUGraphInitialize",
                                                                         ^{
                                                                           ioUnit_ = ioUnit;
                                                                           processingGraph_ = processingGraph;
                                                                           
                                                                         },
                                                                         failure);
                                                            },
                                                            failure);
                                               },
                                               failure);
                                  },
                                  failure);
                     },
                     failure);
        }, failure);
      }, failure);
    }, failure);
  }, failure);
  if (ioUnit_ && processingGraph_) {
    return TRUE;
  }
  return FALSE;
}


@end