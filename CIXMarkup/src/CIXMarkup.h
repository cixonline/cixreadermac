//
//  CIXMarkup.h
//  CIXMarkup
//
//  Created by Steve Palmer on 24/06/2015.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CIXMarkup : NSObject
    +(NSString *)markupToHTML:(NSString *)text;
@end
