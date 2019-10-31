//
//  GLView.m
//  双滤镜
//
//  Created by zhengqiankun on 2019/9/3.
//  Copyright © 2019年 zhengqiankun. All rights reserved.
//

#import "GLView.h"
#import "SaturationFilter.h"
#import "TemperatureFilter.h"
#import "GrayScaleFilter.h"
@import OpenGLES;
//顶点结构体
typedef struct
{
    float position[4];//顶点x,y,z,w
    float textureCoordinate[2];//纹理 s,t
} CustomVertex;
//属性枚举
enum
{
    ATTRIBUTE_POSITION = 0,//属性_顶点
    ATTRIBUTE_INPUT_TEXTURE_COORDINATE,//属性_输入纹理坐标
    TEMP_ATTRIBUTE_POSITION,//色温_属性_顶点位置
    TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE,//色温_属性_输入纹理坐标
    GRAY_ATTRIBUTE_POSITION,//灰度顶点坐标
    GRAY_ATTRIBUTE_INPUT_TEXTURE_COORDINATE,//灰度纹理坐标
    NUM_ATTRIBUTES//属性个数
};

//属性数组
GLint glViewAttributes[NUM_ATTRIBUTES];

enum
{
    UNIFORM_INPUT_IMAGE_TEXTURE = 0,//输入纹理
    TEMP_UNIFORM_INPUT_IMAGE_TEXTURE,//色温_输入纹理
    GRAY_UNIFORM_INPUT_IMAGE_TEXTURE,//灰度输入纹理
    UNIFORM_TEMPERATURE,//色温
    UNIFORM_SATURATION,//饱和度
    
    NUM_UNIFORMS//Uniforms个数
};

//Uniforms数组
GLint glViewUniforms[NUM_UNIFORMS];

@implementation GLView
#pragma mark - Life Cycle
- (void)dealloc {
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    _context = nil;
}

#pragma mark - Override
// 想要显示 OpenGL 的内容, 需要把它缺省的 layer 设置为一个特殊的 layer(CAEAGLLayer).
+ (Class)layerClass {
    return [CAEAGLLayer class];
}

#pragma mark - Setup
- (void)setup {

    //1.设置色温和饱和度
    [self setupData];
    //2.设置图层
    [self setupLayer];
    //3.设置图形上下文
    [self setupContext];
    //4.设置renderBuffer
    [self setupRenderBuffer];
    //5.设置frameBuffer
    [self setupFrameBuffer];

    //6.检查FrameBuffer
    NSError *error;
    NSAssert1([self checkFramebuffer:&error], @"%@",error.userInfo[@"ErrorMessage"]);

    //7.链接shader 色温
    [self compileTemperatureShaders];

    //8.链接shader 饱和度
    [self compileSaturationShaders];
    [self compileGrayShaders];//灰度
    //9.设置VBO (Vertex Buffer Objects)
    [self setupVBOs];

    //10.设置纹理
    [self setupSatu];
    [self setupGray];
}

- (void)setupData {
    _temperature = 0.5;
    _saturation = 0.5;
}
//设置图层
- (void)setupLayer {
    // 用于显示的layer
    _eaglLayer = (CAEAGLLayer *)self.layer;
    //  CALayer默认是透明的，而透明的层对性能负荷很大。所以将其关闭。
    _eaglLayer.opaque = YES;
}


//设置图形上下文
- (void)setupContext {
    if (!_context) {
        // 创建GL环境上下文
        // EAGLContext 管理所有通过 OpenGL 进行 Draw 的信息.
        _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    }
    NSAssert(_context && [EAGLContext setCurrentContext:_context], @"初始化GL环境失败");
}

//设置RenderBuffer
- (void)setupRenderBuffer {
    // 释放旧的 renderbuffer
    if (_renderbuffer) {
        glDeleteRenderbuffers(1, &_renderbuffer);
        _renderbuffer = 0;
    }
    // 生成renderbuffer ( renderbuffer = 用于展示的窗口 )
    glGenRenderbuffers(1, &_renderbuffer);
    // 绑定renderbuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);
    // GL_RENDERBUFFER 的内容存储到实现 EAGLDrawable 协议的 CAEAGLLayer
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}

