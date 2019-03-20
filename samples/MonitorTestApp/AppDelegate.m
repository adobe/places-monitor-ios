//
//  AppDelegate.m
//  PlacesDemoApp
//
//  Created by steve benedick on 11/12/18.
//  Copyright © 2018 Adobe Inc. All rights reserved.
//

#import <UserNotifications/UserNotifications.h>
#import "AppDelegate.h"
#import "ACPCore.h"
#import "ACPLifecycle.h"
#import "ACPAnalytics.h"
#import "ACPIdentity.h"
#import "ACPPlaces.h"
#import "ACPPlacesMonitor.h"
#import "ACPSignal.h"
#import "ACPUserProfile.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    // local notification code
    UNUserNotificationCenter *center = [UNUserNotificationCenter currentNotificationCenter];
    [center requestAuthorizationWithOptions:(UNAuthorizationOptionBadge | UNAuthorizationOptionSound | UNAuthorizationOptionAlert)
                          completionHandler:^(BOOL granted, NSError * _Nullable error) {
                              if (!error) {
                                  NSLog(@"request authorization succeeded!");
                              }
                          }];
        
    // Override point for customization after application launch.
    [ACPCore setLogLevel:ACPMobileLogLevelError];
    
    
    // steve's app in benedick corp: launch-EN459260fc579a4dcbb2d1743947e65f09-development
//    [ACPCore configureWithAppId:@"launch-EN459260fc579a4dcbb2d1743947e65f09-development"];
    
    // steve's app in obumobile5: launch-EN06755a968baf4d0dac5159fe1584479f-development
    [ACPCore configureWithAppId:@"launch-EN06755a968baf4d0dac5159fe1584479f-development"];
    
    // qe test property with all the locations: staging/launch-EN692fc5a2033e40269994a786cf871bbb-development
//    [ACPCore configureWithAppId:@"staging/launch-EN692fc5a2033e40269994a786cf871bbb-development"];
    
    [ACPSignal registerExtension];
    [ACPLifecycle registerExtension];
    [ACPIdentity registerExtension];
    [ACPAnalytics registerExtension];
    [ACPUserProfile registerExtension];
    
    [ACPPlaces registerExtension];
    
    // expose logging for extensions so we don't have to use different settings
    [ACPPlacesMonitor setLoggingEnabled:YES];
    [ACPPlacesMonitor registerExtension];
    
    [ACPCore start:^{
        [ACPCore lifecycleStart:nil];
        
        [ACPPlacesMonitor start];
    }];
    
    return YES;
}

@end
