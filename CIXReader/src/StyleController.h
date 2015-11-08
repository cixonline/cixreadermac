//
//  StyleController.h
//  CIXReader
//
//  Created by Steve Palmer on 24/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface StyleController : NSObject {
    NSString * _htmlTemplate;
    NSString * _cssStylesheet;
    NSString * _jsScript;
    NSString * _styleName;
    BOOL _inited;
}

// Properties
@property (strong, atomic) NSString * highlightString;

// Accessors
-(id)initForStyle:(NSString *)styleName;
+(void)loadStylesMap;
-(NSString *)styledTextForCollection:(NSArray *)array;
-(NSArray *)allStyles;

-(NSString *)imageFromTag:(NSString *)tag;
-(NSString *)htmlFromTag:(NSString *)tag;
-(NSString *)stringFromTag:(NSString *)tag;
-(NSString *)dateFromTag:(NSDate *)tag;
@end
