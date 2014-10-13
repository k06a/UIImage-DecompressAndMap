//
//  UIImage+ImageWithDataNoCopy.h
//  DailyPhoto
//
//  Created by Антон Буков on 30.11.13.
//  Copyright (c) 2013 Codeless Solution. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIImage (DecompressAndMap)

- (UIImage *)decompressAndMapToData:(NSData **)data;
- (UIImage *)decompressAndMapToData:(NSData **)data withCrop:(CGRect)cropRect;
- (UIImage *)decompressAndMapToData:(NSData **)data withResize:(CGSize)resizeSize;
- (UIImage *)decompressAndMapToData:(NSData **)data withCrop:(CGRect)cropRect andResize:(CGSize)resizeSize;

- (UIImage *)decompressAndMapToPath:(NSString *)path;
- (UIImage *)decompressAndMapToPath:(NSString *)path withCrop:(CGRect)cropRect;
- (UIImage *)decompressAndMapToPath:(NSString *)path withResize:(CGSize)resizeSize;
- (UIImage *)decompressAndMapToPath:(NSString *)path withCrop:(CGRect)cropRect andResize:(CGSize)resizeSize;

+ (UIImage *)imageMapFromData:(NSData *)data;
+ (UIImage *)imageMapFromPath:(NSString *)path;

@end
