//
//  Signatures.h
//  CIXReader
//
//  Created by Steve Palmer on 11/09/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

@interface Signatures : NSObject {
	NSMutableDictionary * _signatures;
}

// Public functions
+(Signatures *)defaultSignatures;
+(NSString *)noSignaturesString;
-(NSArray *)signatureTitles;
-(NSString *)signatureForTitle:(NSString *)title;
-(NSString *)expandSignatureForTitle:(NSString *)title;
-(void)addSignature:(NSString *)title withText:(NSString *)withText;
-(void)removeSignature:(NSString *)title;
@end
