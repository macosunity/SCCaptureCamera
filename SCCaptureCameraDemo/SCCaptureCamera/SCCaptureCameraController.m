//
//  SCCaptureCameraController.m
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-16.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import "SCCaptureCameraController.h"
#import "SCCommon.h"
#import "SCDefines.h"
#import "SCNavigationController.h"
#import <AssetsLibrary/AssetsLibrary.h>

#define SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE      0   // 对焦框是否一直闪到对焦完成

#define SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA   1   // 没有拍照功能的设备，是否给一张默认图片体验一下

// color
#define bottomContainerView_UP_COLOR                [UIColor colorWithRed:51 / 255.0f green:51 / 255.0f blue:51 / 255.0f alpha:1.f]     // bottomContainerView的上半部分
#define bottomContainerView_DOWN_COLOR              [UIColor colorWithRed:68 / 255.0f green:68 / 255.0f blue:68 / 255.0f alpha:1.f]     // bottomContainerView的下半部分
#define DARK_GREEN_COLOR                            [UIColor colorWithRed:10 / 255.0f green:107 / 255.0f blue:42 / 255.0f alpha:1.f]    // 深绿色
#define LIGHT_GREEN_COLOR                           [UIColor colorWithRed:143 / 255.0f green:191 / 255.0f blue:62 / 255.0f alpha:1.f]   // 浅绿色

// 对焦
#define ADJUSTINT_FOCUS                             @"adjustingFocus"
#define LOW_ALPHA                                   0.7f
#define HIGH_ALPHA                                  1.0f

@interface SCCaptureCameraController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>{
    int             alphaTimes;
    CGPoint         currTouchPoint;
    UIButton        *_cancelBtn;
}

@property (nonatomic, strong) SCCaptureSessionManager *captureManager;

@property (nonatomic, strong) UIView    *topContainerView;          // 顶部view
@property (nonatomic, strong) UILabel   *topLbl;                    // 顶部的标题

@property (nonatomic, strong) UIView        *bottomContainerView;   // 除了顶部标题、拍照区域剩下的所有区域
@property (nonatomic, strong) UIView        *cameraMenuView;        // 网格、闪光灯、前后摄像头等按钮
@property (nonatomic, strong) NSMutableSet  *cameraBtnSet;

@property (nonatomic, strong) UIView    *doneCameraUpView;
@property (nonatomic, strong) UIView    *doneCameraDownView;

// 对焦
@property (nonatomic, strong) UIImageView *focusImageView;

@end

@implementation SCCaptureCameraController

#pragma mark -------------life cycle---------------
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];

    if (self) {
        // Custom initialization
        alphaTimes = -1;
        currTouchPoint = CGPointZero;

        _cameraBtnSet = [[NSMutableSet alloc] init];
    }

    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor blackColor];

    // navigation bar
    if (self.navigationController && !self.navigationController.navigationBarHidden) {
        self.navigationController.navigationBarHidden = YES;
    }

    // status bar
    // iOS7，需要plist里设置 View controller-based status bar appearance 为NO
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];

    // notification
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationOrientationChange object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationDidChange:) name:kNotificationOrientationChange object:nil];
    
    // session manager
    SCCaptureSessionManager *manager = [[SCCaptureSessionManager alloc] init];

    // AvcaptureManager
    if (CGRectEqualToRect(_previewRect, CGRectZero)) {
        self.previewRect = CGRectMake(0, 0, SC_APP_SIZE.width, SC_APP_SIZE.height * CAMERA_PREVIEW_LAYER_HEIGHT_SCALE);
    }

    [manager configureWithParentLayer:self.view previewRect:_previewRect];

    self.captureManager = manager;

    [self addTopView];
    [self addbottomContainerView];
    [self addCameraMenuView];
    [self addCameraCover];

    [_captureManager.session startRunning];

#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            NSLog(@"设备不支持拍照功能");
        }
#endif
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationSlide];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:UIStatusBarAnimationSlide];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kNotificationOrientationChange object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:ALAssetsLibraryChangedNotification object:nil];
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        if (device && [device isFocusPointOfInterestSupported]) {
            [device removeObserver:self forKeyPath:ADJUSTINT_FOCUS context:nil];
        }
#endif

    self.captureManager = nil;
}

#pragma mark -------------UI---------------
// 顶部菜单
- (void)addTopView
{
    if (!_topContainerView) {
        CGRect topFrame = CGRectMake(0, 0, SC_APP_SIZE.width, CAMERA_TOPVIEW_HEIGHT);

        UIView *tView = [[UIView alloc] initWithFrame:topFrame];
        tView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:tView];
        self.topContainerView = tView;

        UIView *emptyView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, topFrame.size.width, topFrame.size.height)];
        emptyView.backgroundColor = [UIColor blackColor];
        emptyView.alpha = 1.0f;
        [_topContainerView addSubview:emptyView];
    }

    [self addMenuViewButtons];
}

