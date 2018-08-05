//
//  XLSystemPhotoPicker.m
//  PatchBoard
//
//  Created by xll on 2017/7/4.
//  Copyright © 2017年 teason. All rights reserved.
//

#import "XLSystemPhotoPicker.h"

#import <AVFoundation/AVCaptureDevice.h>
#import <AVFoundation/AVMediaFormat.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/PHPhotoLibrary.h>


@implementation XLPhotoModel

@end

@interface SingleManager : NSObject

@property(nonatomic,strong)XLSystemPhotoPicker *holdPicker;

@end

@implementation SingleManager

+(SingleManager *)shareInstance
{
    static SingleManager *instance ;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[SingleManager alloc]init];
    });
    return instance;
}

@end


@interface XLSystemPhotoPicker()<UIImagePickerControllerDelegate,UINavigationControllerDelegate,UIAlertViewDelegate>

@property(nonatomic,weak)UIViewController *weakVC;
@property(nonatomic,assign)XLPickerType pickerType;
@property(nonatomic,assign)BOOL canEdit;


@property(nonatomic,copy)void(^completion)(BOOL isSuccess,XLPhotoModel *selectItem,NSString *msg);
@end

@implementation XLSystemPhotoPicker

-(instancetype)initWithPickerType:(XLPickerType)pickerType withEdit:(BOOL)canEdit completion:(void (^)(BOOL, XLPhotoModel *, NSString *))completion
{
    self = [super init];
    if (self) {
        _pickerType = pickerType;
        _canEdit = canEdit;
        _completion = completion;
        
        //保持不被释放
        [SingleManager shareInstance].holdPicker = self;
    }
    return self;
}
-(void)showPickerIn:(UIViewController *)weakVC
{
    _weakVC = weakVC;
    
    if (_pickerType  == XLPickerAlbumType) {
        [self showAlbumPicker];
    }
    else if(_pickerType  == XLPickerCameraType)
    {
        [self showCameraPicker];
    }
    else
    {
        UIAlertController *alertVC = [self GetAlertWithTitle:@"提示" message:nil style:UIAlertControllerStyleActionSheet withActions:@[@"相册",@"相机"] cancelAction:@"取消" completion:^(NSInteger index) {
            if (index == 0) {
                [self showAlbumPicker];
            }
            else if(index == 1)
            {
                [self showCameraPicker];
            }
            else
            {
                //选择图片完成回调
                if (_completion) {
                    _completion(NO,nil,@"取消");
                }
                //释放self
                [SingleManager shareInstance].holdPicker = nil;
            }
        }];
        if (_weakVC) {
            [_weakVC presentViewController:alertVC animated:YES completion:nil];
        }
    }
}
-(void)showAlbumPicker
{
    
    if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusDenied || [PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusRestricted) {
        UIAlertController *alertVC = [self GetAlertWithTitle:@"提示" message:@"请去iPhone的""设置-隐私-照片""中允许访问相册" style:UIAlertControllerStyleAlert withActions:@[@"确定"] cancelAction:nil completion:^(NSInteger index) {
            if (index == 0) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        }];
        if (_weakVC) {
            [_weakVC presentViewController:alertVC animated:YES completion:nil];
        }
        //选择图片完成回调
        if (_completion) {
            _completion(NO,nil,@"用户未开启权限");
        }
        //释放self
        [SingleManager shareInstance].holdPicker = nil;
        
        return;
    }
    else if ([PHPhotoLibrary authorizationStatus] == PHAuthorizationStatusNotDetermined)
    {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            if (status == PHAuthorizationStatusAuthorized) {
                UIImagePickerController *pickerVC = [self GetImagePickerWithPickType:UIImagePickerControllerSourceTypePhotoLibrary];
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //跳转系统相册
                    dispatch_async(dispatch_get_main_queue(), ^{
                         [_weakVC presentViewController:pickerVC animated:YES completion:nil];
                    });
                   
                });
                
            }
            else
            {
                //选择图片完成回调
                if (_completion) {
                    _completion(NO,nil,@"用户未开启权限");
                }
                //释放self
                [SingleManager shareInstance].holdPicker = nil;
                
                return;
            }
        }];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImagePickerController *pickerVC = [self GetImagePickerWithPickType:UIImagePickerControllerSourceTypePhotoLibrary];
            //跳转系统相册
            [_weakVC presentViewController:pickerVC animated:YES completion:nil];
        });
        
    }
    
    
}

