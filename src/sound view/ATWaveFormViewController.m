//
//  ATWaveFormViewController.m
//  OpenGLES_Ch2_3
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

#import "ATWaveFormViewController.h"
#import "AGLKVertexAttribArrayBuffer.h"
#import "AGLKContext.h"
#import "ATVertexAttribArray.h"
#pragma mark - osciloscope 

// This determines how slowly the oscilloscope lines fade away from the display.
// Larger numbers = slower fade (and more strain on the graphics processing)

float *drawBuffers[kNumDrawBuffers];
int drawBufferIdx = 0;
const int drawBufferLen = kDefaultDrawSamples;
int drawBufferLen_alloced = 0;
// Assumtions: 1.memmory remains allocated during app lifetime
//             2. only one player at a time is active

void cycleOscilloscopeLines(void){
	// Cycle the lines in our draw buffer so that they age and fade. The oldest line is discarded.
	int drawBuffer_i;
	for (drawBuffer_i=(kNumDrawBuffers - 2); drawBuffer_i>=0; drawBuffer_i--)
		memmove(drawBuffers[drawBuffer_i + 1], drawBuffers[drawBuffer_i], drawBufferLen*sizeof(float));
}
void updateDrawBufferSizes(void){
  if (drawBufferLen != drawBufferLen_alloced)
  {
    int drawBuffer_i;
    
    // Allocate our draw buffer if needed
    if (drawBufferLen_alloced == 0)
      for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
        drawBuffers[drawBuffer_i] = NULL;
    
    // Fill the first element in the draw buffer with PCM data
    for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
    {
      drawBuffers[drawBuffer_i] = (float *)realloc(drawBuffers[drawBuffer_i], drawBufferLen*sizeof(float));
      bzero(drawBuffers[drawBuffer_i], drawBufferLen*sizeof(float));
    }
    drawBufferLen_alloced = drawBufferLen;
  }
}

#pragma mark - OpenGLES_Ch2_3ViewController

@interface ATWaveFormViewController(){
  GLfloat				*	oscilLine_;
  GLKBaseEffect * lineEffect_; // shaders for the line 
}

@end

@implementation ATWaveFormViewController

@synthesize baseEffect = baseEffect_;
@synthesize vertexBuffer = vertexBuffer_;
@synthesize vertexAttribArray = vertexAttribArray_;

-(void)dealloc{
  free(oscilLine_);
  lineEffect_ = nil;
  vertexBuffer_ = nil;
  baseEffect_ = nil;
  vertexAttribArray_ = nil;
}

static const float background[] =
{
  0.0f,   1.0f,  -1.0f, 0.0f, 1.0f, // A
  0.0f,  -1.0f,  -1.0f, 0.0f, 0.0f, // B
  1.0f,  -1.0f,  -1.0f, 1.0f, 0.0f, // C
  1.0f,  -1.0f,  -1.0f, 1.0f, 0.0f, // C
  1.0f,   1.0f,  -1.0f, 1.0f, 1.0f, // D
  0.0f,   1.0f,  -1.0f, 0.0f, 1.0f, // A
};

- (void)viewDidLoad
{
   [super viewDidLoad];
  // Verify the type of view created automatically by the
  // Interface Builder storyboard
  GLKView *view = (GLKView *)self.view;
  NSAssert([view isKindOfClass:[GLKView class]],
           @"View controller's view is not a GLKView");
  [view description];
}

