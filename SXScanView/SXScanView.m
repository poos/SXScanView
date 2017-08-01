//
//  SXScanView.m
//  SingleViewDemo
//
//  Created by Shown on 2017/4/25.
//  Copyright © 2017年 xiaoR. All rights reserved.
//

#import "SXScanView.h"
#import <AVFoundation/AVFoundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import "TZImagePickerController.h"

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
#define Scaled(a) ((int) ((a) * ScreenWidth / 375))
#define RGBA(r, g, b, a) [UIColor colorWithRed:r / 255.0 green:g / 255.0 blue:b / 255.0 alpha:a]

static BOOL sxScanViewNotUseSingleton = NO;
static SXScanView *sxScanView = nil;

@interface SXScanView () <AVCaptureMetadataOutputObjectsDelegate, UIAlertViewDelegate, AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureMetadataOutputObjectsDelegate, AVCaptureMetadataOutputObjectsDelegate> {
    UIImage *_selectImage;
    NSString *_signID;
    BOOL _isCodeImage;
    UIImageView *_scanImageView;
    CGRect _imageRect;
    UIButton *_lightBtn;
    UIButton *_photoBtn;
    TZImagePickerController *_imagePickerVc;
}

@property (strong, nonatomic) AVCaptureDevice *device;
@property (strong, nonatomic) AVCaptureDeviceInput *input;
@property (strong, nonatomic) AVCaptureMetadataOutput *output;
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoDataOutput; //图片输出
@property (strong, nonatomic) AVCaptureSession *session;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *preview;
@property (copy, nonatomic) void(^rerurnStringBlcok)(NSString *);

@end

@implementation SXScanView


+ (void)configNotUseSingleton:(BOOL)notSingleton {
    sxScanViewNotUseSingleton = notSingleton;
}

- (void)setIsPhotoScan:(BOOL)isPhotoScan {
    _photoBtn.hidden = !isPhotoScan;
}

- (void)setIsLight:(BOOL)isLight {
    _lightBtn.hidden = !isLight;
}

- (void)scanPhotoAction {
    [self selectedImage];
}

- (void)scanLightAction {
    [self clickLightButton:_lightBtn];
}

- (void)setOffLight {
    _lightBtn.selected = NO;
    [self turnTorchOn:NO];
}

- (void)clickLightButton:(UIButton *)button {
    button.selected = !button.selected;
    if (button.selected) {
        [self turnTorchOn:YES];
    } else {
        [self turnTorchOn:NO];
    }
}
#pragma mark-> 开关闪光灯
- (void)turnTorchOn:(BOOL)on {
    
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]) {
            [device lockForConfiguration:nil];
            if (on) {
                [device setTorchMode:AVCaptureTorchModeOn];
                [device setFlashMode:AVCaptureFlashModeOn];
            } else {
                [device setTorchMode:AVCaptureTorchModeOff];
                [device setFlashMode:AVCaptureFlashModeOff];
            }
            [device unlockForConfiguration];
        }
    }
}

- (void)startScanning {
    [_session startRunning];
}

- (void)stopScanning {
    [_session stopRunning];
}

- (void)setResoultBlock:(void (^)(NSString *))resoultBlock {
    _rerurnStringBlcok = resoultBlock;
}

- (instancetype)init {
    return [self initWithFrame:CGRectZero];
}

- (instancetype)initWithFrame:(CGRect)frame {
    //用单例
    if (!sxScanViewNotUseSingleton && sxScanView) {
        sxScanView.frame = frame;
        return sxScanView;
    }
    //不用单例
    sxScanView = [super initWithFrame:frame];
    if (sxScanView) {
        self.backgroundColor = [UIColor darkGrayColor];
        [self defaultConfig];
        [self setScanView];
        
        [self addLightButton];
        [self addPhotoButton];
        self.clipsToBounds = YES;
    }
    return sxScanView;
}

