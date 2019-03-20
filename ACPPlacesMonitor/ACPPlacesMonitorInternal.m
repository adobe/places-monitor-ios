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
// ACPPlacesMonitorInternal.m
//

#import <CoreLocation/CoreLocation.h>
#import "ACPPlaces.h"
#import "ACPPlacesMonitor.h"
#import "ACPPlacesMonitorConstants.h"
#import "ACPPlacesMonitorInternal.h"
#import "ACPPlacesMonitorListener.h"
#import "ACPPlacesMonitorLocationDelegate.h"
#import "ACPPlacesMonitorLogger.h"
#import "ACPExtensionEvent.h"
#import "ACPPlacesQueue.h"

@interface ACPPlacesMonitorInternal()
@property(nonatomic, strong) ACPPlacesQueue* eventQueue;
@property(nonatomic, strong) ACPPlacesMonitorLocationDelegate* locationDelegate;
@property(nonatomic, strong) CLLocationManager* locationManager;
@property(nonatomic, strong) NSMutableArray<NSString*>* currentlyMonitoredRegions;
@property(nonatomic, strong) NSMutableArray<NSString*>* userWithinRegions;
@property(nonatomic) ACPPlacesMonitorMode monitorMode;
@end

@implementation ACPPlacesMonitorInternal

#pragma mark - ACPExtension methods
- (nullable NSString*) name {
    return ACPPlacesMonitorExtensionName;
}

- (NSString*) version {
    return ACPPlacesMonitorExtensionVersion;
}

- (instancetype) init {
    if (self = [super init]) {
        // register a listener for shared state changes
        NSError* error = nil;

        if ([self.api registerListener:[ACPPlacesMonitorListener class]
                             eventType:ACPPlacesMonitorEventTypeHub
                           eventSource:ACPPlacesMonitorEventSourceSharedState
                                 error:&error]) {
            ACPPlacesMonitorLogDebug(@"Listener successfully registered for Event Hub shared state events");
        } else {
            ACPPlacesMonitorLogError(@"There was an error registering for Event Hub shared state events: %@",
                                     error.localizedDescription ? : @"unknown");
        }

        if ([self.api registerListener:[ACPPlacesMonitorListener class]
                             eventType:ACPPlacesMonitorEventTypePlaces
                           eventSource:ACPPlacesMonitorEventSourceResponseContent
                                 error:&error]) {
            ACPPlacesMonitorLogDebug(@"Listener successfully registered for Places response events");
        } else {
            ACPPlacesMonitorLogError(@"There was an error registering for Places response events: %@",
                                     error.localizedDescription ? : @"unknown");
        }

        if ([self.api registerListener:[ACPPlacesMonitorListener class]
                             eventType:ACPPlacesMonitorEventTypeMonitor
                           eventSource:ACPPlacesMonitorEventSourceRequestContent
                                 error:&error]) {
            ACPPlacesMonitorLogDebug(@"Listener successfully registered for Places Monitor request events");
        } else {
            ACPPlacesMonitorLogError(@"There was an error registering for Places Monitor request events: %@",
                                     error.localizedDescription ? : @"unknown");
        }

        [self loadPersistedValues];

        self.eventQueue = [[ACPPlacesQueue alloc] init];

        // creating a CLLocationManager must happen on the main thread
        if ([NSThread isMainThread]) {
            self.locationManager = [[CLLocationManager alloc] init];
        } else {
            dispatch_sync(dispatch_get_main_queue(), ^ {
                self.locationManager = [[CLLocationManager alloc] init];
            });
        }

        self.locationDelegate = [[ACPPlacesMonitorLocationDelegate alloc] init];
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        self.locationManager.distanceFilter = 100;
        self.locationManager.delegate = self.locationDelegate;
        self.locationDelegate.parent = self;

        if ([self.locationManager respondsToSelector:@selector(setAllowsBackgroundLocationUpdates:)]) {
            self.locationManager.allowsBackgroundLocationUpdates = [self backgroundLocationUpdatesEnabledInBundle];
        }
    }

    return self;
}

- (void) onUnregister {
    [super onUnregister];

    // the extension was unregistered
    // if the shared states are not used in the next registration they can be cleared in this method
    [[self api] clearSharedEventStates:nil];
}

