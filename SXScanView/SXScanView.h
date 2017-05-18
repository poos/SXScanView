//
//  SXScanView.h
//  SingleViewDemo
//
//  Created by Shown on 2017/4/25.
//  Copyright © 2017年 xiaoR. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SXScanView : UIView
/*
 
 建议宽度高度550以上,view过高度过低"手电筒"按钮可能会被遮挡
 
 注意设置plist
<key>NSCameraUsageDescription</key>
<string>App需要使用您的相机来提供服务</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>App需要访问您的相册来提供服务</string>
 
 */

#pragma mark ------必须设置的-------
/**
 初始化方法,设置frame
 */
- (instancetype)initWithFrame:(CGRect)frame;
/*
 扫描成功的回调
 失败返回nil
 */
- (void)setResoultBlock:(void(^)(NSString *returnStr))resoultBlock;

//开始结束,如果设置无效考虑在主线程调用
- (void)startScanning;
- (void)stopScanning;


#pragma mark ------可选的-------

//不使用单例- 默认使用单例
+ (void)configNotUseSingleton:(BOOL)notSingleton;
// 是否支持相册扫描- 默认NO
@property (nonatomic, assign) BOOL isPhotoScan;
// 是否支持闪光灯- 默认NO
@property (nonatomic, assign) BOOL isLight;
// 是否连续扫描,YES则扫到结果不会停止- 默认NO(下次扫描要手动start)
@property (nonatomic, assign) BOOL isAutoScan;

// 相册按钮 对应的方法,打开photo,直接调用
- (void)scanPhotoAction;
// 闪光灯按钮 对应的方法,开关闪光灯,直接调用
- (void)scanLightAction;
// 关闭闪光灯
- (void)setOffLight;

@end
