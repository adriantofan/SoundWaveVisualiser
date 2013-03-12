//
//  ATSoundIOSession.h
//  SoundWaveVisualiser
//
//  Created by Adrian Tofan  on 12/03/13.
//  Copyright (c) 2013 Adrian Tofan .
//
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


#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AVFoundation/AVFoundation.h>

@class ATDCRejectionFilter;

@interface ATSoundSessionIO : NSObject
@property (nonatomic, assign) AudioUnit ioUnit;
@property (nonatomic, assign) AudioStreamBasicDescription inputStreamFormat; // the input element's stream format
@property (nonatomic, assign) AudioStreamBasicDescription processStreamFormat; // the input element's stream format
@property (nonatomic, assign) AudioBufferList *processABL;
@property (nonatomic, assign) AudioConverterRef audioConverter;
@property (nonatomic,readonly) BOOL isProcessingSound;
@property (nonatomic) ATDCRejectionFilter* leftChanelFilter;
@property (nonatomic) ATDCRejectionFilter* rightChanelFilter;
@property (nonatomic) double graphSampleRate;
@property (nonatomic) AUGraph processingGraph;
@property (nonatomic,copy) OSStatus(^inBlock)(Float32* left, Float32*right, UInt32 inNumberFrames);

-(BOOL)startSoundProcessing:(NSError**)error;
-(BOOL)stopSoundProcessing:(NSError**)error;
-(BOOL)prepareSoundProcessingGraph:(NSError**)error;
-(BOOL)disposeSoundProcessingGraph:(NSError**)error;

@end
