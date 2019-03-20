/*
 Copyright 2019 Adobe. All rights reserved.
 This file is licensed to you under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License. You may obtain a copy
 of the License at http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software distributed under
 the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR REPRESENTATIONS
 OF ANY KIND, either express or implied. See the License for the specific language
 governing permissions and limitations under the License.
 */

//
// ACPPlacesMonitorLocationDelegate.m
//

#import "ACPPlacesMonitorConstants.h"
#import "ACPPlacesMonitorInternal.h"
#import "ACPPlacesMonitorLocationDelegate.h"
#import "ACPPlacesMonitorLogger.h"
#import "ACPPlaces.h"
#import <UIKit/UIKit.h>

// TODO: remove this before going live!!!
#import <UserNotifications/UserNotifications.h>

@implementation ACPPlacesMonitorLocationDelegate

#pragma mark - location methods
- (void) locationManager: (CLLocationManager*) manager didUpdateLocations: (NSArray<CLLocation*>*) locations {

    // TODO: remove this before going live!!!
    [self sendMessageToSlack:[NSString stringWithFormat:@"locationManager:didUpdateLocations: %@", [locations lastObject]]];

    ACPPlacesMonitorLogDebug(@"%s - location:%@", __PRETTY_FUNCTION__, [locations lastObject]);
    [_parent postLocationUpdate:[locations lastObject]];
}

- (void) locationManager: (CLLocationManager*) manager didFailWithError: (NSError*) error {
    ACPPlacesMonitorLogDebug(@"%s - error:%@", __PRETTY_FUNCTION__, error);

    // if we get this error, all location activity should end
    if (error.code == kCLErrorDenied) {
        [_parent stopAllMonitoring];
        ACPPlacesMonitorLogDebug(@"Places functionality has been suspended due to a monitoring failure: %@", error);
    }
}

#pragma mark - region methods (beacons and geo fences)
#if GEOFENCES_SUPPORTED || BEACONS_SUPPORTED
- (void) locationManager: (CLLocationManager*) manager didEnterRegion: (CLRegion*) region {



    // TODO: remove this before going live!!!
    [self triggerLocalNotification:[NSString stringWithFormat:@"Entry event for region ID (%@)", region.identifier]];
    [self sendMessageToSlack:region forEvent:ACPRegionEventTypeEntry];




    // make sure we're not already in this region before posting this entry event
    if ([_parent deviceIsWithinRegion:region]) {
        return;
    }

    // post the notification and add the region to our membership list
    ACPPlacesMonitorLogDebug(@"Entry event detected for region: %@", region);
    [_parent postRegionUpdate:region withEventType:ACPRegionEventTypeEntry];
    [_parent addDeviceToRegion:region];

    // if this is a beacon region, we should begin ranging when we enter
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        if ([CLLocationManager isRangingAvailable]) {
            ACPPlacesMonitorLogDebug(@"Started ranging beacons in region: %@", region);
            [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
        }
    }
}

- (void) locationManager: (CLLocationManager*) manager didExitRegion: (CLRegion*) region {



    // TODO: remove this before going live!!!
    [self triggerLocalNotification:[NSString stringWithFormat:@"Exit event for region ID (%@)", region.identifier]];
    [self sendMessageToSlack:region forEvent:ACPRegionEventTypeExit];




    // only post an exit if we have an associated entry
    if (![_parent deviceIsWithinRegion:region]) {
        return;
    }

    // post the notification and remove the region from our membership list
    ACPPlacesMonitorLogDebug(@"Exit event detected for region: %@", region);
    [_parent postRegionUpdate:region withEventType:ACPRegionEventTypeExit];
    [_parent removeDeviceFromRegion:region];

    // if this is a beacon region, we should stop ranging upon exit
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        if ([CLLocationManager isRangingAvailable]) {
            ACPPlacesMonitorLogDebug(@"Stopped ranging beacons in region: %@", region);
            [manager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
        }
    }
}

- (void) locationManager: (CLLocationManager*) manager didDetermineState: (CLRegionState) state forRegion: (CLRegion*) region {
    ACPPlacesMonitorLogDebug(@"%s - region:%@ - state:%d", __PRETTY_FUNCTION__, region, state);
}

- (void) locationManager: (CLLocationManager*) manager monitoringDidFailForRegion: (CLRegion*) region withError: (NSError*) error {
    ACPPlacesMonitorLogDebug(@"%s - region:%@ - error:%@", __PRETTY_FUNCTION__, region, error);
}

- (void) locationManager: (CLLocationManager*) manager didStartMonitoringForRegion: (CLRegion*) region {
    ACPPlacesMonitorLogDebug(@"Started monitoring region: %@", region);
}
#endif

