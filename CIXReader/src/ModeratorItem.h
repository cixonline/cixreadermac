//
//  ModeratorItem.h
//  CIXReader
//
//  Created by Steve Palmer on 05/10/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

@interface ModeratorItem : NSObject

@property (retain, readwrite) NSImage * image;
@property (retain, readwrite) NSString * name;

@end

@interface ModeratorCollectionViewItem : NSCollectionViewItem

@property (retain, readwrite) id item;

@end


