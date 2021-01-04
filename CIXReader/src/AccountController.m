//
//  AccountController.m
//  CIXReader
//
//  Created by Steve Palmer on 26/08/2014.
//  Copyright (c) 2014-2020 ICUK Ltd. All rights reserved.
//

#import "AccountController.h"
#import "StringExtensions.h"
#import "ImageExtensions.h"
#import "CIX.h"
#import <Quartz/Quartz.h>

@implementation AccountController

/* Load the NIB for this panel.
 */
-(id)init
{
    if ((self = [super initWithWindowNibName:@"Account"]) != nil)
    {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        
        _isEditing = NO;
    }
    return self;
}

/* Populate the dialog from the current authenticated user's profile.
 */
-(void)awakeFromNib
{
    if (!_isInitialised)
    {
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(userProfileChanged:) name:MAUserProfileChanged object:nil];
        [nc addObserver:self selector:@selector(userMugshotChanged:) name:MAUserMugshotChanged object:nil];
        
        [mugshotImage setCircleDiameter:70];
        _isInitialised = YES;
    }
}

/* Hook up notifications for text changes.
 */
-(void)windowDidLoad
{
    [self setEditState:_isEditing];
    
    Profile * myProfile = [Profile profileForUser:CIX.username];
    [self refreshAccount:myProfile];
    [myProfile refresh];
    
    Mugshot * myMugshot = [Mugshot mugshotForUser:CIX.username];
    [self refreshMugshot:myMugshot];
    [myMugshot refresh];
}

/* Called when a user's account type is retrieved from the API. If it
 * is the one for this user, we update the Account panel.
 */
-(void)userProfileChanged:(NSNotification *)notification
{
    Response * response = (Response *)notification.object;
    if (response.errorCode == CCResponse_NoError)
    {
        Profile * profile = response.object;
        if ([profile.username isEqualToString:CIX.username])
            [self refreshAccount:profile];
    }
}

/* Called when a user's mugshot is retrieved from the API. If it is
 * the one for this user, we update the mugshot in the Account panel.
 */
-(void)userMugshotChanged:(NSNotification *)notification
{
    Response * response = (Response *)notification.object;
    if (response.errorCode == CCResponse_NoError)
    {
        Mugshot * mugshot = response.object;
        if ([mugshot.username isEqualToString:CIX.username])
            [mugshotImage setImage:mugshot.image];
    }
}

/* Update the dialog from the profile.
 */
-(void)refreshAccount:(Profile *)myProfile
{
    [accountName setStringValue:[myProfile username]];
    [fullName setStringValue:SafeString([myProfile fullname])];
    [eMailAddress setStringValue:SafeString([myProfile eMailAddress])];
    
    [lastOnDate setStringValue:SafeString([_dateFormatter stringFromDate:[myProfile lastOn]])];
    [location setStringValue:SafeString([myProfile location])];
    
    // Popup list has the codes 'm', 'f' and 'u' assigned to
    // the tags of the Male, Female and Don't Say items.
    char sexCode = 'u';
    if (!IsEmpty(myProfile.sex))
        sexCode = [[myProfile.sex lowercaseString] characterAtIndex:0];
    
    [sexList selectItemWithTag:sexCode];
    
    [aboutText setString:SafeString([myProfile about])];
    
    [notifyPM setState:(myProfile.flags & 1) ? NSOnState : NSOffState];
    [notifyTagged setState:(myProfile.flags & 2) ? NSOnState : NSOffState];

    NSString * accountTypeName;
    switch (CIX.userAccountType)
    {
        case AccountTypeFull:
            accountTypeName = NSLocalizedString(@"Full", nil);
            break;
            
        case AccountTypeBasic:
            accountTypeName = NSLocalizedString(@"Basic", nil);
            [upgradeButton setHidden:NO];
            break;
            
        default:
            accountTypeName = NSLocalizedString(@"Unknown", nil);
            break;
    }
    [accountType setStringValue:accountTypeName];
}

/* Update the mugshot in the dialog.
 */
-(void)refreshMugshot:(Mugshot *)myMugshot
{
    [mugshotImage setImage:myMugshot.image];
}

/* Change the UI to permit editing of fields.
 */
