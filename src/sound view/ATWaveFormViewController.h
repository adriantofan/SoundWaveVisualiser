//
//  ATWaveFormViewController.h
//  ATWaveFormViewController
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

#import <GLKit/GLKit.h>
#define kNumDrawBuffers 3
#define kDefaultDrawSamples 10240
#if __cplusplus
extern "C" {
#endif
extern void cycleOscilloscopeLines(void);
extern void updateDrawBufferSizes(void);
#if __cplusplus
}
#endif

float extern *drawBuffers[];
int extern drawBufferIdx;
const int extern drawBufferLen;
int extern drawBufferLen_alloced;

@class AGLKVertexAttribArrayBuffer,ATVertexAttribArray;


@interface ATWaveFormViewController : GLKViewController

@property (strong, nonatomic) GLKBaseEffect 
   *baseEffect;
@property (strong, nonatomic) AGLKVertexAttribArrayBuffer 
   *vertexBuffer;
@property (strong, nonatomic) ATVertexAttribArray *vertexAttribArray;
@end
