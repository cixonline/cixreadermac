//
//  SearchFolder.h
//  CIXReader
//
//  Created by Steve Palmer on 19/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "SmartFolder.h"

@interface SearchFolder : SmartFolder

@property (atomic, readwrite) NSString * searchString;

@end
