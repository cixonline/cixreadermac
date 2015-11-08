//
//  CRScriptCommand.m
//  CIXReader
//
//  Created by Steve Palmer on 16/06/2015.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "CRScriptCommand.h"
#import "AppDelegate.h"

@implementation CRScriptCommand

/* This is the entry point for all link handlers associated with CIXReader. Currently we parse
 * and manage the following format:
 *
 *   cix://<link>
 */
-(id)performDefaultImplementation
{
	NSScanner * scanner = [NSScanner scannerWithString:[self directParameter]];
	NSString * urlPrefix = nil;

	[scanner scanUpToString:@":" intoString:&urlPrefix];
	[scanner scanString:@":" intoString:nil];
	if (urlPrefix && [urlPrefix isEqualToString:@"cix"])
	{
		NSString * linkPath = nil;

		[scanner scanUpToString:@"" intoString:&linkPath];
		if (linkPath == nil)
			return nil;
		linkPath = [NSString stringWithFormat:@"%@:%@", urlPrefix, linkPath];
        [((AppDelegate *)[NSApp delegate]) setLaunchAddress:linkPath];
	}
	return nil;
}
@end
