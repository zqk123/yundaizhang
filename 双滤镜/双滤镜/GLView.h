//
//  GLView.h
//  双滤镜
//
//  Created by zhengqiankun on 2019/9/3.
//  Copyright © 2019年 zhengqiankun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLView : UIView
{
    CAEAGLLayer *_eaglLayer;//图层
    EAGLContext *_context;//上下文
    GLuint       _framebuffer;
    GLuint       _renderbuffer;

    GLuint       _texture;//纹理

    GLuint       _satuFramebuffer;
    GLuint       _satuTexture;
    GLuint       _satuRenderBuffer;

    GLuint       _grayFramebuffer;
    GLuint       _grayTexture;
    GLuint       _grayRenderBuffer;


    GLuint       _temprogramHandle;
    GLuint       _satuProgramHandle;
    GLuint       _grayProgramHandle;

}

@property (nonatomic, assign) CGFloat temperature;//色温
@property (nonatomic, assign) CGFloat saturation;//饱和度

//将图片加入到GLView上
- (void)layoutGLViewWithImage:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