//设置FrameBuffer
- (void)setupFrameBuffer {
    // 释放旧的 framebuffer
    if (_framebuffer) {
        glDeleteFramebuffers(1, &_framebuffer);
        _framebuffer = 0;
    }
    // 生成 framebuffer ( framebuffer = 画布 )
    glGenFramebuffers(1, &_framebuffer);
    // 绑定 fraembuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    // framebuffer 不对绘制的内容做存储, 所以这一步是将 framebuffer 绑定到 renderbuffer ( 绘制的结果就存在 renderbuffer )
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _renderbuffer);
}

- (void)setupVBOs {
    //顶点坐标和纹理坐标
    static const CustomVertex vertices[] =
    {
        { .position = { -1.0, -1.0, 0, 1 }, .textureCoordinate = { 0.0, 0.0 } },
        { .position = {  1.0, -1.0, 0, 1 }, .textureCoordinate = { 1.0, 0.0 } },
        { .position = { -1.0,  1.0, 0, 1 }, .textureCoordinate = { 0.0, 1.0 } },
        { .position = {  1.0,  1.0, 0, 1 }, .textureCoordinate = { 1.0, 1.0 } }
    };
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertices), vertices, GL_STATIC_DRAW);
}

#pragma mark - Private
- (BOOL)checkFramebuffer:(NSError *__autoreleasing *)error {

    // 检查 framebuffer 是否创建成功
    GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    NSString *errorMessage = nil;
    BOOL result = NO;
    switch (status)
    {
        case GL_FRAMEBUFFER_UNSUPPORTED:
            errorMessage = @"framebuffer不支持该格式";
            result = NO;
            break;
        case GL_FRAMEBUFFER_COMPLETE:
            NSLog(@"framebuffer 创建成功");
            result = YES;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT:
            errorMessage = @"Framebuffer不完整 缺失组件";
            result = NO;
            break;
        case GL_FRAMEBUFFER_INCOMPLETE_DIMENSIONS:
            errorMessage = @"Framebuffer 不完整, 附加图片必须要指定大小";
            result = NO;
            break;
        default:
            // 一般是超出GL纹理的最大限制
            errorMessage = @"未知错误 error !!!!";
            result = NO;
            break;
    }
    NSLog(@"%@",errorMessage ? errorMessage : @"");
    *error = errorMessage ? [NSError errorWithDomain:@"com.Yue.error"
                                                code:status
                                            userInfo:@{@"ErrorMessage" : errorMessage}] : nil;
    return result;
}



//色温处理shaders编译
- (void)compileTemperatureShaders {
    _temprogramHandle=[TemperatureFilter compileTemperatureShaders];

    //使用program
    glUseProgram(_temprogramHandle);
    //顶点坐标
    glViewAttributes[ATTRIBUTE_POSITION] = glGetAttribLocation(_temprogramHandle, "position");
    //输入的纹理坐标
    glViewAttributes[ATTRIBUTE_INPUT_TEXTURE_COORDINATE]  = glGetAttribLocation(_temprogramHandle, "inputTextureCoordinate");

    glViewUniforms[UNIFORM_INPUT_IMAGE_TEXTURE] = glGetUniformLocation(_temprogramHandle, "inputImageTexture");
    //色温值
    glViewUniforms[UNIFORM_TEMPERATURE] = glGetUniformLocation(_temprogramHandle, "temperature");
    glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_POSITION]);
    glEnableVertexAttribArray(glViewAttributes[ATTRIBUTE_INPUT_TEXTURE_COORDINATE]);

}

