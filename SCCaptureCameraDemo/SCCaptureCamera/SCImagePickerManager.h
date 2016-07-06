//
//  SCImagePickerManager.h
//  SCCaptureCameraDemo
//
//  Created by 王亮 on 16/6/24.
//  Copyright © 2016年 Aevitx. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^SCImageDidFinishPickingImageBlock)(void);
typedef void(^SCImageDidFinishPickingMediaWithInfoBlock)(UIImage *pickedImage);

@interface SCImagePickerManager : NSObject<UINavigationControllerDelegate,UIImagePickerControllerDelegate>

- (id)init;

@property (nonatomic,copy) SCImageDidFinishPickingImageBlock finishPickImageBlock;
@property (nonatomic,copy) SCImageDidFinishPickingMediaWithInfoBlock finishPickImageMediaBlock;

@end
