//
//  UIImage+Color.m
//  FlatUI
//
//  Created by thilong on 5/3/13.
//  org author : Jack Flintermann 
//  Copyright (c) 2013 TYC. All rights reserved.
//

#import "UIImage+Color.h"

@implementation UIImage (FlatUI)

static CGFloat edgeSizeFromCornerRadius(CGFloat cornerRadius) {
	return cornerRadius * 2 + 1;
}

+ (UIImage *)imageWithColor:(UIColor *)color
               cornerRadius:(CGFloat)cornerRadius {
	CGFloat minEdgeSize = edgeSizeFromCornerRadius(cornerRadius);
	CGRect rect = CGRectMake(0, 0, minEdgeSize, minEdgeSize);
	UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
	roundedRect.lineWidth = 0;
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
	[color setFill];
	[roundedRect fill];
	[roundedRect stroke];
	[roundedRect addClip];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return [image resizableImageWithCapInsets:UIEdgeInsetsMake(cornerRadius, cornerRadius, cornerRadius, cornerRadius)];
}

+ (UIImage *)imageWithColor:(UIColor *)color
               cornerRadius:(CGFloat)cornerRadius
                       size:(CGSize)size {
	CGRect rect = CGRectMake(0, 0, size.width, size.height);
	UIBezierPath *roundedRect = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:cornerRadius];
	roundedRect.lineWidth = 0;
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
	[color setFill];
	[roundedRect fill];
	[roundedRect stroke];
	[roundedRect addClip];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

+ (UIImage *)buttonImageWithColor:(UIColor *)color
                     cornerRadius:(CGFloat)cornerRadius
                      shadowColor:(UIColor *)shadowColor
                     shadowInsets:(UIEdgeInsets)shadowInsets {
	UIImage *topImage = [self imageWithColor:color cornerRadius:cornerRadius];
	UIImage *bottomImage = [self imageWithColor:shadowColor cornerRadius:cornerRadius];
	CGFloat totalHeight = edgeSizeFromCornerRadius(cornerRadius) + shadowInsets.top + shadowInsets.bottom;
	CGFloat totalWidth = edgeSizeFromCornerRadius(cornerRadius) + shadowInsets.left + shadowInsets.right;
	CGFloat topWidth = edgeSizeFromCornerRadius(cornerRadius);
	CGFloat topHeight = edgeSizeFromCornerRadius(cornerRadius);
	CGRect topRect = CGRectMake(shadowInsets.left, shadowInsets.top, topWidth, topHeight);
	CGRect bottomRect = CGRectMake(0, 0, totalWidth, totalHeight);
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(totalWidth, totalHeight), NO, 0.0f);
	if (!CGRectEqualToRect(bottomRect, topRect)) {
		[bottomImage drawInRect:bottomRect];
	}
	[topImage drawInRect:topRect];
	UIImage *buttonImage = UIGraphicsGetImageFromCurrentImageContext();
	UIEdgeInsets resizeableInsets = UIEdgeInsetsMake(cornerRadius + shadowInsets.top,
	                                                 cornerRadius + shadowInsets.left,
	                                                 cornerRadius + shadowInsets.bottom,
	                                                 cornerRadius + shadowInsets.right);
	UIGraphicsEndImageContext();
	return [buttonImage resizableImageWithCapInsets:resizeableInsets];
}

+ (UIImage *)circularImageWithColor:(UIColor *)color
                               size:(CGSize)size {
	CGRect rect = CGRectMake(0, 0, size.width, size.height);
	UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:rect];
	UIGraphicsBeginImageContextWithOptions(rect.size, NO, 0.0f);
	[color setFill];
	[color setStroke];
	[circle addClip];
	[circle fill];
	[circle stroke];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

- (UIImage *)imageWithMinimumSize:(CGSize)size {
	CGRect rect = CGRectMake(0, 0, size.width, size.height);
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(size.width, size.height), NO, 0.0f);
	[self drawInRect:rect];
	UIImage *resized = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return [resized resizableImageWithCapInsets:UIEdgeInsetsMake(size.height / 2, size.width / 2, size.height / 2, size.width / 2)];
}