- (void)selectedImage {
    ALAuthorizationStatus author =[ALAssetsLibrary authorizationStatus];
    if (author == ALAuthorizationStatusRestricted || author == ALAuthorizationStatusDenied) {
        //无权限
        if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
        } else {
            NSURL *privacyUrl = [NSURL URLWithString:@"prefs:root=Privacy&path=CAMERA"];
            if ([[UIApplication sharedApplication] canOpenURL:privacyUrl]) {
                [[UIApplication sharedApplication] openURL:privacyUrl];
            } else {
                NSString *message = @"不能跳转到设置页面, 请到\"设置-隐私-照片\"选项允许app访问手机相册";
                UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"提醒" message:message delegate:nil cancelButtonTitle:[NSBundle tz_localizedStringForKey:@"确定"] otherButtonTitles: nil];
                [alert show];
            }
        }
        return;
    }
    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:nil];
    imagePickerVc.isSelectOriginalPhoto = YES;
    imagePickerVc.allowPickingVideo = NO;
    imagePickerVc.allowTakePicture = NO;    // 在内部显示拍照按钮
    imagePickerVc.allowPickingImage = YES;    // 图片
    imagePickerVc.sortAscendingByModificationDate = NO;  // 按时间升序
    imagePickerVc.allowPickingOriginalPhoto = NO;  // 原图
    imagePickerVc.allowPreview = NO;//预览
    
    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
        //
        CIDetector *detector = [CIDetector detectorOfType:CIDetectorTypeQRCode context:nil options:@{CIDetectorAccuracy : CIDetectorAccuracyHigh}];
        //监测到的结果数组
        NSArray *features = [detector featuresInImage:[CIImage imageWithCGImage:photos[0].CGImage]];
        if (features.count >=1) {
            /**结果对象 */
            CIQRCodeFeature *feature = [features objectAtIndex:0];
            NSString *scannedResult = feature.messageString;
            if (_rerurnStringBlcok) {
                AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
                _rerurnStringBlcok(scannedResult);
            }
        }else{
            if (_rerurnStringBlcok) {
                _rerurnStringBlcok(nil);
            }
            [_session startRunning];
        }
    }];
    [imagePickerVc setImagePickerControllerDidCancelHandle:^{
        [_session startRunning];
    }];
    _imagePickerVc = imagePickerVc;
    [[self viewController] presentViewController:_imagePickerVc animated:YES completion:^{
        [_session stopRunning];
    }];
    _lightBtn.selected = NO;
    [self turnTorchOn:NO];
}

- (UILabel *)createLabelWithTitle:(NSString *)title frame:(CGRect)frame textColor:(UIColor *)color fontSize:(CGFloat)size {
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.textAlignment = NSTextAlignmentCenter;
    label.text = title;
    label.textColor = color;
    label.font = [UIFont systemFontOfSize:size];
    return label;
}

- (UIImage *)bundleImageWithName:(NSString *)imageName {
    NSBundle *myBundle = [NSBundle bundleForClass:[SXScanView class]];
    NSURL *bundleUrl = [myBundle URLForResource:@"Resources" withExtension:@"bundle"];
    NSBundle *imageBundle = [NSBundle bundleWithURL:bundleUrl];
    NSString *path = [[imageBundle resourcePath]stringByAppendingPathComponent:imageName];
    return [UIImage imageWithContentsOfFile:path];
}

- (void)setScanView {
    UIView * view  = [[UIView alloc] initWithFrame:CGRectMake(0, 0, Scaled(1240), Scaled(1240))];
    view.layer.borderWidth = Scaled(500);
    view.layer.borderColor = RGBA(0, 0, 0, .3).CGColor;
    view.center = CGPointMake(ScreenWidth/2, ScreenHeight/2 -40);
    [self addSubview:view];
    UIImageView * image = [[UIImageView alloc] initWithFrame:CGRectMake(ScreenWidth/2-Scaled(120), Scaled(184), Scaled(240), Scaled(240))];
    image.image = [self bundleImageWithName:@"sxTakePhoto"];
    image.center = CGPointMake(ScreenWidth/2, ScreenHeight/2 -40);
    [self addSubview:image];
    UILabel *tipLabel = [self createLabelWithTitle:@"将取景器对准要扫描的条形码或者二维码" frame:CGRectMake(0, image.frame.origin.y - Scaled(40), ScreenWidth, 20) textColor:RGBA(255, 255, 255, 1) fontSize:Scaled(14)];
    tipLabel.textAlignment = NSTextAlignmentCenter;
    [self addSubview:tipLabel];
    UIView * viewLine = [[UIView alloc] initWithFrame:CGRectMake(ScreenWidth/2-120, ScreenHeight/2-40, 240, 1)];
    viewLine.backgroundColor = RGBA(0, 0, 0, .05);
    [self addSubview:viewLine];
    
    [_output setRectOfInterest:CGRectMake((image.frame.origin.y-Scaled(30)) / ScreenHeight,(image.frame.origin.x-Scaled(30)) / ScreenWidth,(image.frame.size.height+Scaled(60)) / ScreenHeight,(image.frame.size.width+Scaled(60)) / ScreenWidth)];
    
    _scanImageView = image;
}

//向上找到第一个controller
- (UIViewController *)viewController {
    UIResponder *responder = self;
    while ((responder = [responder nextResponder]))
        if ([responder isKindOfClass:[UIViewController class]])
            return (UIViewController *) responder;
    
    return nil;
}

- (void)addPhotoButton {
    //相册
    UIButton * photoButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth - Scaled(60), Scaled(24), Scaled(60),Scaled(70))];
    [photoButton setTitle:@"相册" forState:UIControlStateNormal];
    [photoButton addTarget:self action:@selector(selectedImage) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:photoButton];
    _photoBtn = photoButton;
    _photoBtn.hidden = YES;
}

