//
//  GLKContext.m
//  
// http://www.amazon.com/dp/0321741838
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

#import "AGLKContext.h"

@implementation AGLKContext

/////////////////////////////////////////////////////////////////
// This method sets the clear (background) RGBA color.
// The clear color is undefined until this method is called.
- (void)setClearColor:(GLKVector4)clearColorRGBA
{
   clearColor = clearColorRGBA;
   
   NSAssert(self == [[self class] currentContext],
      @"Receiving context required to be current context");
      
   glClearColor(
      clearColorRGBA.r, 
      clearColorRGBA.g, 
      clearColorRGBA.b, 
      clearColorRGBA.a);
}


/////////////////////////////////////////////////////////////////
// Returns the clear (background) color set via -setClearColor:.
// If no clear color has been set via -setClearColor:, the 
// return clear color is undefined.
- (GLKVector4)clearColor
{
   return clearColor;
}


/////////////////////////////////////////////////////////////////
// This method instructs OpenGL ES to set all data in the
// current Context's Render Buffer(s) identified by mask to
// colors (values) specified via -setClearColor: and/or
// OpenGL ES functions for each Render Buffer type.
- (void)clear:(GLbitfield)mask
{
   NSAssert(self == [[self class] currentContext],
      @"Receiving context required to be current context");
      
   glClear(GL_COLOR_BUFFER_BIT);
}


/////////////////////////////////////////////////////////////////
// 
- (void)enable:(GLenum)capability;
{
   NSAssert(self == [[self class] currentContext],
      @"Receiving context required to be current context");
   
   glEnable(capability);
}


/////////////////////////////////////////////////////////////////
// 
- (void)disable:(GLenum)capability;
{
   NSAssert(self == [[self class] currentContext],
      @"Receiving context required to be current context");
      
   glDisable(capability);
}


/////////////////////////////////////////////////////////////////
// 
- (void)setBlendSourceFunction:(GLenum)sfactor 
   destinationFunction:(GLenum)dfactor;
{
   glBlendFunc(sfactor, dfactor);
}

- (void)setLineWidth:(GLfloat)width{
  glLineWidth(width);

}

@end
