//
//  DirForum.h
//  CIXClient
//
//  Created by Steve Palmer on 28/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "DirCategory.h"

@interface DirForum : TableBase {
    BOOL _isModeratorsRefreshing;
    BOOL _isParticipantsRefreshing;
}

@property ID_type ID;
@property NSString * name;
@property NSString * title;
@property NSString * desc;
@property NSString * type;
@property NSString * mods;
@property NSString * parts;
@property NSString * cat;
@property NSString * sub;
@property int recent;
@property BOOL detailsPending;
@property BOOL joinPending;
@property NSString * addedMods;
@property NSString * removedMods;
@property NSString * addedParts;
@property NSString * removedParts;

// Accessors
-(BOOL)isClosed;
-(BOOL)isModerator;
-(void)join;
-(BOOL)hasPending;
-(void)requestAdmission;
-(NSArray *)moderators;
-(void)addModerators:(NSArray *)names;
-(void)removeModerators:(NSArray *)names;
-(NSArray *)addedModerators;
-(NSArray *)removedModerators;
-(NSArray *)participants;
-(void)addParticipants:(NSArray *)names;
-(void)removeParticipants:(NSArray *)names;
-(NSArray *)addedParticipants;
-(NSArray *)removedParticipants;
-(void)getDateOfLatestMessage;
-(void)refresh;
-(void)update;
@end
