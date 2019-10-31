//
//  GLContainerView.h
//  双滤镜
//
//  Created by zhengqiankun on 2019/9/3.
//  Copyright © 2019年 zhengqiankun. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLContainerView : UIView
//图片
@property (nonatomic, strong) UIImage *image;
//色温值
@property (nonatomic, assign) CGFloat  colorTempValue;
//饱和度
@property (nonatomic, assign) CGFloat  saturationValue;
@end

NS_ASSUME_NONNULL_END
