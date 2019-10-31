//
//  SaturationFilter.h
//  双滤镜
//
//  Created by zhengqiankun on 2019/9/4.
//  Copyright © 2019年 zhengqiankun. All rights reserved.
//

#import <Foundation/Foundation.h>
@import OpenGLES;
NS_ASSUME_NONNULL_BEGIN

@interface SaturationFilter : NSObject
+(GLuint)compileSaturationShaders;
@end

NS_ASSUME_NONNULL_END