- (void) unexpectedError: (NSError*) error {
    [super unexpectedError:error];
}

#pragma mark - ACPPlacesMonitorInternal Public Methods
#pragma mark - Event Handling
- (void) queueEvent: (ACPExtensionEvent*) event {
    if (!event) {
        return;
    }

    [self.eventQueue add:event];
}

- (void) processEvents {
    while ([self.eventQueue hasNext]) {
        ACPExtensionEvent* eventToProcess = [self.eventQueue peek];

        NSError* error = nil;
        NSDictionary* configSharedState = [self.api getSharedEventState:ACPPlacesMonitorConfigurationSharedState
                                                                  event:eventToProcess
                                                                  error:&error];

        // NOTE: configuration is mandatory for processing the event, so if shared state is null stop processing events
        if (!configSharedState) {
            ACPPlacesMonitorLogDebug(@"Waiting to process event, configuration shared state is pending");
            return;
        }

        if (error != nil) {
            ACPPlacesMonitorLogWarning(@"Could not process event, an error occured while retrieving configuration shared state %ld",
                                       [error code]);
            return;
        }

        if ([eventToProcess.eventName isEqualToString:ACPPlacesMonitorEventNameStart]) {
            [self startMonitoring];
        } else if ([eventToProcess.eventName isEqualToString:ACPPlacesMonitorEventNameStop]) {
            [self stopAllMonitoring];
        } else if ([eventToProcess.eventName isEqualToString:ACPPlacesMonitorEventNameUpdateLocationNow]) {
            [self updateLocationNow];
        } else if ([eventToProcess.eventName isEqualToString:ACPPlacesMonitorEventNameUpdateMonitorConfiguration]) {
            NSNumber* modeNumber = [eventToProcess.eventData objectForKey:ACPPlacesMonitorEventDataMonitorMode];
            ACPPlacesMonitorMode newMode = modeNumber ? [modeNumber integerValue] : ACPPlacesMonitorModeSignificantChanges;
            [self setMonitorMode:newMode];
        }

        [self.eventQueue poll];
    }
}

#pragma mark - Location Settings and State
- (void) stopAllMonitoring {
#if CONTINUOUS_LOCATION_SUPPORTED
    [self stopMonitoringContinuousLocationChanges];
#endif

#if SIGNIFICANT_LOCATION_CHANGE_MONITORING_SUPPORTED
    [self stopMonitoringSignificantLocationChanges];
#endif

#if GEOFENCES_SUPPORTED
    [self stopMonitoringGeoFences];
#endif
}

- (void) startMonitoring {
    CLAuthorizationStatus auth = [CLLocationManager authorizationStatus];

    // if the user has denied location services, bail early
    if ([self userHasDeclinedLocationPermission:auth]) {
        ACPPlacesMonitorLogDebug(@"Permission to use location data has been denied by the user");
        return;
    }

    // if the user hasn't been asked yet, we need to ask for permission to use location
    if (auth == kCLAuthorizationStatusNotDetermined) {
        if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
            [_locationManager requestAlwaysAuthorization];
        }
    }

    [self beginTrackingLocation];
}

- (void) beginTrackingLocation {
#if CONTINUOUS_LOCATION_SUPPORTED

    if (_monitorMode & ACPPlacesMonitorModeContinuous) {
        [self startMonitoringContinuousLocationChanges];
    } else {
        [self stopMonitoringContinuousLocationChanges];
    }

#endif

#if SIGNIFICANT_LOCATION_CHANGE_MONITORING_SUPPORTED

    if (_monitorMode & ACPPlacesMonitorModeSignificantChanges) {
        [self startMonitoringSignificantLocationChanges];
    } else {
        [self stopMonitoringSignificantLocationChanges];
    }

#endif

    [self updateLocationNow];
}

- (void) addDeviceToRegion: (CLRegion*) region {
    [_userWithinRegions addObject:region.identifier];
    [self updateUserWithinRegionsInPersistence];
}

- (void) removeDeviceFromRegion: (CLRegion*) region {
    [_userWithinRegions removeObject:region.identifier];
    [self updateUserWithinRegionsInPersistence];
}

