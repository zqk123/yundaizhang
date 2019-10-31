//
//  ViewController.m
//  双滤镜
//
//  Created by zhengqiankun on 2019/9/3.
//  Copyright © 2019年 zhengqiankun. All rights reserved.
//

#import "ViewController.h"
#import "GLContainerView.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet GLContainerView *glContainerView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.glContainerView.image = [UIImage imageNamed:@"Lena"];
}
- (IBAction)actionValueChanged:(UISlider *)sender {
    self.glContainerView.colorTempValue = sender.value;
}

- (IBAction)actionSaturationValueChanged:(UISlider *)sender {
    self.glContainerView.saturationValue = sender.value;
}
@end