-(void)setEditState:(BOOL)value
{
    _isEditing = value;
    [fullName setEditable:_isEditing];
    [location setEditable:_isEditing];
    [aboutText setEditable:_isEditing];
    [sexList setEnabled:_isEditing];
    [eMailAddress setEditable:_isEditing];
    [mugshotImage setEditable:_isEditing];
    
    [notifyPM setEnabled:_isEditing];
    [notifyTagged setEnabled:_isEditing];
    
    [mugshotImage setFocusRingType:NSFocusRingTypeNone];
    [mugshotImage setAction:@selector(imageSelector:)];
    [mugshotImage setDelegate:self];
    
    NSColor * backColor = _isEditing ? [NSColor controlBackgroundColor] : [NSColor windowBackgroundColor];
    [fullName setBackgroundColor:backColor];
    [location setBackgroundColor:backColor];
    [aboutText setBackgroundColor:backColor];
    [eMailAddress setBackgroundColor:backColor];
    
    if (_isEditing)
    {
        [editButton setTitle:NSLocalizedString(@"Save", nil)];
        [[self window] makeFirstResponder:fullName];
        [fullName selectText:self];
    }
    else
    {
        [editButton setTitle:NSLocalizedString(@"Edit", nil)];
        [[self window] makeFirstResponder:saveButton];
    }
}

/* Invoked when the user clicks the mugshot image in edit mode.
 */
-(void)imageSelector:(id)sender
{
    if ([mugshotImage isEditable])
    {
        IKPictureTaker * picker = [IKPictureTaker pictureTaker];
        [picker setInputImage:mugshotImage.image];
        
        [picker setValue:@(YES) forKey:IKPictureTakerShowAddressBookPictureKey];
        
        [picker beginPictureTakerSheetForWindow:[self window]
                                   withDelegate:self
                                 didEndSelector:@selector(pictureTakerDidEnd:code:contextInfo:)
                                    contextInfo:nil];
    }
}

/* Use selects an image from the iamge picker.
 */
-(void)pictureTakerDidEnd:(IKPictureTaker*) pictureTaker code:(int) returnCode contextInfo:(void*) ctxInf
{
    if (returnCode == NSModalResponseOK)
    {
        mugshotImage.image = [pictureTaker.outputImage resize:NSMakeSize(100, 100)];
        _isImageModified = YES;
    }
}

/* Handle the user closing via the Close button.
 */
-(void)windowWillClose:(NSNotification *)notification
{
    [NSApp stopModalWithCode:NO];
}

/* Handle the edit button to toggle between editing and saving
 * changes.
 */
-(IBAction)handleEditButton:(id)sender
{
    if (_isEditing)
    {
        Profile * myProfile = [Profile profileForUser:CIX.username];
        BOOL isModified = NO;
        
        NSString * value = [fullName stringValue];
        if (![value isEqualToString:[myProfile fullname]])
        {
            [myProfile setFullname:value];
            isModified = YES;
        }
        
        value = [eMailAddress stringValue];
        if (![value isEqualToString:[myProfile eMailAddress]])
        {
            [myProfile setEMailAddress:value];
            isModified = YES;
        }
        
        value = [location stringValue];
        if (![value isEqualToString:[myProfile location]])
        {
            [myProfile setLocation:value];
            isModified = YES;
        }
        
        value = [aboutText string];
        if (![value isEqualToString:[myProfile about]])
        {
            [myProfile setAbout:value];
            isModified = YES;
        }
        
        switch ([sexList selectedTag])
        {
            case 'm':   value = @"m";   break;
            case 'f':   value = @"f";   break;
            case 'u':   value = @"u";   break;
                
            default:
                NSAssert(false, @"Invalid tag value in sexList list");
                break;
        }
        if (![value isEqualToString:[myProfile sex]])
        {
            [myProfile setSex:value];
            isModified = YES;
        }
        
        int flags = 0;
        if ([notifyPM state] == NSOnState)
            flags |= 1;
        if ([notifyTagged state] == NSOnState)
            flags |= 2;
        if (flags != myProfile.flags)
        {
            myProfile.flags = flags;
            isModified = YES;
        }
        
        if (isModified)
            [myProfile update];
        
        if (_isImageModified)
        {
            Mugshot * myMugshot = [Mugshot mugshotForUser:CIX.username];
            [myMugshot setImage:mugshotImage.image];
            [myMugshot update];
        }
    }
    [self setEditState:!_isEditing];
}

/* Handle the notification when the mugshot image was modified.
 */
-(IBAction)handleImageWasModified:(id)sender
{
    NSImage * newImage = [[mugshotImage image] resize:NSMakeSize(100.0, 100.0)];
    [mugshotImage setImage:newImage];
    _isImageModified = YES;
}

/* Handle the Close button
 */
-(IBAction)handleCloseButton:(id)sender
{
    [self setEditState:!_isEditing];
    [NSApp stopModalWithCode:YES];
}
@end
