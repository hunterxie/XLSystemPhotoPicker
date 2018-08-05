//
//  ViewController.m
//  XLSystemPhotoPicker
//
//  Created by xll on 2018/8/5.
//  Copyright © 2018年 xll. All rights reserved.
//

#import "ViewController.h"
#import "XLSystemPhotoPicker.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        //    __weak typeof(self)weakSelf = self;
        XLSystemPhotoPicker *picker = [[XLSystemPhotoPicker alloc]initWithPickerType:XLPickerBothType withEdit:NO completion:^(BOOL isSuccess, XLPhotoModel *selectItem, NSString *msg) {
            //        __strong typeof(weakSelf)strongSelf = weakSelf;
            if (isSuccess) {
                NSLog(@"%@",selectItem);
            }
        }];
        [picker showPickerIn:self];
    });

    // Do any additional setup after loading the view, typically from a nib.
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
