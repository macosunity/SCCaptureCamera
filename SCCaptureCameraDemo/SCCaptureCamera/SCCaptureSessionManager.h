//
//  SCCaptureSessionManager.h
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-16.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "SCDefines.h"

@protocol SCCaptureSessionManager;

typedef void (^ DidCapturePhotoBlock)(UIImage *stillImage);

@interface SCCaptureSessionManager : NSObject

@property (nonatomic) dispatch_queue_t                      sessionQueue;
@property (nonatomic, strong) AVCaptureSession              *session;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer    *previewLayer;
@property (nonatomic, strong) AVCaptureDeviceInput          *inputDevice;
@property (nonatomic, strong) AVCaptureStillImageOutput     *stillImageOutput;

// pinch
@property (nonatomic, assign) CGFloat   preScaleNum;
@property (nonatomic, assign) CGFloat   scaleNum;

@property (nonatomic, assign) id <SCCaptureSessionManager> delegate;

- (void)configureWithParentLayer:(UIView *)parent previewRect:(CGRect)preivewRect;
- (void)takePicture:(DidCapturePhotoBlock)block;
- (void)switchCamera:(BOOL)isFrontCamera;
- (void)switchFlashMode:(UIButton *)sender;
- (void)focusInPoint:(CGPoint)devicePoint;

@end

@protocol SCCaptureSessionManager <NSObject>

@optional
- (void)didCapturePhoto:(UIImage *)stillImage;

@end