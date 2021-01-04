//
//  ProfileCollection.h
//  CIXClient
//
//  Created by Steve Palmer on 27/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Profile.h"

@interface ProfileCollection : NSObject <NSFastEnumeration> {
@private
    NSMutableArray * _profiles;
}

// Accessors
-(void)sync;
-(Profile *)get:(NSString *)username;
-(void)add:(Profile *)profile;
@end
