//========================================================================
// OpenGL ES 2.0 triangle example
// Copyright (c) Camilla Löwy <elmindreda@glfw.org>
//
// This software is provided 'as-is', without any express or implied
// warranty. In no event will the authors be held liable for any damages
// arising from the use of this software.
//
// Permission is granted to anyone to use this software for any purpose,
// including commercial applications, and to alter it and redistribute it
// freely, subject to the following restrictions:
//
// 1. The origin of this software must not be misrepresented; you must not
//    claim that you wrote the original software. If you use this software
//    in a product, an acknowledgment in the product documentation would
//    be appreciated but is not required.
//
// 2. Altered source versions must be plainly marked as such, and must not
//    be misrepresented as being the original software.
//
// 3. This notice may not be removed or altered from any source
//    distribution.
//
//========================================================================

//#define GLAD_GLES2_IMPLEMENTATION
//#include <glad/gles2.h>
#define GLFW_INCLUDE_NONE
#define GLFW_EXPOSE_NATIVE_COCOA
#include <GLFW/glfw3.h>
#include <GLFW/glfw3native.h>

#include "linmath.h"

#include <stdlib.h>
#include <stddef.h>
#include <stdio.h>

//#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES2/gl.h>

#include <dlfcn.h>

typedef struct Vertex
{
    vec2 pos;
    vec3 col;
} Vertex;

static const Vertex vertices[3] =
{
    { { -0.6f, -0.4f }, { 1.f, 0.f, 0.f } },
    { {  0.6f, -0.4f }, { 0.f, 1.f, 0.f } },
    { {   0.f,  0.6f }, { 0.f, 0.f, 1.f } }
};

static const char* vertex_shader_text =
"#version 100\n"
"precision mediump float;\n"
"uniform mat4 MVP;\n"
"attribute vec3 vCol;\n"
"attribute vec2 vPos;\n"
"varying vec3 color;\n"
"void main()\n"
"{\n"
"    gl_Position = MVP * vec4(vPos, 0.0, 1.0);\n"
"    color = vCol;\n"
"}\n";

static const char* fragment_shader_text =
"#version 100\n"
"precision mediump float;\n"
"varying vec3 color;\n"
"void main()\n"
"{\n"
"    gl_FragColor = vec4(color, 1.0);\n"
"}\n";

static void error_callback(int error, const char* description)
{
    fprintf(stderr, "GLFW Error: %s\n", description);
}

static void key_callback(GLFWwindow* window, int key, int scancode, int action, int mods)
{
    if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS)
        glfwSetWindowShouldClose(window, GLFW_TRUE);
}

static void* molten;

void (*resolver(const char* name))(void) {
    printf("GLES %s\n", name);
    void (*ret)(void) = (void (*)(void))dlsym(molten, name);
    printf("GLES %i\n", (int)ret);
    return ret;
}

