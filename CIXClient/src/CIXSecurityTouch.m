//
//  CIXSecurityTouch.m
//  CIXClient
//
//  Created by Steve Palmer on 29/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import <CIX.h>
#import <Security/Security.h>

static NSString * _serviceName = @"CIXReader:CIX";
static NSString * _password;

@implementation CIX (CIXSecurity)

+(NSMutableDictionary *)getKeychainQuery:(NSString *)service
{
    return [NSMutableDictionary dictionaryWithObjectsAndKeys:
            (__bridge id)kSecClassGenericPassword, (__bridge id)kSecClass,
            service, (__bridge id)kSecAttrService,
            service, (__bridge id)kSecAttrAccount,
            (__bridge id)kSecAttrAccessibleAfterFirstUnlock, (__bridge id)kSecAttrAccessible,
            nil];
}

/** Set the current CIX password
 
 This method sets the password part of the credentials for subsequent access to the API
 server. No attempt it made to validate the password as part of this method. An invalid
 password will result in authentication failures from the CIX service on the next access
 to the API server.
 
 @warning The CIX password is passed in plaintext but stored in the Mac OSX keychain.
 During execution, the password is cached in memory in plaintext for performance reasons.
 
 @param newPassword The new CIX password.
 */
+(void)setPassword:(NSString *)newPassword
{
    _password = newPassword;
    
    NSMutableDictionary *keychainQuery = [self getKeychainQuery:_serviceName];
    SecItemDelete((__bridge CFDictionaryRef)keychainQuery);
    [keychainQuery setObject:[NSKeyedArchiver archivedDataWithRootObject:newPassword] forKey:(__bridge id)kSecValueData];
    SecItemAdd((__bridge CFDictionaryRef)keychainQuery, NULL);
}

/** Return the current CIX password
 
 This property returns the current CIX password obtained from the Mac OSX keychain
 as a plaintext string.
 
 @return The CIX password in plaintext
 */
+(NSString *)password
{
    if (_password == nil)
    {
        NSMutableDictionary *keychainQuery = [self getKeychainQuery:_serviceName];
        [keychainQuery setObject:(id)kCFBooleanTrue forKey:(__bridge id)kSecReturnData];
        [keychainQuery setObject:(__bridge id)kSecMatchLimitOne forKey:(__bridge id)kSecMatchLimit];
        CFDataRef keyData = NULL;
        if (SecItemCopyMatching((__bridge CFDictionaryRef)keychainQuery, (CFTypeRef *)&keyData) == noErr)
        {
            @try {
                _password = [NSKeyedUnarchiver unarchiveObjectWithData:(__bridge NSData *)keyData];
            }
            @catch (NSException *e) {
                NSLog(@"Unarchive of %@ failed: %@", _serviceName, e);
            }
            @finally {}
        }
        if (keyData)
            CFRelease(keyData);
    }
    return _password;
}
@end
