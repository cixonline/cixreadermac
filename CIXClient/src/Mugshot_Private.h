//
//  Mugshot_Private.h
//  CIXClient
//
//  Created by Steve Palmer on 10/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#ifndef CIXClient_Mugshot_Private_h
#define CIXClient_Mugshot_Private_h

#import "Mugshot.h"

/* Private Mugshot class accessors
 */
@interface Mugshot (Private)
    +(void)create;
    -(void)sync;
    +(ImageClass *)defaultMugshot;
@end

#endif
