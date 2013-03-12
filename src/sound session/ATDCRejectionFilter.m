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

#import "ATDCRejectionFilter.h"

const Float32 kDefaultPoleDist = 0.975f;
@interface ATDCRejectionFilter (){
  Float32	mY1;
  Float32 mX1;
}
@end


@implementation ATDCRejectionFilter
-(id)init{
  if (self = [super init]) {
    mX1 = 0.0;
    mY1 = 0.0f;
  }
  return self;
}

-(void) inplaceFilter:(Float32*) ioData frameCount:(UInt32) numFrames
{
	for (UInt32 i=0; i < numFrames; i++)
	{
    Float32 xCurr = ioData[i];
		ioData[i] = ioData[i] - mX1 + (kDefaultPoleDist * mY1);
    mX1 = xCurr;
    mY1 = ioData[i];
	}
}

@end