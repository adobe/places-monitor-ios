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

#import <ACPCore/ACPCore.h>
#import <ACPPlaces/ACPPlaces.h>
#import "ACPPlacesMonitorConstants.h"
#import "ACPPlacesMonitorInternal.h"
#import "ACPPlacesMonitorLocationDelegate.h"

@implementation ACPPlacesMonitorLocationDelegate

#pragma mark - location methods
- (void) locationManager: (CLLocationManager*) manager didUpdateLocations: (NSArray<CLLocation*>*) locations {
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"%s - location:%@", __PRETTY_FUNCTION__, [locations lastObject]]];
    [_parent postLocationUpdate:[locations lastObject]];
}

- (void) locationManager: (CLLocationManager*) manager didFailWithError: (NSError*) error {
    [ACPCore log:ACPMobileLogLevelWarning
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"%s - error:%@. Have you set values for NSLocationWhenInUseUsageDescription and NSLocationAlwaysAndWhenInUseUsageDescription in your Info.plist file?", __PRETTY_FUNCTION__, error]];

    // if we get this error, all location activity should end
    if (error.code == kCLErrorDenied) {
        [_parent stopAllMonitoring:YES];
        [ACPCore log:ACPMobileLogLevelDebug
                 tag:ACPPlacesMonitorExtensionName
             message:[NSString stringWithFormat:@"Places functionality has been suspended due to a monitoring failure: %@", error]];
    }
}

#pragma mark - region methods (beacons and geo fences)
#if GEOFENCES_SUPPORTED || BEACONS_SUPPORTED
- (void) locationManager: (CLLocationManager*) manager didEnterRegion: (CLRegion*) region {
    // make sure we're not already in this region before posting this entry event
    if ([_parent deviceIsWithinRegion:region]) {
        return;
    }

    // post the notification and add the region to our membership list
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"Entry event detected for region: %@", region]];
    [_parent postRegionUpdate:region withEventType:ACPRegionEventTypeEntry];
    [_parent addDeviceToRegion:region];

    // if this is a beacon region, we should begin ranging when we enter
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        if ([CLLocationManager isRangingAvailable]) {
            [ACPCore log:ACPMobileLogLevelDebug
                     tag:ACPPlacesMonitorExtensionName
                 message:[NSString stringWithFormat:@"Started ranging beacons in region: %@", region]];
            [manager startRangingBeaconsInRegion:(CLBeaconRegion*)region];
        }
    }
}

- (void) locationManager: (CLLocationManager*) manager didExitRegion: (CLRegion*) region {
    // only post an exit if we have an associated entry
    if (![_parent deviceIsWithinRegion:region]) {
        return;
    }

    // post the notification and remove the region from our membership list
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"Exit event detected for region: %@", region]];
    [_parent postRegionUpdate:region withEventType:ACPRegionEventTypeExit];
    [_parent removeDeviceFromRegion:region];

    // if this is a beacon region, we should stop ranging upon exit
    if ([region isKindOfClass:[CLBeaconRegion class]]) {
        if ([CLLocationManager isRangingAvailable]) {
            [ACPCore log:ACPMobileLogLevelDebug
                     tag:ACPPlacesMonitorExtensionName
                 message:[NSString stringWithFormat:@"Stopped ranging beacons in region: %@", region]];
            [manager stopRangingBeaconsInRegion:(CLBeaconRegion*)region];
        }
    }
}

- (void) locationManager: (CLLocationManager*) manager didDetermineState: (CLRegionState) state forRegion: (CLRegion*) region {
    [ACPCore log:ACPMobileLogLevelVerbose
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"%s - region:%@ - state:%ld", __PRETTY_FUNCTION__, region, (long)state]];
}

- (void) locationManager: (CLLocationManager*) manager monitoringDidFailForRegion: (CLRegion*) region withError: (NSError*) error {
    [ACPCore log:ACPMobileLogLevelWarning
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"%s - region:%@ - error:%@", __PRETTY_FUNCTION__, region, error]];
}

- (void) locationManager: (CLLocationManager*) manager didStartMonitoringForRegion: (CLRegion*) region {
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"Started monitoring region: %@", region]];
}
#endif

/*
 * BEACONS are not supported in V1 of Places.  Leaving this in for use later.
 */
#pragma mark - ranging methods (beacons)
#if BEACONS_SUPPORTED
- (void) locationManager: (CLLocationManager*) manager didRangeBeacons: (NSArray<CLBeacon*>*) beacons inRegion: (CLBeaconRegion*) region {
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"%s - region:%@ - beacons:%@", __PRETTY_FUNCTION__, region, beacons]];
}

- (void) locationManager: (CLLocationManager*) manager rangingBeaconsDidFailForRegion: (CLBeaconRegion*) region withError: (NSError*) error {
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"%s - region:%@ - error:%@", __PRETTY_FUNCTION__, region, error]];
}
#endif

#pragma mark - configuration delegate methods
- (void) locationManager: (CLLocationManager*) manager didChangeAuthorizationStatus: (CLAuthorizationStatus) status {
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"Authorization status changed: %@", [self authStatusString:status]]];
    
    // update the places shared state
    [ACPPlaces setAuthorizationStatus:status];
}

#pragma mark - other delegate methods
- (void) locationManagerDidPauseLocationUpdates: (CLLocationManager*) manager {
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:@"Location updates paused"];
}

- (void) locationManagerDidResumeLocationUpdates: (CLLocationManager*) manager {
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:@"Location updates resumed"];
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

@end
