//
//  CIXSecurity.m
//  CIXClient
//
//  Created by Steve Palmer on 29/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

static NSString * _password;

@implementation CIX (CIXSecurity)

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
    const char * cServiceName = [@"CIXReader:CIX" cStringUsingEncoding:NSWindowsCP1252StringEncoding];
    const char * cPassword = [newPassword cStringUsingEncoding:NSWindowsCP1252StringEncoding];
    const char * cUsername = [[self username] cStringUsingEncoding:NSWindowsCP1252StringEncoding];
    SecKeychainItemRef itemRef;
    OSStatus status;
    
    _password = newPassword;
    
    UInt32 serviceNameLength = (UInt32)strlen(cServiceName);
    UInt32 accountNameLength = (UInt32)strlen(cUsername);
    UInt32 passwordLength = (UInt32)strlen(cPassword);
    
    status = SecKeychainFindGenericPassword(NULL, serviceNameLength, cServiceName, accountNameLength, cUsername, &passwordLength, NULL, &itemRef);
    if (status == noErr)
        SecKeychainItemDelete(itemRef);

    SecKeychainAddGenericPassword(NULL, serviceNameLength, cServiceName, accountNameLength, cUsername, passwordLength, cPassword, NULL);
}

/** Remove the current CIX password

 This method removes the password stored in the keychain.
 */
+(void)deletePassword
{
    const char * cServiceName = [@"CIXReader:CIX" cStringUsingEncoding:NSWindowsCP1252StringEncoding];
    const char * cUsername = [[self username] cStringUsingEncoding:NSWindowsCP1252StringEncoding];
    SecKeychainItemRef itemRef;
    OSStatus status;
    
    UInt32 serviceNameLength = (UInt32)strlen(cServiceName);
    UInt32 accountNameLength = (UInt32)strlen(cUsername);
    
    status = SecKeychainFindGenericPassword(NULL, serviceNameLength, cServiceName, accountNameLength, cUsername, NULL, NULL, &itemRef);
    if (status == noErr)
        SecKeychainItemDelete(itemRef);
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
        const char * cServiceName = [@"CIXReader:CIX" cStringUsingEncoding:NSWindowsCP1252StringEncoding];
        const char * cUsername = [[self username] cStringUsingEncoding:NSWindowsCP1252StringEncoding];
        
        UInt32 passwordLength;
        void * passwordPtr;
        NSString * thePassword;
        OSStatus status;
        
        UInt32 serviceNameLength = (UInt32)strlen(cServiceName);
        UInt32 accountNameLength = (UInt32)strlen(cUsername);
        
        status = SecKeychainFindGenericPassword(NULL, serviceNameLength, cServiceName, accountNameLength, cUsername, &passwordLength, &passwordPtr, NULL);
        if (status != noErr)
            thePassword = @"";
        else
        {
            thePassword = [[NSString alloc] initWithBytes:passwordPtr length:passwordLength encoding:NSWindowsCP1252StringEncoding];
            SecKeychainItemFreeContent(NULL, passwordPtr);
        }
        _password = thePassword;
    }
    return _password;
}
@end
