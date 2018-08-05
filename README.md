# XLSystemPhotoPicker
单张图片选择器，使用系统picker，支持相机相册，两行代码获取完毕<br>

```
//    __weak typeof(self)weakSelf = self;
        XLSystemPhotoPicker *picker = [[XLSystemPhotoPicker alloc]initWithPickerType:XLPickerBothType withEdit:NO completion:^(BOOL isSuccess, XLPhotoModel *selectItem, NSString *msg) {
            //        __strong typeof(weakSelf)strongSelf = weakSelf;
            if (isSuccess) {
                NSLog(@"%@",selectItem);
            }
        }];
        [picker showPickerIn:self];
```
不要忘记info.plist添加<br>
```
<key>NSCameraUsageDescription</key>
    <string>是否允许AAA使用您的相机拍照？</string>
    <key>NSPhotoLibraryAddUsageDescription</key>
    <string>是否允许访问相册，以便将拍摄图片存入相册？</string>
    <key>NSPhotoLibraryUsageDescription</key>
    <string>是否允许访问相？</string>
```