// bottomContainerView，总体
- (void)addbottomContainerView
{
    CGFloat bottomY = _captureManager.previewLayer.frame.origin.y + _captureManager.previewLayer.frame.size.height;
    CGRect  bottomFrame = CGRectMake(0, bottomY, SC_APP_SIZE.width, SC_APP_SIZE.height - bottomY);

    UIView *view = [[UIView alloc] initWithFrame:bottomFrame];

    view.backgroundColor = [UIColor clearColor];
    [self.view addSubview:view];
    self.bottomContainerView = view;
}

// 拍照菜单栏
- (void)addCameraMenuView
{
    // 拍照按钮
    CGFloat cameraBtnLength = 80;

    [self buildButton:CGRectMake((SC_APP_SIZE.width - cameraBtnLength) / 2, (_bottomContainerView.frame.size.height-cameraBtnLength)/2.0, cameraBtnLength, cameraBtnLength)
         normalImgStr:[UIImage imageNamed:@"shot.png"]
      highlightImgStr:[UIImage imageNamed:@"shot_h.png"]
       selectedImgStr:nil
               action:@selector(takePictureBtnPressed:)
           parentView:_bottomContainerView];
    
    CGFloat cancelBtnWidth = 60;
    _cancelBtn = [self buildButton:CGRectMake(0, (_bottomContainerView.frame.size.height-cancelBtnWidth)/2.0, cancelBtnWidth, cancelBtnWidth)
                      normalImgStr:nil
                   highlightImgStr:nil
                    selectedImgStr:nil
                            action:@selector(dismissBtnPressed:)
                        parentView:_bottomContainerView];
    [_cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [_cancelBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

// 菜单栏上的按钮
- (void)addMenuViewButtons
{
    NSMutableArray  *normalArr = [[NSMutableArray alloc] initWithObjects:@"flashing_off", @"", @"switch_camera", nil];
    NSMutableArray  *highlightArr = [[NSMutableArray alloc] initWithObjects:@"", @"", @"", nil];
    NSMutableArray  *selectedArr = [[NSMutableArray alloc] initWithObjects:@"", @"", @"", nil];
    NSMutableArray *actionArr = [[NSMutableArray alloc] initWithObjects:@"flashBtnPressed:", @"", @"switchCameraBtnPressed:", nil];

    CGFloat eachW = CAMERA_MENU_VIEW_HEIGH;
    CGFloat theH = CAMERA_MENU_VIEW_HEIGH;
    UIView  *parentView = _topContainerView;

    for (int i = 0; i < actionArr.count; i++) {
        UIButton *btn = [self buildButton:CGRectMake(eachW * i, CAMERA_TOPVIEW_HEIGHT - theH, eachW, theH)
                             normalImgStr:[UIImage imageNamed:[normalArr objectAtIndex:i]]
                          highlightImgStr:[UIImage imageNamed:[highlightArr objectAtIndex:i]]
                           selectedImgStr:[UIImage imageNamed:[selectedArr objectAtIndex:i]]
                                   action:NSSelectorFromString([actionArr objectAtIndex:i])
                               parentView:parentView];
        btn.backgroundColor = [UIColor clearColor];
        btn.tag = i + 1;
        [_cameraBtnSet addObject:btn];
    }

    CGRect switchCameraframe = [_topContainerView viewWithTag:3].frame;
    switchCameraframe.origin.x = SC_APP_SIZE.width - switchCameraframe.size.width - 5;
    [_topContainerView viewWithTag:3].frame = switchCameraframe;

    CGRect flashFrame = [_topContainerView viewWithTag:2].frame;
    flashFrame.origin.x = (parentView.frame.size.width - flashFrame.size.width) / 2;
    [_topContainerView viewWithTag:2].frame = flashFrame;
}

- (UIButton *)buildButton:(CGRect)frame normalImgStr:(UIImage *)normalImgStr highlightImgStr :(UIImage *)highlightImgStr selectedImgStr:(UIImage *)selectedImgStr action:(SEL)action parentView:(UIView *)parentView
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];

    btn.frame = frame;

    if (normalImgStr) {
        [btn setImage:normalImgStr forState:UIControlStateNormal];
    }

    if (highlightImgStr) {
        [btn setImage:highlightImgStr forState:UIControlStateHighlighted];
    }

    if (selectedImgStr) {
        [btn setImage:selectedImgStr forState:UIControlStateSelected];
    }

    if (NSStringFromSelector(action).length > 0) {
        [btn addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    }
    [parentView addSubview:btn];
    btn.backgroundColor = [UIColor clearColor];

    return btn;
}

// 对焦的框
- (void)addFocusView
{
    UIImageView *imgView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"touch_focus_x.png"]];

    imgView.alpha = 0;
    [self.view addSubview:imgView];
    self.focusImageView = imgView;

#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];

        if (device && [device isFocusPointOfInterestSupported]) {
            [device addObserver:self forKeyPath:ADJUSTINT_FOCUS options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        }
#endif
}

// 拍完照后的遮罩
- (void)addCameraCover
{
    UIView *upView = [[UIView alloc] initWithFrame:CGRectMake(0, CAMERA_TOPVIEW_HEIGHT, SC_APP_SIZE.width, 0)];

    upView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:upView];
    self.doneCameraUpView = upView;

    UIView *downView = [[UIView alloc] initWithFrame:CGRectMake(0, _bottomContainerView.frame.origin.y, SC_APP_SIZE.width, 0)];
    downView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:downView];
    self.doneCameraDownView = downView;
}

