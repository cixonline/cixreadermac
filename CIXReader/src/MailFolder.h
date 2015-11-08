//
//  MailFolder.h
//  CIXReader
//
//  Created by Steve Palmer on 29/08/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "FolderBase.h"

@interface MailFolder : FolderBase<FolderProtocol>

@property NSImage * icon;

// Accessors
-(id)initWithName:(NSString *)name andImage:(NSImage *)image;
@end
