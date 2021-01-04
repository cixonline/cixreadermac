//
//  Signatures.m
//  CIXReader
//
//  Created by Steve Palmer on 11/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "Signatures.h"
#import "Constants.h"
#import "AppDelegate.h"

/* We maintain a singleton of all signatures for simplicity
 * even though the caller can create their own collection.
 */
static Signatures * defaultSignatures = nil;

@implementation Signatures

/* init
 * Create an empty signature dictionary.
 */
-(id)init
{
	if ((self = [super init]) != nil)
	{
		_signatures = [NSMutableDictionary dictionary];
		[_signatures addEntriesFromDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:MAPref_Signatures]];
        
        if (_signatures.count == 0)
            [self addSignature:@"cix.support" withText:@"Using CIXReader %VERSION% for Mac OSX"];
	}
	return self;
}

/* Return the string that is used to display None in the UI
 */
+(NSString *)noSignaturesString
{
    return NSLocalizedString(@"None", nil);
}

/* Return the default signatures singleton.
 */
+(Signatures *)defaultSignatures
{
	if (defaultSignatures == nil)
		defaultSignatures = [[Signatures alloc] init];
	return defaultSignatures;
}

/* Return an array of all the signature titles.
 */
-(NSArray *)signatureTitles
{
	return [_signatures allKeys];
}

/* Returns the signature identified by the specified title. The
 * title cannot be nil. If the title does not appear in the list
 * of signatures we know about, the return value is nil.
 */
-(NSString *)signatureForTitle:(NSString *)title
{
    return [_signatures valueForKey:title];
}

/* Returns the signature identified by the specified title. The
 * title cannot be nil. If the title does not appear in the list
 * of signatures we know about, the return value is nil.
 */
-(NSString *)expandSignatureForTitle:(NSString *)title
{
	NSString * rawSignature = [self signatureForTitle:title];
    AppDelegate * app = (AppDelegate *)[NSApp delegate];
    return [rawSignature stringByReplacingOccurrencesOfString:@"%VERSION%" withString:[app applicationVersion]];
}

/* Adds a new signature (possibly replacing an existing signature
 * with the same title).
 */
-(void)addSignature:(NSString *)title withText:(NSString *)withText
{
	_signatures[title] = withText;
	[[NSUserDefaults standardUserDefaults] setObject:_signatures forKey:MAPref_Signatures];
}

/* Deletes the signature referenced by the specified title.
 */
-(void)removeSignature:(NSString *)title
{
	[_signatures removeObjectForKey:title];
	[[NSUserDefaults standardUserDefaults] setObject:_signatures forKey:MAPref_Signatures];
}
@end
