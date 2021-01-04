//
//  DateExtensions.h
//  CIXExtensions
//
//  Created by Steve Palmer on 15/11/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface NSDate (DateExtensions)
    -(NSString *)friendlyDescription;
    -(NSDate *)toLocalDate;
    -(NSDate *)fromLocalDate;
    +(NSDate *)localDate;
    +(NSDate *)defaultDate;
    -(NSDate *)GMTBSTtoUTC;
    -(NSDate *)UTCtoGMTBST;
@end
