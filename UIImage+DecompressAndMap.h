//
//  UIImage+ImageWithDataNoCopy.h
//  DailyPhoto
//
//  Created by Антон Буков on 30.11.13.
//  Copyright (c) 2013 Codeless Solution. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (DecompressAndMap)

- (UIImage *)decompressAndMapToPath:(NSString *)path;
- (UIImage *)decompressAndMapToPath:(NSString *)path withCrop:(CGRect)cropRect;
- (UIImage *)decompressAndMapToPath:(NSString *)path withResize:(CGSize)resizeSize;
- (UIImage *)decompressAndMapToPath:(NSString *)path withCrop:(CGRect)cropRect andResize:(CGSize)resizeSize;

+ (UIImage *)imageMapFromPath:(NSString *)path;

@end