//饱和度
- (void)compileSaturationShaders {

    _satuProgramHandle=[SaturationFilter compileSaturationShaders];

    //使用program
    glUseProgram(_satuProgramHandle);
    //顶点坐标
    glViewAttributes[TEMP_ATTRIBUTE_POSITION] = glGetAttribLocation(_satuProgramHandle, "position");
    glViewAttributes[TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE]  = glGetAttribLocation(_satuProgramHandle, "inputTextureCoordinate");
    glViewUniforms[TEMP_UNIFORM_INPUT_IMAGE_TEXTURE] = glGetUniformLocation(_satuProgramHandle, "inputImageTexture");

    //饱和度值
    glViewUniforms[UNIFORM_SATURATION] = glGetUniformLocation(_satuProgramHandle, "saturation");
glEnableVertexAttribArray(glViewAttributes[TEMP_ATTRIBUTE_POSITION]);
    glEnableVertexAttribArray(glViewAttributes[TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE]);

}
//灰度
-(void)compileGrayShaders{
    _grayProgramHandle=[GrayScaleFilter compileTemperatureShaders];
    //使用program
    glUseProgram(_grayProgramHandle);
    //顶点坐标
    glViewAttributes[GRAY_ATTRIBUTE_POSITION] = glGetAttribLocation(_grayProgramHandle, "position");
    glViewAttributes[GRAY_ATTRIBUTE_INPUT_TEXTURE_COORDINATE]  = glGetAttribLocation(_grayProgramHandle, "inputTextureCoordinate");
    glViewUniforms[GRAY_UNIFORM_INPUT_IMAGE_TEXTURE] = glGetUniformLocation(_grayProgramHandle, "inputImageTexture");
    glEnableVertexAttribArray(glViewAttributes[GRAY_ATTRIBUTE_POSITION]);
    glEnableVertexAttribArray(glViewAttributes[GRAY_ATTRIBUTE_INPUT_TEXTURE_COORDINATE]);

}
#pragma mark - Public
- (void)layoutGLViewWithImage:(UIImage *)image {
    //1.设置
    [self setup];

    //2.设置纹理图片
    [self setupTextureWithImage:image];

    //3.渲染
    [self render];

}

//设置色温
- (void)setTemperature:(CGFloat)temperature {
    //1.更新色温
    _temperature = temperature;
    //2.重新渲染
    [self render];
}

//设置饱和度
- (void)setSaturation:(CGFloat)saturation {
    //1.更新饱和度
    _saturation = saturation;
    //2.重新渲染
    [self render];
}
//设置纹理从图片
- (void)setupTextureWithImage:(UIImage *)image {
    //1.获取图片宽\高
    size_t width = CGImageGetWidth(image.CGImage);
    size_t height = CGImageGetHeight(image.CGImage);
    //2.获取颜色组件
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    //3.计算图片数据大小->开辟空间
    void *imageData = malloc( height * width * 4 );
    CGContextRef context = CGBitmapContextCreate(imageData,
                                                 width,
                                                 height,
                                                 8,
                                                 4 * width,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    //创建完context,可以释放颜色空间colorSpace
    CGColorSpaceRelease( colorSpace );
    CGContextClearRect( context, CGRectMake( 0, 0, width, height ) );
    CGContextTranslateCTM(context, 0, height);
    //缩小
    CGContextScaleCTM (context, 1.0,-1.0);

    //绘制图片
    CGContextDrawImage( context, CGRectMake( 0, 0, width, height ), image.CGImage );

    //释放context
    CGContextRelease(context);

    //生成纹理标记
    glGenTextures(1, &_texture);

    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, _texture);

    //设置纹理参数
    //环绕方式
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    //放大\缩小过滤
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER,GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER,GL_LINEAR);
    glTexImage2D(GL_TEXTURE_2D,
                 0,
                 GL_RGBA,
                 (GLint)width,
                 (GLint)height,
                 0,
                 GL_RGBA,
                 GL_UNSIGNED_BYTE,
                 imageData);
    free(imageData);

}
- (void)setupSatu {
    //申请_tempFramesBuffe标记
    glGenFramebuffers(1, &_satuFramebuffer);

    glGenTextures(1, &_satuTexture);
    glBindTexture(GL_TEXTURE_2D, _satuTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindFramebuffer(GL_FRAMEBUFFER, _satuFramebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _satuTexture, 0);
}
-(void)setupGray{
    //申请_tempFramesBuffe标记
    glGenFramebuffers(1, &_grayFramebuffer);

    glGenTextures(1, &_grayTexture);
    glBindTexture(GL_TEXTURE_2D, _grayTexture);
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glBindFramebuffer(GL_FRAMEBUFFER, _grayFramebuffer);
    glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, _grayTexture, 0);
}



