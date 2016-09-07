//
//  ViewController.m
//  SCCaptureCameraDemo
//
//  Created by Aevitx on 14-1-18.
//  Copyright (c) 2014年 Aevitx. All rights reserved.
//

#import "ViewController.h"
#import "PostViewController.h"

@interface ViewController ()<SCNavigationControllerDelegate>

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *showCameraBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    showCameraBtn.frame = CGRectMake(0, 0, 200, 40);
    showCameraBtn.center = CGPointMake(self.view.center.x, self.view.center.y-40);
    [showCameraBtn setTitle:@"show camera" forState:UIControlStateNormal];
    [showCameraBtn addTarget:self action:@selector(showCameraBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:showCameraBtn];
    
    UIButton *showAlbumBtn = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    showAlbumBtn.frame = CGRectMake(0, 0, 200, 40);
    showAlbumBtn.center = CGPointMake(self.view.center.x, self.view.center.y+40);
    [showAlbumBtn setTitle:@"show photo library" forState:UIControlStateNormal];
    [showAlbumBtn addTarget:self action:@selector(showAlbumBtnPressed:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:showAlbumBtn];
}

- (void)showCameraBtnPressed:(id)sender {
    SCNavigationController *nav = [[SCNavigationController alloc] init];
    nav.scNaigationDelegate = self;
    [nav showCameraWithViewController:self];
}

- (void)showAlbumBtnPressed:(id)sender {
    SCNavigationController *nav = [[SCNavigationController alloc] init];
    nav.scNaigationDelegate = self;
    [nav showAlbumWithViewController:self];
}

#pragma mark - SCNavigationControllerDelegate
- (void)didTakePictureWithImage:(UIImage *)image {
    
    PostViewController *con = [[PostViewController alloc] init];
    con.postImage = image;
    [self.navigationController pushViewController:con animated:YES];
}

@end
