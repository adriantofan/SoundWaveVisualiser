//
//  ATVertexAtrinbArray.m
//  SoundWaveVisualiser
//
//  Created by Adrian Tofan  on 09/03/13.
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


#import "ATVertexAttribArray.h"
#import <GLKit/GLKit.h>

@implementation ATVertexAttribArray
-(id)initWithStride:(GLsizeiptr)stride{
  if (self = [super init]) {
    self.stride = stride;
  }
  return self;
}
- (void)prepareToDrawWithAttrib:(GLuint)attrib // ex GLKVertexAttribPosition
            numberOfCoordinates:(GLint)count   //2 
                           data:(const GLvoid*) ptr{
  NSParameterAssert(NULL != ptr);
  glBindBuffer(GL_ARRAY_BUFFER, 0);
  
  glEnableVertexAttribArray(attrib);
  
  glVertexAttribPointer(attrib, count, GL_FLOAT, GL_FALSE, self.stride, ptr);
  #ifdef DEBUG
    {  // Report any errors
      GLenum error = glGetError();
      if(GL_NO_ERROR != error)
      {
        NSLog(@"GL Error: 0x%x", error);
      }
    }
  #endif
}
- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count
{
  glDrawArrays(mode, first, count);
  #ifdef DEBUG
    {  // Report any errors
      GLenum error = glGetError();
      if(GL_NO_ERROR != error)
      {
        NSLog(@"GL Error: 0x%x", error);
      }
    }
  #endif
}

@end
