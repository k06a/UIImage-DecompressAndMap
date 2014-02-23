//
//  ABFastImageCell.m
//  ABImageMapping
//
//  Created by Антон Буков on 23.02.14.
//  Copyright (c) 2014 Codeless Solutions. All rights reserved.
//

#import "ABFastImageCell.h"

@implementation ABFastImageCell

static void addRoundedRectToPath(CGContextRef context, CGRect rect, float ovalWidth, float ovalHeight)
{
    if (ovalWidth == 0 || ovalHeight == 0) {
        CGContextAddRect(context, rect);
        return;
    }
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, CGRectGetMinX(rect), CGRectGetMinY(rect));
    CGContextScaleCTM(context, ovalWidth, ovalHeight);
    float fw = CGRectGetWidth(rect) / ovalWidth;
    float fh = CGRectGetHeight(rect) / ovalHeight;
    CGContextMoveToPoint(context, fw, fh/2);
    CGContextAddArcToPoint(context, fw, fh, fw/2, fh, 1);
    CGContextAddArcToPoint(context, 0, fh, 0, fh/2, 1);
    CGContextAddArcToPoint(context, 0, 0, fw/2, 0, 1);
    CGContextAddArcToPoint(context, fw, 0, fw, fh/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}

- (void)drawRect:(CGRect)rect
{
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [UIColor whiteColor].CGColor);
    CGContextFillRect(context, self.bounds);
    
    CGContextSaveGState(context);
    NSInteger dx = (self.bounds.size.width/10)/2;
    addRoundedRectToPath(context, CGRectInset(self.bounds, dx, dx), 2*dx, 2*dx);
    CGContextClip(context);
    [self.image drawInRect:CGRectInset(self.bounds, dx, dx)];
    CGContextRestoreGState(context);
}

@end