/*
 * BEACONS are not supported in V1 of Places.  Leaving this in for use later.
 */
#pragma mark - ranging methods (beacons)
#if BEACONS_SUPPORTED
- (void) locationManager: (CLLocationManager*) manager didRangeBeacons: (NSArray<CLBeacon*>*) beacons inRegion: (CLBeaconRegion*) region {
    ACPPlacesMonitorLogDebug(@"%s - region:%@ - beacons:%@", __PRETTY_FUNCTION__, region, beacons);
}

- (void) locationManager: (CLLocationManager*) manager rangingBeaconsDidFailForRegion: (CLBeaconRegion*) region withError: (NSError*) error {
    ACPPlacesMonitorLogDebug(@"%s - region:%@ - error:%@", __PRETTY_FUNCTION__, region, error);
}
#endif

#pragma mark - configuration delegate methods
- (void) locationManager: (CLLocationManager*) manager didChangeAuthorizationStatus: (CLAuthorizationStatus) status {
    ACPPlacesMonitorLogDebug(@"Authorization status changed: %@", [self authStatusString:status]);
}

#pragma mark - other delegate methods
- (void) locationManagerDidPauseLocationUpdates: (CLLocationManager*) manager {
    ACPPlacesMonitorLogDebug(@"Location updates paused");
}

- (void) locationManagerDidResumeLocationUpdates: (CLLocationManager*) manager {
    ACPPlacesMonitorLogDebug(@"Location updates resumed");
}

#pragma mark - private methods

- (NSString*) authStatusString: (CLAuthorizationStatus) status {
    switch (status) {
    case kCLAuthorizationStatusDenied:
        return @"Denied";
        break;

    case kCLAuthorizationStatusRestricted:
        return @"Restricted";
        break;

    case kCLAuthorizationStatusNotDetermined:
        return @"Not Determined";
        break;

    case kCLAuthorizationStatusAuthorizedAlways:
        return @"Always";
        break;

    case kCLAuthorizationStatusAuthorizedWhenInUse:
        return @"When in use";
        break;

    default:
        return @"Not Determined";
        break;
    }
}


// TODO: remove this before going live!!!
- (void) sendMessageToSlack: (NSString*) string {
    auto bgtask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:nil];

    NSURLSession* session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    NSString* jsonString = [NSString stringWithFormat:@"{\"text\":\"%@\"}", string];
    NSData* postData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];

    // steve's channel, please do not use
    //    NSMutableURLRequest* request = [[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://hooks.slack.com/services/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"]] mutableCopy];

    NSMutableURLRequest* request = [[NSURLRequest requestWithURL:[NSURL URLWithString:@"https://hooks.slack.com/services/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"]] mutableCopy];
    [request setHTTPMethod:@"POST"];
    [request setHTTPBody:postData];
    [request setValue:[NSString stringWithFormat:@"%lu", (unsigned long)postData.length] forHTTPHeaderField:@"Content-Length"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSURLSessionTask* task = [session dataTaskWithRequest:request];
    [task resume];

    [[UIApplication sharedApplication] endBackgroundTask:bgtask];
}

- (void) sendMessageToSlack: (CLRegion*) region forEvent: (ACPRegionEventType) event {
    NSString* message = [NSString stringWithFormat:@"raw '%@' event for region id '%@'",
      event == ACPRegionEventTypeEntry ? @"entry" : @"exit", region.identifier];

    [self sendMessageToSlack:message];
}

// TODO: remove this before going live!!!
- (void) triggerLocalNotification: (NSString*) message {
    UNMutableNotificationContent* objNotificationContent = [[UNMutableNotificationContent alloc] init];
    objNotificationContent.title = [NSString localizedUserNotificationStringForKey:@"Places Monitor Region Event" arguments:nil];
    objNotificationContent.body = [NSString localizedUserNotificationStringForKey:message arguments:nil];

    UNTimeIntervalNotificationTrigger* trigger =  [UNTimeIntervalNotificationTrigger triggerWithTimeInterval:1.f repeats:NO];

    UNNotificationRequest* request = [UNNotificationRequest requestWithIdentifier:@"acpplacesmonitor"
                                                                          content:objNotificationContent
                                                                          trigger:trigger];

    UNUserNotificationCenter* center = [UNUserNotificationCenter currentNotificationCenter];
    [center addNotificationRequest:request withCompletionHandler: ^ (NSError * _Nullable error) {
               if (!error) {
                   NSLog(@"Local Notification succeeded");
               } else {
                   NSLog(@"Local Notification failed");
        }
    }];
}

@end