- (void)addLightButton {
    //闪光灯
    UIButton * lightButton = [[UIButton alloc] initWithFrame:CGRectMake(ScreenWidth/2 - Scaled(30), _scanImageView.frame.origin.y + _scanImageView.frame.size.height + Scaled(40), Scaled(60),Scaled(70))];
    [lightButton setBackgroundImage:[self bundleImageWithName:@"sxLamplightOpen"] forState:UIControlStateNormal];
    [lightButton setBackgroundImage:[self bundleImageWithName:@"sxLamplightClose"] forState:UIControlStateSelected];
    [lightButton addTarget:self action:@selector(clickLightButton:) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:lightButton];
    _lightBtn = lightButton;
    _lightBtn.hidden = YES;
}

- (void)defaultConfig {
#if TARGET_IPHONE_SIMULATOR//模拟器
    
#elif TARGET_OS_IPHONE
    
    NSString *mediaType = AVMediaTypeVideo;//读取媒体类型
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:mediaType]; //读取设备授权状态
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        UIAlertController *alertVc = [UIAlertController alertControllerWithTitle:@"提醒" message:@"设备不支持访问相机, 请到\"设置-隐私-照片\"选项允许app访问手机相机" preferredStyle:UIAlertControllerStyleAlert];
        [alertVc addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            if ([UIDevice currentDevice].systemVersion.floatValue >= 8.0f) {
                [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
            } else {
                NSURL *privacyUrl = [NSURL URLWithString:@"prefs:root=Privacy&path=PHOTOS"];
                if ([[UIApplication sharedApplication] canOpenURL:privacyUrl]) {
                    [[UIApplication sharedApplication] openURL:privacyUrl];
                }
            }
        }]];
        [[[UIApplication sharedApplication].delegate window].rootViewController presentViewController:alertVc animated:YES completion:nil];
        
    } else {
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        // Input
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
        // Output
        _output = [[AVCaptureMetadataOutput alloc] init];
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        // Session
        _session = [[AVCaptureSession alloc] init];
        [_session setSessionPreset:AVCaptureSessionPresetHigh];
        if ([_session canAddInput:self.input]) {
            [_session addInput:self.input];
        }
        if ([_session canAddOutput:self.videoDataOutput]) {
            [_session addOutput:self.videoDataOutput];
        }
        if ([_session canAddOutput:self.output]) {
            [_session addOutput:self.output];
        }
        AVCaptureConnection *outputConnection = [_output connectionWithMediaType:AVMediaTypeVideo];
        outputConnection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
        _output.metadataObjectTypes=@[AVMetadataObjectTypeUPCECode,
                                      AVMetadataObjectTypeCode39Code,
                                      AVMetadataObjectTypeCode39Mod43Code,
                                      AVMetadataObjectTypeEAN13Code,
                                      AVMetadataObjectTypeEAN8Code,
                                      AVMetadataObjectTypeCode93Code,
                                      AVMetadataObjectTypeCode128Code,
                                      AVMetadataObjectTypePDF417Code,
                                      AVMetadataObjectTypeQRCode,
                                      AVMetadataObjectTypeAztecCode,
                                      AVMetadataObjectTypeInterleaved2of5Code,
                                      AVMetadataObjectTypeITF14Code,
                                      AVMetadataObjectTypeDataMatrixCode];
        //只有二维码扫描
        //        _output.metadataObjectTypes = @[ AVMetadataObjectTypeQRCode ];
        // Preview
        _preview = [AVCaptureVideoPreviewLayer layerWithSession:_session];
        _preview.videoGravity = AVLayerVideoGravityResize;
        _preview.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        [self.layer insertSublayer:_preview atIndex:0];
        _preview.connection.videoOrientation = [self videoOrientationFromCurrentDeviceOrientation];
        [_session startRunning];
    }
    
#endif
}

- (AVCaptureVideoOrientation)videoOrientationFromCurrentDeviceOrientation {
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    
    if (orientation == UIInterfaceOrientationPortrait) {
        return AVCaptureVideoOrientationPortrait;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return AVCaptureVideoOrientationLandscapeLeft;
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return AVCaptureVideoOrientationLandscapeRight;
    } else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
        return AVCaptureVideoOrientationPortraitUpsideDown;
    }
    
    return AVCaptureVideoOrientationPortrait;
}


#pragma mark AVCaptureMetadataOutputObjectsDelegate -扫描结果
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    if (metadataObjects.count > 0) {
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects objectAtIndex:0];
        NSString *scannedResult = metadataObject.stringValue;
        if (_rerurnStringBlcok) {
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            _rerurnStringBlcok(scannedResult);
        }
        if (!_isAutoScan) {
            [_session stopRunning];
        }
    }else{
        if (_rerurnStringBlcok) {
            _rerurnStringBlcok(nil);
        }
    }
}

@end
