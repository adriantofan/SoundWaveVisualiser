//
//  ATOSSErrorHelpers.h
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

#ifdef __cplusplus
extern "C" {
#endif
  
static inline NSError* at_checkOSStatusError(OSStatus error, NSString *operation);
static inline void at_ifNotError(OSStatus errorCode, NSString *operation,void(^success )(void),void(^failure)(NSError* err));

#ifdef __cplusplus
}
#endif

static inline NSError* at_checkOSStatusError(OSStatus error, NSString *operation)
{
	if (error == noErr) return  nil;
	
	char str[20];
	// see if it appears to be a 4-char-code
	*(UInt32 *)(str + 1) = CFSwapInt32HostToBig(error);
	if (isprint(str[1]) && isprint(str[2]) && isprint(str[3]) && isprint(str[4])) {
		str[0] = str[5] = '\'';
		str[6] = '\0';
	} else
		// no, format it as an integer
		sprintf(str, "%d", (int)error);
  NSError *err = [NSError errorWithDomain:[NSString stringWithCString:str encoding:NSUTF8StringEncoding]
                                     code:0
                                 userInfo:nil];
  return err;
}

static inline void at_ifNotError(OSStatus errorCode, NSString *operation,void(^success )(void),void(^failure)(NSError* err)){
  NSError* result;
  if ((result = at_checkOSStatusError(errorCode, operation))) {
    failure?failure(result):(void)NULL;
  }else{
    success?success():(void)NULL;
  }
}