- (void)showCameraCover:(BOOL)toShow
{
    [UIView animateWithDuration:0.38f animations:^{
        CGRect upFrame = _doneCameraUpView.frame;
        upFrame.size.height = (toShow ? ((CAMERA_CONTENT_HEIGHT-CAMERA_TOPVIEW_HEIGHT)/2.0): 0);
        _doneCameraUpView.frame = upFrame;
        
        CGRect downFrame = _doneCameraDownView.frame;
        downFrame.origin.y = (toShow ? (((CAMERA_CONTENT_HEIGHT-CAMERA_TOPVIEW_HEIGHT)/2.0) + CAMERA_TOPVIEW_HEIGHT) : _bottomContainerView.frame.origin.y);
        downFrame.size.height = (toShow ? ((CAMERA_CONTENT_HEIGHT-CAMERA_TOPVIEW_HEIGHT)/2.0) : 0);
        _doneCameraDownView.frame = downFrame;
    }];
}

#pragma mark -------------touch to focus---------------
#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
    // 监听对焦是否完成了
    - (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
    {
        if ([keyPath isEqualToString:ADJUSTINT_FOCUS]) {
            BOOL isAdjustingFocus = [[change objectForKey:NSKeyValueChangeNewKey] isEqualToNumber:[NSNumber numberWithInt:1]];

            if (!isAdjustingFocus) {
                alphaTimes = -1;
            }
        }
    }

    - (void)showFocusInPoint:(CGPoint)touchPoint
    {
        [UIView animateWithDuration:0.1f delay:0 options:UIViewAnimationOptionAllowUserInteraction animations:^{
            int alphaNum = (alphaTimes % 2 == 0 ? HIGH_ALPHA : LOW_ALPHA);
            self.focusImageView.alpha = alphaNum;
            alphaTimes++;
        } completion:^(BOOL finished) {
            if (alphaTimes != -1) {
                [self showFocusInPoint:currTouchPoint];
            } else {
                self.focusImageView.alpha = 0.0f;
            }
        }];
    }
#endif /* if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE */

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    alphaTimes = -1;

    UITouch *touch = [touches anyObject];
    currTouchPoint = [touch locationInView:self.view];

    if (CGRectContainsPoint(_captureManager.previewLayer.bounds, currTouchPoint) == NO) {
        return;
    }

    [_captureManager focusInPoint:currTouchPoint];

    // 对焦框
    [_focusImageView setCenter:currTouchPoint];
    _focusImageView.transform = CGAffineTransformMakeScale(2.0, 2.0);

#if SWITCH_SHOW_FOCUSVIEW_UNTIL_FOCUS_DONE
        [UIView animateWithDuration:0.1f animations:^{
            _focusImageView.alpha = HIGH_ALPHA;
            _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:^(BOOL finished) {
            [self showFocusInPoint:currTouchPoint];
        }];
#else
        [UIView animateWithDuration:0.3f delay:0.f options:UIViewAnimationOptionAllowUserInteraction animations:^{
            _focusImageView.alpha = 1.f;
            _focusImageView.transform = CGAffineTransformMakeScale(1.0, 1.0);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.5f delay:0.5f options:UIViewAnimationOptionAllowUserInteraction animations:^{
                _focusImageView.alpha = 0.f;
            } completion:nil];
        }];
#endif
}

#pragma mark -------------button actions---------------
// 拍照页面，拍照按钮
- (void)takePictureBtnPressed:(UIButton *)sender
{
#if SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA
        if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            NSLog(@"设备不支持拍照功能");
            return;
        }
