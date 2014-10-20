//
//  UIImage+ImageWithDataNoCopy.m
//  DailyPhoto
//
//  Created by Антон Буков on 30.11.13.
//  Copyright (c) 2013 Codeless Solution. All rights reserved.
//

#import <sys/mman.h>
#import "UIImage+DecompressAndMap.h"

@implementation UIImage (DecompressAndMap)

// conform to CGDataProviderReleaseDataCallback
void munmap_wrapper(void *p, const void *cp, size_t l) { munmap(p,l); }

- (UIImage *)decompressAndMapToData:(NSData *__autoreleasing *)data
{
    return [self decompressAndMapToData:data
                               withCrop:(CGRect){CGPointZero,self.size}
                              andResize:self.size];
}

- (UIImage *)decompressAndMapToData:(NSData *__autoreleasing *)data withCrop:(CGRect)cropRect
{
    return [self decompressAndMapToData:data
                               withCrop:cropRect
                              andResize:cropRect.size];
}

- (UIImage *)decompressAndMapToData:(NSData *__autoreleasing *)data withResize:(CGSize)resizeSize;
{
    return [self decompressAndMapToData:data
                               withCrop:(CGRect){CGPointZero,self.size}
                              andResize:resizeSize];
}

- (UIImage *)decompressAndMapToData:(NSData *__autoreleasing *)data withCrop:(CGRect)cropRect andResize:(CGSize)resizeSize;
{
    CGImageRef sourceImage = self.CGImage;
    
    //Parameters needed to create the bitmap context
    CGFloat scale = [UIScreen mainScreen].scale;
    uint32_t width = resizeSize.width*scale;//CGImageGetWidth(sourceImage);
    uint32_t height = resizeSize.height*scale;//CGImageGetHeight(sourceImage);
    NSInteger bitsPerComponent = 8;    //Each component is 1 byte, so 8 bits
    NSInteger bytesPerRow = 4 * width; //Uncompressed RGBA is 4 bytes per pixel
    
    size_t size = height*bytesPerRow+4+4+4;
    NSMutableData *buffer = [NSMutableData dataWithLength:size];
    uint8_t *bytes = buffer.mutableBytes;
    *(uint32_t *)(bytes+0) = (uint32_t)width;
    *(uint32_t *)(bytes+4) = (uint32_t)height;
    *(float *)(bytes+8) = (float)scale;
    bytes += 12;
    *data = buffer;
    
    //Create uncompressed context, draw the compressed source image into it
    //and save the resulting image.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(bytes, width, height, bitsPerComponent, bytesPerRow, colorSpace, (uint32_t)kCGImageAlphaPremultipliedLast);
    
    CGFloat kx = resizeSize.width*scale / cropRect.size.width;
    CGFloat ky = resizeSize.height*scale / cropRect.size.height;
    CGRect drawRect = CGRectMake(-cropRect.origin.x*kx,
                                 -cropRect.origin.y*kx,
                                 self.size.width*kx,
                                 self.size.height*ky);
    CGContextDrawImage(context, drawRect, sourceImage);
    
    //Tidy up
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    
    return [UIImage imageMapFromData:buffer];
}

///

- (UIImage *)decompressAndMapToPath:(NSString *)path
{
    return [self decompressAndMapToPath:path
                               withCrop:(CGRect){CGPointZero,self.size}
                              andResize:self.size];
}

- (UIImage *)decompressAndMapToPath:(NSString *)path withCrop:(CGRect)cropRect
{
    return [self decompressAndMapToPath:path
                               withCrop:cropRect
                              andResize:cropRect.size];
}

- (UIImage *)decompressAndMapToPath:(NSString *)path withResize:(CGSize)resizeSize;
{
    return [self decompressAndMapToPath:path
                               withCrop:(CGRect){CGPointZero,self.size}
                              andResize:resizeSize];
}

- (UIImage *)decompressAndMapToPath:(NSString *)path withCrop:(CGRect)cropRect andResize:(CGSize)resizeSize;
{
    CGImageRef sourceImage = self.CGImage;
    
    //Parameters needed to create the bitmap context
    CGFloat scale = [UIScreen mainScreen].scale;
    uint32_t width = resizeSize.width*scale;//CGImageGetWidth(sourceImage);
    uint32_t height = resizeSize.height*scale;//CGImageGetHeight(sourceImage);
    NSInteger bitsPerComponent = 8;    //Each component is 1 byte, so 8 bits
    NSInteger bytesPerRow = 4 * width; //Uncompressed RGBA is 4 bytes per pixel
    
    FILE *file = fopen([path UTF8String], "w+");
    if (file == NULL)
        return nil;
    int filed = fileno(file);
    size_t size = height*bytesPerRow+4+4+4;
    ftruncate(filed, size);
    char *data = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, filed, 0);
    *(uint32_t *)(data+0) = (uint32_t)width;
    *(uint32_t *)(data+4) = (uint32_t)height;
    *(float *)(data+8) = (float)scale;
    
    data += 12;
    size -= 12;
    fclose(file);
    
    //Create uncompressed context, draw the compressed source image into it
    //and save the resulting image.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, (uint32_t)kCGImageAlphaPremultipliedFirst);
    
    CGFloat kx = resizeSize.width*scale / cropRect.size.width;
    CGFloat ky = resizeSize.height*scale / cropRect.size.height;
    CGRect drawRect = CGRectMake(-cropRect.origin.x*kx,
                                 -cropRect.origin.y*kx,
                                 self.size.width*kx,
                                 self.size.height*ky);
    CGContextDrawImage(context, drawRect, sourceImage);
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(data, data, size, munmap_wrapper);
    CGImageRef inflatedImage = CGImageCreate(width, height, bitsPerComponent, 4*8, bytesPerRow, colorSpace, (uint32_t)kCGImageAlphaPremultipliedLast, provider, NULL, NO, kCGRenderingIntentDefault);
    
    //Tidy up
    CGColorSpaceRelease(colorSpace);
    CGContextRelease(context);
    CGDataProviderRelease(provider);
    
    UIImage *img = [UIImage imageWithCGImage:inflatedImage scale:self.scale orientation:UIImageOrientationUp];
    CGImageRelease(inflatedImage);
    return img;
}

+ (UIImage *)imageMapFromData:(NSData *)data
{
    uint8_t *bytes = (uint8_t *)data.bytes;
    uint32_t width = *(uint32_t *)(bytes + 0);
    uint32_t height = *(uint32_t *)(bytes + 4);
    float scale = *(float *)(bytes + 8);
    bytes += 12;
    
    NSInteger bitsPerComponent = 8;
    NSInteger bytesPerRow = 4 * width;
    size_t size = height*bytesPerRow;
    
    if (data.length < size + 12)
        return nil;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(bytes, bytes, size, munmap_wrapper);
    CGImageRef inflatedImage = CGImageCreate(width, height, bitsPerComponent, 4*8, bytesPerRow, colorSpace, (uint32_t)kCGImageAlphaPremultipliedLast, provider, NULL, NO, kCGRenderingIntentDefault);
    
    //Tidy up
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    
    UIImage *img = [UIImage imageWithCGImage:inflatedImage scale:scale orientation:UIImageOrientationUp];
    CGImageRelease(inflatedImage);
    return img;
}

+ (UIImage *)imageMapFromPath:(NSString *)path
{
    NSError *error = nil;
    NSData *data = [NSData dataWithContentsOfFile:path options:NSDataReadingMappedAlways error:&error];
    if (error != nil || data == nil)
        return nil;
    return [UIImage imageMapFromData:data];
}

@end