-(void)showCameraPicker
{
    //先判断设备
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
        //选择图片完成回调
        if (_completion) {
            _completion(NO,nil,@"模拟器中无法打开照相机,请在真机中使用");
        }
        //释放self
        [SingleManager shareInstance].holdPicker = nil;
        return;
    }
    
    BOOL isCamera = [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceRear] || [UIImagePickerController isCameraDeviceAvailable:UIImagePickerControllerCameraDeviceFront];
    if (!isCamera) {
        //设备没有摄像头
        UIAlertController *alertVC = [self GetAlertWithTitle:@"提示" message:@"您的设备不支持拍照" style:UIAlertControllerStyleAlert withActions:@[@"确定"] cancelAction:nil completion:^(NSInteger index) {
            if (index == 0) {
    
            }
        }];
        if (_weakVC) {
            [_weakVC presentViewController:alertVC animated:YES completion:nil];
        }
        //选择图片完成回调
        if (_completion) {
            _completion(NO,nil,@"您的设备不支持拍照");
        }
        //释放self
        [SingleManager shareInstance].holdPicker = nil;
        return ;
        
    }
    
    
    //先判断授权
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        UIAlertController *alertVC = [self GetAlertWithTitle:@"提示" message:@"请去iPhone的""设置-隐私-相机""中允许访问相机" style:UIAlertControllerStyleAlert withActions:@[@"确定"] cancelAction:nil completion:^(NSInteger index) {
            if (index == 0) {
                NSURL *url = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                if ([[UIApplication sharedApplication] canOpenURL:url]) {
                    [[UIApplication sharedApplication] openURL:url];
                }
            }
        }];
        if (_weakVC) {
            [_weakVC presentViewController:alertVC animated:YES completion:nil];
        }
        //选择图片完成回调
        if (_completion) {
            _completion(NO,nil,@"用户未开启权限");
        }
        //释放self
        [SingleManager shareInstance].holdPicker = nil;
        
        return;
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined)
    {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (!granted) {
                //选择图片完成回调
                if (_completion) {
                    _completion(NO,nil,@"用户未开启权限");
                }
                //释放self
                [SingleManager shareInstance].holdPicker = nil;
                
                return;
            }
            else
            {
                UIImagePickerController *pickerVC = [self GetImagePickerWithPickType:UIImagePickerControllerSourceTypeCamera];
               
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    //跳转系统相机
                    [_weakVC presentViewController:pickerVC animated:YES completion:nil];
                });
            }
        }];
    }
    else
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            UIImagePickerController *pickerVC = [self GetImagePickerWithPickType:UIImagePickerControllerSourceTypeCamera];
            //跳转系统相机
            [_weakVC presentViewController:pickerVC animated:YES completion:nil];
        });
        
    }
    
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    //选择图片完成回调
    if (_completion) {
        _completion(NO,nil,@"用户取消选择");
    }
    
    [picker dismissViewControllerAnimated:YES completion:nil];
    //释放self
    [SingleManager shareInstance].holdPicker = nil;
}
-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    
    UIImage *image = [info objectForKey:@"UIImagePickerControllerEditedImage"];
    if (image == nil) {
        image = [info objectForKey:@"UIImagePickerControllerOriginalImage"];
    }
    
    XLPhotoModel *model = [[XLPhotoModel alloc] init];
    model.originImage = image;
    model.thumbnail = [XLSystemPhotoPicker thumbnailWithImage:image size:CGSizeMake(200, 200)];
    
    //选择图片完成回调
    if (_completion) {
        _completion(YES,model,@"success");
    }
    [picker dismissViewControllerAnimated:YES completion:nil];
    //释放self
    [SingleManager shareInstance].holdPicker = nil;
}
-(void)dealloc
{
    NSLog(@"picker dealloc");
}
-(UIImagePickerController *)GetImagePickerWithPickType:(UIImagePickerControllerSourceType)type
{
    //跳转到相册
    UIImagePickerController *pickerVC = [[UIImagePickerController alloc] init];
    pickerVC.view.backgroundColor = [UIColor whiteColor];
    //设置跳转方式
    pickerVC.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    if (type == UIImagePickerControllerSourceTypeCamera) {
        pickerVC.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    }
    
    //设置是否可对图片进行编辑
    pickerVC.allowsEditing = _canEdit;
    //代理
    pickerVC.delegate = self;
    //类型
    pickerVC.sourceType = type;
    return pickerVC;
}
#pragma mark 创建alert
-(UIAlertController *)GetAlertWithTitle:(NSString *)title message:(NSString *)message style:(UIAlertControllerStyle)style withActions:(NSArray *)actions cancelAction:(NSString*)cancel completion:(void(^)(NSInteger index))completion
{
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:style];
    
    for (NSInteger i = 0; i < actions.count; i++) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:actions[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            completion(i);
        }];
        [alertVC addAction:action];
    }
    
    if (cancel) {
        UIAlertAction *action = [UIAlertAction actionWithTitle:cancel style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            completion(actions.count);
        }];
        [alertVC addAction:action];
    }
    
    return alertVC;
}
#pragma mark  图片压缩
/**
 *  获取图片的缩略图片
 */
+ (UIImage *)thumbnailWithImage:(UIImage *)image size:(CGSize)size {
    
    UIImage *newimage;
    if (nil == image) {
        newimage = nil;
        
    }else{
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        newimage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
    }
    return newimage;
}
@end
