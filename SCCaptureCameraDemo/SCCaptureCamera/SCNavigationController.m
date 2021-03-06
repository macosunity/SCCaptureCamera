//
//  SCNavigationController.m
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-17.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import "SCNavigationController.h"
#import <objc/runtime.h>

@interface UIViewController(PickerManager)

//for UIImagePickerController use
@property (nonatomic,strong) SCImagePickerManager *pickerManager;

@end

static char const *const PickerManagerTagKey;

@implementation UIViewController(PickerManager)
@dynamic pickerManager;

- (id)pickerManager {
    return objc_getAssociatedObject(self, PickerManagerTagKey);
}

- (void)setPickerManager:(SCImagePickerManager *)pickerManager {
    objc_setAssociatedObject(self, PickerManagerTagKey, pickerManager, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end

@interface SCNavigationController ()

@property (nonatomic, assign) BOOL isStatusBarHiddenBeforeShowCamera;

@end

@implementation SCNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.navigationBarHidden = YES;
    self.hidesBottomBarWhenPushed = YES;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark - pop
- (void)dismissModalViewControllerAnimated:(BOOL)animated
{
    BOOL shouldToDismiss = YES;

    if ([self.scNaigationDelegate respondsToSelector:@selector(willDismissNavigationController:)]) {
        shouldToDismiss = [self.scNaigationDelegate willDismissNavigationController:self];
    }

    if (shouldToDismiss) {
        [super dismissModalViewControllerAnimated:animated];
    }
}

#pragma mark - action(s)
//拍照
- (void)showCameraWithViewController:(UIViewController *)viewController
{
    SCCaptureCameraController *con = [[SCCaptureCameraController alloc] init];
    con.albumName = self.customAlbumName;
    
    [self setViewControllers:[NSArray arrayWithObjects:con, nil]];
    [viewController presentViewController:self animated:YES completion:nil];
}

//从相册选择
- (void)showAlbumWithViewController:(UIViewController *)viewController
{
    viewController.pickerManager = [[SCImagePickerManager alloc] init];

    SCImagePickerManager *pickerManager = viewController.pickerManager;
    
    SCImagePickerController *picker = [[SCImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.allowsEditing = NO;
    picker.delegate = pickerManager;
    [viewController presentViewController:picker animated:YES completion:nil];
    
    pickerManager.finishPickImageBlock = ^ {
        NSLog(@"cancel");
        if ([self.scNaigationDelegate respondsToSelector:@selector(willDismissNavigationController:)]) {
            [self.scNaigationDelegate willDismissNavigationController:self];
        }
    };
    
    __weak UIViewController *weakParentVC = viewController;
    pickerManager.finishPickImageMediaBlock = ^(UIImage *pickedImage) {
        NSLog(@"%@", pickedImage);
        
        if ([weakParentVC respondsToSelector:@selector(didTakePictureWithImage:)]) {
            [weakParentVC performSelector:@selector(didTakePictureWithImage:) withObject:pickedImage];
        }
    };
}

#define CAN_ROTATE 0

#pragma mark -------------rotate---------------
// <iOS6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
#if CAN_ROTATE
    return interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationPortrait || interfaceOrientation == UIInterfaceOrientationLandscapeLeft || interfaceOrientation == UIInterfaceOrientationLandscapeRight;

#else
    return interfaceOrientation == UIInterfaceOrientationPortrait;
#endif
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0
    // iOS6+
- (BOOL)shouldAutorotate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
#if CAN_ROTATE
    return YES;
#else
    return NO;
#endif
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}
#endif /* if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0 */

@end