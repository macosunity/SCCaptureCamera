//
//  SCNavigationController.h
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-17.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SCDefines.h"
#import "SCCaptureCameraController.h"
#import "SCImagePickerManager.h"
#import "SCImagePickerController.h"

@protocol SCNavigationControllerDelegate;

@interface SCNavigationController : UINavigationController

@property (nonatomic, copy) NSString                                 *customAlbumName;
@property (nonatomic, assign) id <SCNavigationControllerDelegate>    scNaigationDelegate;

//拍照
- (void)showCameraWithParentController:(UIViewController *)parentController;
//从相册选择
- (void)showAlbumWithParentController:(UIViewController *)parentController;
@end

@protocol SCNavigationControllerDelegate <NSObject>

@optional
- (BOOL)willDismissNavigationController:(SCNavigationController *)navigatonController;
- (void)didTakePictureWithImage:(UIImage *)image;

@end