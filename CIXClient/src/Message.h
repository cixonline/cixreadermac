//
//  Message.h
//  CIXClient
//
//  Created by Steve Palmer on 21/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "TableBase.h"

@class Folder;

@interface Message : TableBase {
    Message * _lastChildMessage;
    NSMutableArray * _attachments;
    Folder * _folder;
    int _level;
}

@property ID_type ID;
@property ID_type topicID;
@property int commentID;
@property int remoteID;
@property int rootID;
@property NSString * author;
@property NSString * body;
@property NSDate * date;
@property BOOL unread;
@property BOOL priority;
@property BOOL starred;
@property BOOL readLocked;
@property BOOL ignored;
@property BOOL readPending;
@property BOOL postPending;
@property BOOL starPending;
@property BOOL withdrawPending;

// Accessors
-(int)level;
-(Message *)parent;
-(Folder*)forum;
-(Folder*)topic;
-(NSString *)subject;
-(Message *)root;
-(BOOL)isDraft;
-(BOOL)isPseudo;
-(BOOL)isMine;
-(void)markRead;
-(void)markUnread;
-(void)addStar;
-(void)removeStar;
-(void)markReadLock;
-(void)clearReadLock;
-(void)setPriority;
-(void)removePriority;
-(void)setIgnore;
-(void)removeIgnore;
-(void)withdraw;
-(void)markReadThread;
-(void)markUnreadThread;
-(NSString *)quotedBody;
-(NSAttributedString *)attributedBody;
-(NSString *)bodyWithAttachments;
-(bool)hasChildren;
-(int)unreadChildren;
-(NSArray *)attachments;
-(void)attachFile:(NSData *)fileData withName:(NSString *)filename;
-(void)deleteAttachments;
@end
