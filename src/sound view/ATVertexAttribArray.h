//
//  ATVertexAtrinbArray.h
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

#import <Foundation/Foundation.h>
// Simple class used to draw Vertex attrib array stored in system's memmory

@interface ATVertexAttribArray : NSObject
@property (nonatomic, assign) GLsizei
stride;
-(id)initWithStride:(GLsizeiptr)stride;

// Will prepare to draw a buffer of vertices stored in system's memmory
- (void)prepareToDrawWithAttrib:(GLuint)attrib 
            numberOfCoordinates:(GLint)count 
                           data:(const GLvoid*) ptr;

- (void)drawArrayWithMode:(GLenum)mode
         startVertexIndex:(GLint)first
         numberOfVertices:(GLsizei)count;

@end