- (void) updateUserWithinRegionsInPersistence {
    if (_userWithinRegions.count) {
        [[NSUserDefaults standardUserDefaults] setObject:_userWithinRegions
                                                  forKey:ACPPlacesMonitorDefaultsUserWithinRegions];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACPPlacesMonitorDefaultsUserWithinRegions];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void) updateCurrentlyMonitoredRegionsInPersistence {
    if (_currentlyMonitoredRegions.count) {
        [[NSUserDefaults standardUserDefaults] setObject:_currentlyMonitoredRegions
                                                  forKey:ACPPlacesMonitorDefaultsMonitoredRegions];
    } else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACPPlacesMonitorDefaultsMonitoredRegions];
    }

    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) deviceIsWithinRegion: (CLRegion*) region {
    return [_userWithinRegions containsObject:region.identifier];
}

#pragma mark - Location Updates
- (void) postLocationUpdate: (CLLocation*) currentLocation {
    [ACPPlaces getNearbyPointsOfInterest:currentLocation
                                   limit:ACPPlacesMonitorDefaultMaxMonitoredRegionCount
                                callback: ^ (NSArray<ACPPlacesPoi*>* _Nullable nearbyPoi) {

        [self resetMonitoredGeofences];

        if (nearbyPoi.count) {
            ACPPlacesMonitorLogDebug(@"Received a new list of POIs from Places: %@", nearbyPoi);
            [self startMonitoringGeoFences:nearbyPoi];
        } else {
            ACPPlacesMonitorLogDebug(@"Response from Places indicates there are no nearby POIs currently");
        }

        [self removeNonMonitoredRegionsFromUserWithinRegions];
    }];
}

- (void) updateLocationNow {
    [_locationManager requestLocation];
}

- (void) postRegionUpdate: (CLRegion*) region withEventType: (ACPRegionEventType) type {
    [ACPPlaces processRegionEvent:region forRegionEventType:type];
}

#pragma mark - ACPPlacesMonitorInternal Private Methods
- (void) loadPersistedValues {
    NSNumber* monitorMode = [[NSUserDefaults standardUserDefaults] objectForKey:ACPPlacesMonitorDefaultsMonitorMode];
    self.monitorMode = monitorMode ? [monitorMode longValue] : ACPPlacesMonitorModeSignificantChanges;

    NSArray* persistedRegions = [[NSUserDefaults standardUserDefaults]
                                 arrayForKey:ACPPlacesMonitorDefaultsMonitoredRegions];
    self.currentlyMonitoredRegions = persistedRegions.count ? [persistedRegions mutableCopy] : [@[] mutableCopy];

    NSArray* persistedUserWithinRegions = [[NSUserDefaults standardUserDefaults]
                                           arrayForKey:ACPPlacesMonitorDefaultsUserWithinRegions];
    self.userWithinRegions = persistedUserWithinRegions.count ?
                             [persistedUserWithinRegions mutableCopy] : [@[] mutableCopy];
}

- (void) resetMonitoredGeofences {
    // remove regions in locationManager.moniteredRegions that we have initialized
    // NOTE - the process of verifying that each region is one we are monitoring is important
    // so we don't stop monitoring a region used elsewhere in the app
    NSArray* regions = [_locationManager.monitoredRegions copy];

    for (CLRegion * region in regions) {
        if ([region isKindOfClass:[CLCircularRegion class]] && [_currentlyMonitoredRegions containsObject:region.identifier]) {
            [_locationManager stopMonitoringForRegion:region];
        }
    }

    // clear out our list
    [_currentlyMonitoredRegions removeAllObjects];
    [self updateCurrentlyMonitoredRegionsInPersistence];
}

- (void) setMonitorMode: (ACPPlacesMonitorMode) monitorMode {
    _monitorMode = monitorMode;
    [[NSUserDefaults standardUserDefaults] setInteger:monitorMode forKey:ACPPlacesMonitorDefaultsMonitorMode];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // a call to refresh how we are monitoring based on the new mode
    [self beginTrackingLocation];
}

