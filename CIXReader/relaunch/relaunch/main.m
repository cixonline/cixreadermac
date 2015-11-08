//
//  main.m
//  relaunch
//
//  Created by Steve Palmer on 04/12/2014.
//  Copyright (c) 2014 Steve Palmer. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#pragma mark Main method
int main(int argc, char *argv[])
{
    // wait a sec, to be safe
    sleep(1);
    
    NSString *appPath = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
    BOOL success = [[NSWorkspace sharedWorkspace] openFile:[appPath stringByExpandingTildeInPath]];
    
    if (!success)
        NSLog(@"Error: could not relaunch application at %@", appPath);
    
    return (success) ? 0 : 1;
}
