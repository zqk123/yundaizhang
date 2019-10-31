//
//  SaturationFilter.m
//  双滤镜
//
//  Created by zhengqiankun on 2019/9/4.
//  Copyright © 2019年 zhengqiankun. All rights reserved.
//

#import "SaturationFilter.h"

@implementation SaturationFilter
+(GLuint)compileShader:(NSString *)shaderName withType:(GLenum)shaderType {

    //路径
    NSString *shaderPath = [[NSBundle mainBundle] pathForResource:shaderName ofType:nil];
    NSError *error;
    NSString *shaderString = [NSString stringWithContentsOfFile:shaderPath encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        exit(1);
    }
    //创建临时shader
    GLuint shaderHandle = glCreateShader(shaderType);
    //获取shader路径-C语言字符串
    const char* shaderStringUFT8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];

    glShaderSource(shaderHandle, 1, &shaderStringUFT8, &shaderStringLength);

    //编译shader
    glCompileShader(shaderHandle);

    //判断是否编译成功
    GLint compileSuccess;
    //获取编译信息
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);

    //打印编译时出错信息
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"glGetShaderiv ShaderIngoLog: %@", messageString);
        exit(1);
    }
    return shaderHandle;

}
//饱和度
+(GLuint)compileSaturationShaders {
    GLuint tempProgramHandle;
    //获取路径
    //Vertex Shader是一样的
    GLuint vertexShader = [self compileShader:@"CCVertexShader.vsh" withType:GL_VERTEX_SHADER];

    //片元着色器是不一样的
    GLuint fragmentShader = [self compileShader:@"CCSaturation.fsh" withType:GL_FRAGMENT_SHADER];

    //创建program
    tempProgramHandle = glCreateProgram();
    //将vertes Shader 和 fragment Shader 附着到program上
    glAttachShader(tempProgramHandle, vertexShader);
    glAttachShader(tempProgramHandle, fragmentShader);

    //链接Program
    glLinkProgram(tempProgramHandle);

    //获取link状态
    GLint linkSuccess;
    glGetProgramiv(tempProgramHandle, GL_LINK_STATUS, &linkSuccess);

    //link失败处理
    if (linkSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(tempProgramHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"glGetProgramiv ShaderIngoLog: %@", messageString);
        exit(1);
    }

    return tempProgramHandle;
}
@end
