//
//  Address.h
//  CIXReader
//
//  Created by Steve Palmer on 08/10/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface Address : NSObject {
    NSString * _address;
}

@property NSString * scheme;
@property (nonatomic) NSString * query;
@property NSString * data;
@property NSString * schemeAndQuery;
@property BOOL unread;

// Accessors
-(id)initWithString:(NSString *)address;
-(NSString *)address;
@end
