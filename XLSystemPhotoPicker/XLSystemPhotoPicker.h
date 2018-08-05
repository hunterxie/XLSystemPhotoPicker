//
//  XLSystemPhotoPicker.h
//  PatchBoard
//
//  Created by xll on 2017/7/4.
//  Copyright © 2017年 teason. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
typedef NS_ENUM(NSUInteger, XLPickerType){
    XLPickerAlbumType = 0,//相册
    XLPickerCameraType ,//相机
    XLPickerBothType //两者都要  弹出询问框
};

@interface XLPhotoModel : NSObject

//原图
@property(nonatomic,strong)UIImage *originImage;

//压缩图  200*200
@property(nonatomic,strong)UIImage *thumbnail;


@end



//系统的照片选择器   系统必须大于iOS8才行 低于iOS8的 暂时没考虑

@interface XLSystemPhotoPicker : NSObject


-(instancetype)initWithPickerType:(XLPickerType)pickerType withEdit:(BOOL)canEdit completion:(void(^)(BOOL isSuccess,XLPhotoModel *selectItem,NSString *msg))completion;

//显示图片选择
-(void)showPickerIn:(UIViewController *)weakVC;
@end
