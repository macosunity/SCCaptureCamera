//
//  SCImagePickerManager.m
//  SCCaptureCameraDemo
//
//  Created by 王亮 on 16/6/24.
//  Copyright © 2016年 Aevitx. All rights reserved.
//

#import "SCImagePickerManager.h"

@implementation SCImagePickerManager

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo {
    
    __block SCImagePickerManager *blockSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        if (blockSelf.finishPickImageBlock) {
            blockSelf.finishPickImageBlock();
        }
    }];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info{
    
    __block SCImagePickerManager *blockSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        UIImage *originalImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        if (blockSelf.finishPickImageMediaBlock) {
            blockSelf.finishPickImageMediaBlock(originalImage);
        }
    }];
}

@end
