//
//  DateExtensions.m
//  CIXExtensions
//
//  Created by Steve Palmer on 15/11/2014.
//  Copyright (c) 2014-2015 CIXOnline Ltd. All rights reserved.
//

#import "DateExtensions.h"

@implementation NSDate (DateExtensions)

/* Return a default date value.
 */
+(NSDate *)defaultDate
{
    return [NSDate dateWithTimeIntervalSince1970:0];
}

/* Returns the current date adjusted for the timezone. This is actually not a great way to
 * handle NSDate which is supposed to be timezone agnostic though.
 */
+(NSDate *)localDate
{
    return [[NSDate date] toLocalDate];
}

/* Return this date adjusted to local time.
 */
-(NSDate *)toLocalDate
{
    NSTimeZone *tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = [tz secondsFromGMTForDate:self];
    return [NSDate dateWithTimeInterval: seconds sinceDate:self];
}

/* Return this date adjusted to UTC
 */
-(NSDate *)fromLocalDate
{
    NSTimeZone * tz = [NSTimeZone defaultTimeZone];
    NSInteger seconds = -[tz secondsFromGMTForDate: self];
    return [NSDate dateWithTimeInterval: seconds sinceDate:self];
}

/* Convert this date from GMT/BST to UTC
 */
-(NSDate *)GMTBSTtoUTC
{
    NSTimeZone * gmtTimeZone = [NSTimeZone timeZoneWithName:@"Europe/London"];
    if ([gmtTimeZone isDaylightSavingTimeForDate:self])
    {
        NSInteger seconds = -[gmtTimeZone secondsFromGMTForDate: self];
        return [NSDate dateWithTimeInterval:seconds sinceDate:self];
    }
    return self;
}

/* Convert this date from UTC to GMT/BST
 */
-(NSDate *)UTCtoGMTBST
{
    NSDate * theDate = self;
    NSTimeZone * gmtTimeZone = [NSTimeZone timeZoneWithName:@"Europe/London"];
    if ([gmtTimeZone isDaylightSavingTimeForDate:theDate])
    {
        NSInteger seconds = [gmtTimeZone secondsFromGMTForDate:theDate];
        theDate = [theDate dateByAddingTimeInterval:seconds];
    }
    return theDate;
}

/* friendlyDescription
 * Return a calendar date format string in a friendly format as follows:
 *
 * If the date is today, we show "Today".
 * If the date was yesterday, we show "Yesterday".
 * If the date is tomorrow, we show "Tomorrow".
 * And in all cases, we show a short time format HH:MM am/pm
 *
 * Why not use the Cocoa date formatters for this? Simple. None of them return the
 * format we need. Sigh.
 */
-(NSString *)friendlyDescription
{
    NSString * theDate;
    NSString * theTime;
        
    NSCalendar * usersCalendar = [[NSLocale currentLocale] objectForKey:NSLocaleCalendar];
    NSInteger differenceInDays = [usersCalendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:[NSDate date]] -
                            [usersCalendar ordinalityOfUnit:NSDayCalendarUnit inUnit:NSEraCalendarUnit forDate:self];
    
    if (differenceInDays == 0)
        theDate = NSLocalizedString(@"Today", nil);
    else if (differenceInDays == 1)
        theDate = NSLocalizedString(@"Yesterday", nil);
    else if (differenceInDays == -1)
        theDate = NSLocalizedString(@"Tomorrow", nil);
    else
        theDate = [NSDateFormatter localizedStringFromDate:self dateStyle:NSDateFormatterShortStyle timeStyle:NSDateFormatterNoStyle];
    
    NSDateComponents * selfComponents = [usersCalendar components:NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit fromDate:self];
    if (selfComponents.hour == 12 && selfComponents.minute == 0)
        theTime = NSLocalizedString(@"Noon", nil);
    else if (selfComponents.hour == 0 && selfComponents.minute == 0)
        theTime = NSLocalizedString(@"Midnight", nil);
    else
    {
        NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
        
        //[formatter setTimeZone:[NSTimeZone timeZoneWithName:@"UTC"]];
        [formatter setTimeStyle:NSDateFormatterShortStyle];
        theTime = [formatter stringFromDate:self];
    }
    return [NSString stringWithFormat:NSLocalizedString(@"%@ at %@", nil), theDate, theTime];
}
@end
