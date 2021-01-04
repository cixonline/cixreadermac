//
//  ImageExtensions.h
//  CIXExtensions
//
//  Created by Steve Palmer on 10/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface ImageClass (ImageExtensions)
    -(NSData *)JFIFData:(float)compressionValue;
    -(ImageClass *)constrain:(int)maxWidth;
    -(ImageClass *)resize:(CGSize)newSize;
    -(ImageClass *)maskedCircularImageWithDiameter:(CGFloat)diameter;
@end
