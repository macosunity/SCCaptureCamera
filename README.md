SCCaptureCamera
===============

A Custom Camera with AVCaptureSession to take a square picture. And the UI is patterned on Instagram.

It can work in iPad, too.

Usage：
----------
0、Import four frameworks: 
```
CoreMedia.framework、QuartzCore.framework、AVFoundation.framework、ImageIO.framework
```

1、Drag "SCCaptureCamera" and "SCCommon" to your project.

2、Import "SCNavigationController.h" and code like this:
```
    //show camera
    SCNavigationController *nav = [[SCNavigationController alloc] init];
    nav.scNaigationDelegate = self;
    [nav showCameraWithViewController:self];
    
    //show photo library
    SCNavigationController *nav = [[SCNavigationController alloc] init];
    nav.scNaigationDelegate = self;
    [nav showAlbumWithViewController:self];
```    
3、After take a picture, you can call back with delegate or a notification.

4、 delegate:
```
#pragma mark - SCNavigationControllerDelegate
- (void)didTakePictureWithImage:(UIImage *)image {
    ...
}
```


Finally, set ```SWITCH_SHOW_DEFAULT_IMAGE_FOR_NONE_CAMERA``` which is in the file ```SCCaptureCameraController.m``` to ```0```, it is just a joke for the devices which cannot take a picture.





