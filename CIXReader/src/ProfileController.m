//
//  ProfileController.m
//  CIXReader
//
//  Created by Steve Palmer on 25/09/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "ProfileController.h"
#import "StringExtensions.h"
#import "WindowCollection.h"
#import "DateExtensions.h"
#import "MapKit/MKMapItem.h"
#import "CIX.h"

@implementation ProfileController

/* Initialise with the specified profile.
 */
-(id)initWithProfile:(Profile *)profile
{
    if ((self = [super initWithWindowNibName:@"ProfileCard"]) != nil)
        _currentProfile = profile;
    return self;
}

/* Display the profile card. As part of displaying
 * the card we also trigger a refresh to update it.
 */
-(void)awakeFromNib
{
    if (_currentProfile != nil)
    {
        Mugshot * mugshot = [Mugshot mugshotForUser:_currentProfile.username];
        
        [mugshotImage setCircleDiameter:70];

        [self refreshMugshot:mugshot];
        [self refreshAccount:_currentProfile];
        
        // Add this to the window collection to ensure that a reference is
        // maintained.
        [[WindowCollection defaultCollection] add:self];
        
        // Trigger refresh
        NSNotificationCenter * nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(userAccountChanged:) name:MAUserProfileChanged object:nil];
        [nc addObserver:self selector:@selector(userMugshotChanged:) name:MAUserMugshotChanged object:nil];
        
        [_currentProfile refresh];
        [mugshot refresh];
    }
}

/* When the window is about to close, remove ourselves from the
 * collection.
 */
-(void)windowWillClose:(NSNotification *)notification
{
    [[WindowCollection defaultCollection] remove:self];
}

/* Called when a user's profile is changed. If it is the one
 * for this user, we update the profile details on the card.
 */
-(void)userAccountChanged:(NSNotification *)notification
{
    Response * response = (Response *)notification.object;
    if (response.errorCode == CCResponse_NoError)
    {
        Profile * profile = response.object;
        if ([profile.username isEqualToString:_currentProfile.username])
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
        if ([mugshot.username isEqualToString:_currentProfile.username])
            [mugshotImage setImage:mugshot.image];
    }
}

/* Common logic to fill out the profile.
 */
-(void)refreshAccount:(Profile *)profile
{
    [username setStringValue:SafeString(profile.username)];
    [emailAddress setStringValue:SafeString(profile.eMailAddress)];
    [lastOn setStringValue:SafeString([profile.lastOn friendlyDescription])];
    [firstOn setStringValue:SafeString([profile.firstOn friendlyDescription])];
    [lastPost setStringValue:SafeString([profile.lastPost friendlyDescription])];
    [about setString:SafeString(profile.about)];
    [location setStringValue:SafeString(profile.location)];
    [fullname setStringValue:SafeString(profile.fullname)];
    
    // Hide location button if no location
    [locationButton setHidden:IsEmpty(profile.location)];
    [mailButton setHidden:IsEmpty(profile.eMailAddress)];
}

/* Common logic to update the mugshot.
 */
-(void)refreshMugshot:(Mugshot *)mugshot
{
    [mugshotImage setImage:mugshot.image];
}

/* Called when the user clicks on the mail icon. Launch the system
 * mail program.
 */
-(IBAction)launchMail:(id)sender
{
    NSString * address = [NSString stringWithFormat:@"mailto:%@", _currentProfile.eMailAddress];
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:address]];
}

/* Called when the user clicks on the location icon. We use this to fire up the
 * Maps application to show the location. Later we could display this in a private
 * view within CIXReader.
 */
-(IBAction)launchLocation:(id)sender
{
    if (_currentProfile.location != nil)
    {
        CLGeocoder *geocoder = [[CLGeocoder alloc] init];
        [geocoder geocodeAddressString:_currentProfile.location
                     completionHandler:^(NSArray *placemarks, NSError *error) {
                         if (error == nil && placemarks.count > 0)
                         {
                             CLPlacemark *geocodedPlacemark = placemarks[0];
                             MKPlacemark *placemark = [[MKPlacemark alloc]
                                                       initWithCoordinate:geocodedPlacemark.location.coordinate
                                                       addressDictionary:geocodedPlacemark.addressDictionary];
                             
                             // Create a map item for the geocoded address to pass to Maps app
                             MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
                             [mapItem setName:geocodedPlacemark.name];
                             
                             // Set the directions mode to "Driving"
                             // Can use MKLaunchOptionsDirectionsModeWalking instead
                             NSDictionary *launchOptions = @{MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving};
                             
                             // Get the "Current User Location" MKMapItem
                             MKMapItem *currentLocationMapItem = [MKMapItem mapItemForCurrentLocation];
                             
                             // Pass the current location and destination map items to the Maps app
                             // Set the direction mode in the launchOptions dictionary
                             [MKMapItem openMapsWithItems:@[currentLocationMapItem, mapItem] launchOptions:launchOptions];
                         }
                     }];
    }
}
@end