-(void)viewWillAppear:(BOOL)animated{
  [super viewWillAppear:animated];
  GLKView *view = (GLKView *)self.view;
  view.context = [[AGLKContext alloc]
                  initWithAPI:kEAGLRenderingAPIOpenGLES2];
  [AGLKContext setCurrentContext:view.context];
  self.baseEffect = [[GLKBaseEffect alloc] init];
  self.baseEffect.transform.modelviewMatrix =
  GLKMatrix4Scale(GLKMatrix4Translate(GLKMatrix4Identity, -1.0, 0.0, 0.0),2.0,1.0,1.0);
  
  lineEffect_ = [[GLKBaseEffect alloc] init];
  lineEffect_.useConstantColor = GL_TRUE;
  lineEffect_.constantColor = GLKVector4Make(0xa1/255.0f, 0xa9/255.0f, 0xb9/255.0f, 1.0f);
  lineEffect_.transform.modelviewMatrix = self.baseEffect.transform.modelviewMatrix;
  self.vertexBuffer = [[AGLKVertexAttribArrayBuffer alloc]
                       initWithAttribStride:(GLsizeiptr)5*sizeof(float) numberOfVertices:6 bytes:background
                       usage:GL_STATIC_DRAW];
  CGImageRef imageRef = [[UIImage imageNamed:@"IMG_BgGraphique"] CGImage];
  if (imageRef) {
    GLKTextureInfo *textureInfo = [GLKTextureLoader textureWithCGImage:imageRef
                                                               options:@{GLKTextureLoaderOriginBottomLeft:@(YES)}
                                                                 error:NULL];
    self.baseEffect.texture2d0.name = textureInfo.name;
    self.baseEffect.texture2d0.target = textureInfo.target;
  }
  if (!oscilLine_) {
    oscilLine_ = (GLfloat*)malloc(drawBufferLen * 2 * sizeof(GLfloat));
  }
  vertexAttribArray_ = [[ATVertexAttribArray alloc] initWithStride:0];



}
- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect
{
	int drawBuffer_i;
  GLfloat *oscilLine_ptr;
	float *drawBuffer_ptr;
  GLfloat max = drawBufferLen;
  AGLKContext* context = (AGLKContext*)view.context;
  [context enable:GL_BLEND];
  [context setBlendSourceFunction:GL_SRC_ALPHA destinationFunction:GL_ONE_MINUS_SRC_ALPHA];
  
  [self.baseEffect prepareToDraw];
  [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribPosition
                         numberOfCoordinates:3
                                attribOffset:0
                                shouldEnable:YES];
  [self.vertexBuffer prepareToDrawWithAttrib:GLKVertexAttribTexCoord0
                         numberOfCoordinates:2
                                attribOffset:3*sizeof(float)
                                shouldEnable:YES];
  [self.vertexBuffer drawArrayWithMode:GL_TRIANGLES
                      startVertexIndex:0
                      numberOfVertices:6];
	// Draw a line for each stored line in our buffer (the lines are stored and fade over time)
	for (drawBuffer_i=0; drawBuffer_i<kNumDrawBuffers; drawBuffer_i++)
	{
		if (!drawBuffers[drawBuffer_i]) continue;
    float aplha  = 1.0 - (float)(drawBuffer_i+1) * (1.0/(float)kNumDrawBuffers)  ;
		oscilLine_ptr = oscilLine_;
		drawBuffer_ptr = drawBuffers[drawBuffer_i];
		GLfloat i;
		// Fill our vertex array with points
		for (i=0.; i<max; i=i+1.)
		{
			*oscilLine_ptr++ = i/max;
			*oscilLine_ptr++ = (Float32)(*drawBuffer_ptr++);
		}
    [context setLineWidth:2.f];
    lineEffect_.useConstantColor = GL_TRUE;
    lineEffect_.constantColor = GLKVector4Make(0xfc/255.0f, 0x00/255.0f, 0x64/255.0f,aplha);
    [vertexAttribArray_ prepareToDrawWithAttrib:GLKVertexAttribPosition
                            numberOfCoordinates:2
                                           data:oscilLine_];
    [lineEffect_ prepareToDraw];
    [vertexAttribArray_ drawArrayWithMode:GL_LINE_STRIP startVertexIndex:0 numberOfVertices:drawBufferLen];
	}  
}

- (void)viewDidDisappear:(BOOL)animated{
  [super viewDidDisappear:animated];
  self.vertexBuffer = nil;
  
  ((GLKView *)self.view).context = nil;
  [EAGLContext setCurrentContext:nil];
  self.baseEffect = nil;
  lineEffect_ = nil;
}

@end