#endif

    sender.userInteractionEnabled = NO;
    [self showCameraCover:YES];

    __block UIActivityIndicatorView *actiView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    actiView.center = CGPointMake(self.view.center.x, self.view.center.y - CAMERA_TOPVIEW_HEIGHT);
    [actiView startAnimating];
    [self.view addSubview:actiView];

    WEAKSELF_SC
    [_captureManager takePicture:^(UIImage *stillImage) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            //照片存至本机
            UIImageWriteToSavedPhotosAlbum(stillImage, nil, nil, nil);
        });

        [actiView stopAnimating];
        [actiView removeFromSuperview];
        actiView = nil;

        double delayInSeconds = 2.f;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void) {
            sender.userInteractionEnabled = YES;
            [weakSelf_SC showCameraCover:NO];
        });
        
        if (self.navigationController) {
            if (self.navigationController.viewControllers.count == 1) {
                SCNavigationController *nav = (SCNavigationController *)weakSelf_SC.navigationController;
                if ([nav.scNaigationDelegate respondsToSelector:@selector(didTakePictureWithImage:)]) {
                    [nav.scNaigationDelegate didTakePictureWithImage:stillImage];
                }
                [self.navigationController dismissViewControllerAnimated:NO completion:^ {
                }];
            } else {
                [self.navigationController popViewControllerAnimated:YES];
                SCNavigationController *nav = (SCNavigationController *)weakSelf_SC.navigationController;
                if ([nav.scNaigationDelegate respondsToSelector:@selector(didTakePictureWithImage:)]) {
                    [nav.scNaigationDelegate didTakePictureWithImage:stillImage];
                }
            }
        } else {
            SCNavigationController *nav = (SCNavigationController *)weakSelf_SC.navigationController;
            if ([nav.scNaigationDelegate respondsToSelector:@selector(didTakePictureWithImage:)]) {
                [nav.scNaigationDelegate didTakePictureWithImage:stillImage];
            }
            [self dismissViewControllerAnimated:NO completion:^ {
            }];
        }
    }];
}

- (void)tmpBtnPressed:(id)sender
{
    [self.navigationController popViewControllerAnimated:YES];
}

// 拍照页面，"X"按钮
- (void)dismissBtnPressed:(id)sender
{
    if (self.navigationController) {
        if (self.navigationController.viewControllers.count == 1) {
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self.navigationController popViewControllerAnimated:YES];
        }
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

// 拍照页面，切换前后摄像头按钮按钮
- (void)switchCameraBtnPressed:(UIButton *)sender
{
    sender.selected = !sender.selected;
    [_captureManager switchCamera:sender.selected];
}

// 拍照页面，闪光灯按钮
- (void)flashBtnPressed:(UIButton *)sender
{
    [_captureManager switchFlashMode:sender];
}

#pragma mark ------------notification-------------
- (void)orientationDidChange:(NSNotification *)noti
{
    if (!_cameraBtnSet || (_cameraBtnSet.count <= 0)) {
        return;
    }

    [_cameraBtnSet enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        UIButton *btn = ([obj isKindOfClass:[UIButton class]] ? (UIButton *)obj : nil);

        if (!btn) {
            *stop = YES;
            return;
        }

        btn.layer.anchorPoint = CGPointMake(0.5, 0.5);
        CGAffineTransform transform = CGAffineTransformMakeRotation(0);
        switch ([UIDevice currentDevice].orientation) {
            case UIDeviceOrientationPortrait:// 1
                {
                    transform = CGAffineTransformMakeRotation(0);
                    break;
                }

            case UIDeviceOrientationPortraitUpsideDown:// 2
                {
                    transform = CGAffineTransformMakeRotation(M_PI);
                    break;
                }

            case UIDeviceOrientationLandscapeLeft:// 3
                {
                    transform = CGAffineTransformMakeRotation(M_PI_2);
                    break;
                }

            case UIDeviceOrientationLandscapeRight:// 4
                {
                    transform = CGAffineTransformMakeRotation(-M_PI_2);
                    break;
                }

            default:
                break;
        }
        [UIView animateWithDuration:0.3f animations:^{
            btn.transform = transform;
        }];
    }];
}

#pragma mark ---------rotate(only when this controller is presented, the code below effect)-------------
// <iOS6
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
    return interfaceOrientation == UIInterfaceOrientationPortrait;
}

#if __IPHONE_OS_VERSION_MAX_ALLOWED >= __IPHONE_6_0
// iOS6+
- (BOOL)shouldAutorotate
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationOrientationChange object:nil];
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskAll;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}
#endif

@end