- (void) startMonitoringGeoFences: (NSArray*) newGeoFences {
    if ([self userHasDeclinedLocationPermission:[CLLocationManager authorizationStatus]]) {
        return;
    }

    // make sure the device support monitoring geofences
    if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        ACPPlacesMonitorLogDebug(@"This device's GPS capabilities do not support monitoring geofence regions");
        return;
    }

    // loop through our regions while we have them AND we are under our max number of regions
    for (ACPPlacesPoi * currentRegion in newGeoFences) {
        // update the radius for the region if necessary
        if (_locationManager.maximumRegionMonitoringDistance < currentRegion.radius) {
            currentRegion.radius = _locationManager.maximumRegionMonitoringDistance;
        }

        // make the circular region
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(currentRegion.latitude, currentRegion.longitude);
        CLCircularRegion* currentCLRegion = [[CLCircularRegion alloc] initWithCenter:center
                                                                              radius:currentRegion.radius
                                                                          identifier:currentRegion.identifier];
        currentCLRegion.notifyOnExit = YES;
        currentCLRegion.notifyOnEntry = YES;

        // start monitoring the new region
        [_locationManager startMonitoringForRegion:currentCLRegion];

        // add the region to our list of monitored regions
        [_currentlyMonitoredRegions addObject:currentCLRegion.identifier];

        // send an entry event if we had one and we know the user was not already in the region
        if (currentRegion.userIsWithin && ![_userWithinRegions containsObject:currentRegion.identifier]) {
            [self addDeviceToRegion:currentCLRegion];
            [ACPPlaces processRegionEvent:currentCLRegion forRegionEventType:ACPRegionEventTypeEntry];
        }
    }

    [self updateCurrentlyMonitoredRegionsInPersistence];
}

- (void) stopMonitoringGeoFences {
    // remove regions in locationManager.moniteredRegions that we have initialized
    NSArray* regions = [_locationManager.monitoredRegions copy];

    for (CLRegion * region in regions) {
        if ([region isKindOfClass:[CLCircularRegion class]] && [_currentlyMonitoredRegions containsObject:region.identifier]) {
            [_locationManager stopMonitoringForRegion:region];
        }
    }
}

- (void) removeNonMonitoredRegionsFromUserWithinRegions {
    // remove all regions from our _userWithinRegions array if they are no longer in our _currentlyMonitoredRegions
    NSArray* userWithinRegionsCopy = [_userWithinRegions copy];

    for (NSString * regionId in userWithinRegionsCopy) {
        if (![_currentlyMonitoredRegions containsObject:regionId]) {
            [_userWithinRegions removeObject:regionId];
        }
    }

    [self updateUserWithinRegionsInPersistence];
}

#if SIGNIFICANT_LOCATION_CHANGE_MONITORING_SUPPORTED
- (void) startMonitoringSignificantLocationChanges {
    if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
        [_locationManager startMonitoringSignificantLocationChanges];
        ACPPlacesMonitorLogDebug(@"Significant location collection is enabled");
    }
}

- (void) stopMonitoringSignificantLocationChanges {
    if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
        [_locationManager stopMonitoringSignificantLocationChanges];
        ACPPlacesMonitorLogDebug(@"Significant location collection is disabled");
    }
}
#endif

#if CONTINUOUS_LOCATION_SUPPORTED
- (void) startMonitoringContinuousLocationChanges {
    if ([self userHasDeclinedLocationPermission:[CLLocationManager authorizationStatus]]) {
        return;
    }

    // this method is available on iOS and starting with watchOS3
    if ([_locationManager respondsToSelector:@selector(startUpdatingLocation)]) {
        [_locationManager startUpdatingLocation];
        ACPPlacesMonitorLogDebug(@"Continuous location collection is enabled");
    }
}

- (void) stopMonitoringContinuousLocationChanges {
    [_locationManager stopUpdatingLocation];
    ACPPlacesMonitorLogDebug(@"Continuous location collection is disabled");
}
#endif

- (BOOL) userHasDeclinedLocationPermission: (CLAuthorizationStatus) status {
    return status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied;
}

- (BOOL) backgroundLocationUpdatesEnabledInBundle {
    NSArray* backgroundModes = [NSBundle mainBundle].infoDictionary[@"UIBackgroundModes"];
    return [backgroundModes containsObject:@"location"];
}

@end
