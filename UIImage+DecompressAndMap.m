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

// conform to CGDataProviderReleaseDataCallback
void munmap_wrapper(void *p, const void *cp, size_t l) { munmap(p,l); }

- (UIImage *)decompressAndMapToPath:(NSString *)path withCrop:(CGRect)cropRect andResize:(CGSize)resizeSize;
{
    CGImageRef sourceImage = self.CGImage;
    
    //Parameters needed to create the bitmap context
    uint32_t width = resizeSize.width;//CGImageGetWidth(sourceImage);
    uint32_t height = resizeSize.height;//CGImageGetHeight(sourceImage);
    NSInteger bitsPerComponent = 8;    //Each component is 1 byte, so 8 bits
    NSInteger bytesPerRow = 4 * width; //Uncompressed RGBA is 4 bytes per pixel
    
    FILE *file = fopen([path UTF8String], "w+");
    if (file == NULL)
        return nil;
    int filed = fileno(file);
    size_t size = height*bytesPerRow+4+4;
    ftruncate(filed, size);
    char *data = mmap(NULL, size, PROT_READ|PROT_WRITE, MAP_SHARED, filed, 0);
    *(uint32_t *)(data+0) = (uint32_t)width;
    *(uint32_t *)(data+4) = (uint32_t)height;
    data += 8;
    size -= 8;
    fclose(file);
    
    //Create uncompressed context, draw the compressed source image into it
    //and save the resulting image.
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(data, width, height, bitsPerComponent, bytesPerRow, colorSpace, (uint32_t)kCGImageAlphaPremultipliedLast);
    
    CGFloat kx = resizeSize.width / cropRect.size.width;
    CGFloat ky = resizeSize.height / cropRect.size.height;
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
    
    return [UIImage imageWithCGImage:inflatedImage];
}

+ (UIImage *)imageMapFromPath:(NSString *)path
{
    FILE *file = fopen([path UTF8String], "rb");
    if (file == NULL)
        return nil;
    
    uint32_t sizes[2];
    fread(&sizes, 8, 1, file);
    uint32_t width = sizes[0];
    uint32_t height = sizes[1];
    
    NSInteger bitsPerComponent = 8;
    NSInteger bytesPerRow = 4 * width;
    size_t size = height*bytesPerRow + 4 + 4;
    char *data = mmap(NULL, size, PROT_READ, MAP_SHARED, fileno(file), 0);
    data += 8;
    size -= 8;
    fclose(file);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithData(data, data, size, munmap_wrapper);
    CGImageRef inflatedImage = CGImageCreate(width, height, bitsPerComponent, 4*8, bytesPerRow, colorSpace, (uint32_t)kCGImageAlphaPremultipliedLast, provider, NULL, NO, kCGRenderingIntentDefault);
    
    //Tidy up
    CGColorSpaceRelease(colorSpace);
    CGDataProviderRelease(provider);
    
    return [UIImage imageWithCGImage:inflatedImage];
}

@end