int main(void)
{
    glfwSetErrorCallback(error_callback);

    if (!glfwInit())
        exit(EXIT_FAILURE);

    glfwWindowHint(GLFW_CLIENT_API, GLFW_NO_API);

    GLFWwindow* window = glfwCreateWindow(640, 480, "OpenGL ES 2.0 Triangle (EGL)", NULL, NULL);
    if (!window)
    {
        glfwTerminate();
        exit(EXIT_FAILURE);
    }

    id nativewindow = glfwGetCocoaWindow(window);
    id nativeview = [nativewindow contentView];
    if (!nativeview)
    {
       return -1;
    }

    NSBundle* bundle = [NSBundle bundleWithPath:@"/System/Library/Frameworks/QuartzCore.framework"];
    if (!bundle)
    {
       return -1;
    }

    id nativelayer = [[bundle classNamed:@"CAMetalLayer"] layer];
    if (!nativelayer)
    {
        return -1;
    }

    [nativelayer setContentsScale:[nativewindow backingScaleFactor]];

    [nativeview setLayer:nativelayer];
    [nativeview setWantsLayer:YES];
    /*id _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context || ![EAGLContext setCurrentContext:_context])
    {
        return -1;
    }*/
    EAGLContext* _context = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext: _context];
    printf("moltengl context created\n");

    //glfwMakeContextCurrent(window);
    //gladLoadGLES2(glfwGetProcAddress); TODO make this work
    /*molten = dlopen("libMoltenGL.dylib", RTLD_LAZY);
    if(!molten) {
        printf("failed to open moltengl\n");
        return 1;
    }*/
    //resolver("glGetString")()
    //gladLoadGLES2(resolver);

    //GL_MINOR_VERSION

    GLuint _colorRenderbuffer;
    GLuint _depthRenderbuffer;

    // Create default framebuffer object. The backing will be allocated for the
    // current layer in -resizeFromLayer
    GLuint defaultFBOName;
	glGenFramebuffers(1, &defaultFBOName);

	glGenRenderbuffers(1, &_colorRenderbuffer);
	glBindFramebuffer(GL_FRAMEBUFFER, defaultFBOName);
	glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
    printf("1\n");
	
	// This call associates the storage for the current render buffer with the
    // EAGLDrawable (our CAEAGLLayer) allowing us to draw into a buffer that
    // will later be rendered to the screen wherever the layer is (which
    // corresponds with our view).
	[_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:nativelayer];
	printf("2\n");

	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer);

    printf("3\n");
    // Get the drawable buffer's width and height so we can create a depth buffer for the FBO
	GLint backingWidth;
	GLint backingHeight;
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
	glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
    printf("4\n");
    // Create a depth buffer to use with our drawable FBO
	glGenRenderbuffers(1, &_depthRenderbuffer);
	glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer);
	glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, backingWidth, backingHeight);
	glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer);
	
	if(glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE)
	{
		NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatus(GL_FRAMEBUFFER));
		return -1;
	}

    glfwSetKeyCallback(window, key_callback);

    //glGetIntegerv(GL_MAJOR_VERSION, &major );
    
    //glfwSwapInterval(1);

    GLuint vertex_buffer;
    glGenBuffers(1, &vertex_buffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertex_buffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);

    const GLuint vertex_shader = glCreateShader(GL_VERTEX_SHADER);
    glShaderSource(vertex_shader, 1, &vertex_shader_text, NULL);
    glCompileShader(vertex_shader);

    const GLuint fragment_shader = glCreateShader(GL_FRAGMENT_SHADER);
    glShaderSource(fragment_shader, 1, &fragment_shader_text, NULL);
    glCompileShader(fragment_shader);

    const GLuint program = glCreateProgram();
    glAttachShader(program, vertex_shader);
    glAttachShader(program, fragment_shader);
    glLinkProgram(program);

    const GLint mvp_location = glGetUniformLocation(program, "MVP");
    const GLint vpos_location = glGetAttribLocation(program, "vPos");
    const GLint vcol_location = glGetAttribLocation(program, "vCol");

    glEnableVertexAttribArray(vpos_location);
    glEnableVertexAttribArray(vcol_location);
    glVertexAttribPointer(vpos_location, 2, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (void*) offsetof(Vertex, pos));
    glVertexAttribPointer(vcol_location, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (void*) offsetof(Vertex, col));

    while (!glfwWindowShouldClose(window))
    {
	    glBindFramebuffer(GL_FRAMEBUFFER, defaultFBOName);
        int width, height;
        glfwGetFramebufferSize(window, &width, &height);
        const float ratio = width / (float) height;

        glViewport(0, 0, width, height);
        glClear(GL_COLOR_BUFFER_BIT);

        mat4x4 m, p, mvp;
        mat4x4_identity(m);
        mat4x4_rotate_Z(m, m, (float) glfwGetTime());
        mat4x4_ortho(p, -ratio, ratio, -1.f, 1.f, 1.f, -1.f);
        mat4x4_mul(mvp, p, m);

        glUseProgram(program);
        glUniformMatrix4fv(mvp_location, 1, GL_FALSE, (const GLfloat*) &mvp);
        glDrawArrays(GL_TRIANGLES, 0, 3);

        // glfwSwapBuffers(window);
        glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer);
        [_context presentRenderbuffer:GL_RENDERBUFFER];
        glfwPollEvents();
    }

    glfwDestroyWindow(window);

    glfwTerminate();
    exit(EXIT_SUCCESS);
}