#pragma 编译Program


-(void)grayProgram{
    glUseProgram(_grayProgramHandle);
    //绑定frameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _grayFramebuffer);
    //设置视口
    glViewport(0, 0, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor);

    //设置清屏颜色
    glClearColor(0, 0, 1, 1);

    //清理屏幕
    glClear(GL_COLOR_BUFFER_BIT);

    //纹理
    //在绑定纹理之前,激活纹理单元 glActiveTexture
    glActiveTexture(GL_TEXTURE1);
    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, _satuTexture);
    glUniform1i(glViewUniforms[GRAY_UNIFORM_INPUT_IMAGE_TEXTURE], 1);


    //顶点数据
    glVertexAttribPointer(glViewAttributes[GRAY_ATTRIBUTE_POSITION], 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
    //纹理数据
    glVertexAttribPointer(glViewAttributes[GRAY_ATTRIBUTE_INPUT_TEXTURE_COORDINATE], 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid *)(sizeof(float) * 4));

    //绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}
-(void)satuProgram{
    //先将第一个正常的图片纹理加载到_tempFramebuffer
    //绘制第一个滤镜
    //使用program
    glUseProgram(_satuProgramHandle);
    //绑定frameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _satuFramebuffer);
    //设置视口
    glViewport(0, 0, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor);

    //设置清屏颜色
    glClearColor(0, 0, 1, 1);

    //清理屏幕
    glClear(GL_COLOR_BUFFER_BIT);

    //纹理
    //在绑定纹理之前,激活纹理单元 glActiveTexture
    glActiveTexture(GL_TEXTURE1);
    //绑定纹理
    glBindTexture(GL_TEXTURE_2D, _texture);
    glUniform1i(glViewUniforms[TEMP_UNIFORM_INPUT_IMAGE_TEXTURE], 1);
    //饱和度
    glUniform1f(glViewUniforms[UNIFORM_SATURATION], _saturation);

    //顶点数据
    glVertexAttribPointer(glViewAttributes[TEMP_ATTRIBUTE_POSITION], 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
    //纹理数据
    glVertexAttribPointer(glViewAttributes[TEMP_ATTRIBUTE_INPUT_TEXTURE_COORDINATE], 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid *)(sizeof(float) * 4));

    //绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}

-(void)temProgram{
    //使用program
    glUseProgram(_temprogramHandle);
    //绑定FrameBuffer
    glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer);
    //绑定RenderBuffer
    glBindRenderbuffer(GL_RENDERBUFFER, _renderbuffer);

    //设置清屏颜色
    glClearColor(1, 0, 0, 1);

    //清除颜色缓存区
    glClear(GL_COLOR_BUFFER_BIT);

    //设置视口
    glViewport(0, 0, self.frame.size.width * self.contentScaleFactor, self.frame.size.height * self.contentScaleFactor);


    //纹理
    glActiveTexture(GL_TEXTURE0);
    glBindTexture(GL_TEXTURE_2D, _grayTexture);
    glUniform1i(glViewUniforms[UNIFORM_INPUT_IMAGE_TEXTURE], 0);

    //色温
    glUniform1f(glViewUniforms[UNIFORM_TEMPERATURE], _temperature);
    //顶点数据
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_POSITION], 4, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), 0);
    //纹理数据
    glVertexAttribPointer(glViewAttributes[ATTRIBUTE_INPUT_TEXTURE_COORDINATE], 2, GL_FLOAT, GL_FALSE, sizeof(CustomVertex), (GLvoid *)(sizeof(float) * 4));

    //绘制
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}
- (void)render {
    //https://www.jianshu.com/p/d7066d6a02cc

    [self satuProgram];
    [self grayProgram];
    [self temProgram];
    //要求本地窗口系统显示OpenGL ES渲染缓存绑定到RenderBuffer上
    [_context presentRenderbuffer:GL_RENDERBUFFER];
}

@end
