# SXScanView


![img](ex.gif)  

## 1.improt & use
可以用pod导入pod 'SXScanView', '~>0.0.4'

也可以直接复制文件夹使用
```
#import <SXScanView.h>
```
```
SXScanView *_scanView;
```
```
_scanView = [[SXScanView alloc] initWithFrame:self.view.bounds];
    _scanView.isLight = YES;
    [self.view addSubview:_scanView];
    __weak ScanController *weakSelf = self;
    [_scanView setResoultBlock:^(NSString *returnStr) {
    //处理 Example:
        [weakSelf checkResoultString:returnStr];
    }];

```
```
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_scanView startScanning];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    [_scanView stopScanning];
}
```

## 2.interface
```
/*
 
 建议宽度高度550以上,view过高度过低"手电筒"按钮可能会被遮挡
 
 注意设置plist
<key>NSCameraUsageDescription</key>
<string>App需要使用您的相机来提供服务</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>App需要访问您的相册来提供服务</string>
 
 */


/*
 扫描成功的回调
 失败返回nil
 */
- (void)setResoultBlock:(void(^)(NSString *returnStr))resoultBlock;

//开始结束
- (void)startScanning;
- (void)stopScanning;


#pragma mark ------optional-------
// 是否支持相册扫描- 默认NO
@property (nonatomic, assign) BOOL isPhotoScan;
// 是否支持闪光灯- 默认NO
@property (nonatomic, assign) BOOL isLight;
// 是否连续扫描,YES则扫到结果不会停止- 默认NO(下次扫描要手动start)
@property (nonatomic, assign) BOOL isAutoScan;

// 对应的方法,打开photo,直接调用
- (void)scanPhotoAction;
// 对应的方法,开关闪光灯,直接调用
- (void)scanLightAction;
```