+ (UIImage *)stepperPlusImageWithColor:(UIColor *)color {
	CGFloat iconEdgeSize = 15;
	CGFloat iconInternalEdgeSize = 3;
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(iconEdgeSize, iconEdgeSize), NO, 0.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[color setFill];
	CGFloat padding = (iconEdgeSize - iconInternalEdgeSize) / 2;
	CGContextFillRect(context, CGRectMake(padding, 0, iconInternalEdgeSize, iconEdgeSize));
	CGContextFillRect(context, CGRectMake(0, padding, iconEdgeSize, iconInternalEdgeSize));
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

+ (UIImage *)stepperMinusImageWithColor:(UIColor *)color {
	CGFloat iconEdgeSize = 15;
	CGFloat iconInternalEdgeSize = 3;
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(iconEdgeSize, iconEdgeSize), NO, 0.0f);
	CGContextRef context = UIGraphicsGetCurrentContext();
	[color setFill];
	CGFloat padding = (iconEdgeSize - iconInternalEdgeSize) / 2;
	CGContextFillRect(context, CGRectMake(0, padding, iconEdgeSize, iconInternalEdgeSize));
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return image;
}

+ (UIImage *)backButtonImageWithColor:(UIColor *)color
                           barMetrics:(UIBarMetrics)metrics
                         cornerRadius:(CGFloat)cornerRadius {
	CGSize size;
	if (metrics == UIBarMetricsDefault) {
		size = CGSizeMake(50, 30);
	}
	else {
		size = CGSizeMake(60, 23);
	}
	UIBezierPath *path = [self bezierPathForBackButtonInRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:cornerRadius];
	UIGraphicsBeginImageContextWithOptions(size, NO, 0.0f);
	[color setFill];
	[path addClip];
	[path fill];
	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return [image resizableImageWithCapInsets:UIEdgeInsetsMake(cornerRadius, 15, cornerRadius, cornerRadius)];
}

+ (UIBezierPath *)bezierPathForBackButtonInRect:(CGRect)rect cornerRadius:(CGFloat)radius {
	UIBezierPath *path = [UIBezierPath bezierPath];
	CGPoint mPoint = CGPointMake(CGRectGetMaxX(rect) - radius, rect.origin.y);
	CGPoint ctrlPoint = mPoint;
	[path moveToPoint:mPoint];
    
	ctrlPoint.y += radius;
	mPoint.x += radius;
	mPoint.y += radius;
	if (radius > 0) [path addArcWithCenter:ctrlPoint radius:radius startAngle:(float)M_PI + (float)M_PI_2 endAngle:0 clockwise:YES];
    
	mPoint.y = CGRectGetMaxY(rect) - radius;
	[path addLineToPoint:mPoint];
    
	ctrlPoint = mPoint;
	mPoint.y += radius;
	mPoint.x -= radius;
	ctrlPoint.x -= radius;
	if (radius > 0) [path addArcWithCenter:ctrlPoint radius:radius startAngle:0 endAngle:(float)M_PI_2 clockwise:YES];
    
	mPoint.x = rect.origin.x + (10.0f);
	[path addLineToPoint:mPoint];
    
	[path addLineToPoint:CGPointMake(rect.origin.x, CGRectGetMidY(rect))];
    
	mPoint.y = rect.origin.y;
	[path addLineToPoint:mPoint];
    
	[path closePath];
	return path;
}

- (UIImage *) imageWithTintColor:(UIColor *)tintColor
{
    return [self imageWithTintColor:tintColor blendMode:kCGBlendModeDestinationIn];
}

- (UIImage *) imageWithGradientTintColor:(UIColor *)tintColor
{
    return [self imageWithTintColor:tintColor blendMode:kCGBlendModeOverlay];
}

- (UIImage *) imageWithTintColor:(UIColor *)tintColor blendMode:(CGBlendMode)blendMode
{
    //We want to keep alpha, set opaque to NO; Use 0.0f for scale to use the scale factor of the device’s main screen.
    UIGraphicsBeginImageContextWithOptions(self.size, NO, 0.0f);
    [tintColor setFill];
    CGRect bounds = CGRectMake(0, 0, self.size.width, self.size.height);
    UIRectFill(bounds);
    
    //Draw the tinted image in context
    [self drawInRect:bounds blendMode:blendMode alpha:1.0f];
    
    if (blendMode != kCGBlendModeDestinationIn) {
        [self drawInRect:bounds blendMode:kCGBlendModeDestinationIn alpha:1.0f];
    }
    
    UIImage *tintedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return tintedImage;
}


@end
