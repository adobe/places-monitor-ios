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
#import "ACPCore.h"
#import "ACPExtensionEvent.h"
#import "ACPPlaces.h"
#import "ACPPlacesMonitor.h"
#import "ACPPlacesMonitorConstants.h"
#import "ACPPlacesMonitorInternal.h"
#import "ACPPlacesMonitorListener.h"
#import "ACPPlacesMonitorLocationDelegate.h"
#import "ACPPlacesQueue.h"

#pragma mark - ACPPlacesMonitorInternal private properties

@interface ACPPlacesMonitorInternal()
@property(nonatomic, strong) ACPPlacesQueue* eventQueue;
@property(nonatomic, strong) ACPPlacesMonitorLocationDelegate* locationDelegate;
@property(nonatomic, strong) CLLocationManager* locationManager;
@property(nonatomic, strong) NSMutableArray<NSString*>* currentlyMonitoredRegions;
@property(nonatomic, strong) NSMutableArray<NSString*>* userWithinRegions;
@property(nonatomic) ACPPlacesMonitorMode monitorMode;
@property(nonatomic) ACPPlacesMonitorRequestAuthorizationLevel requestAuthorizationLevel;
@property(nonatomic) bool isMonitoringStarted;
@end

@implementation ACPPlacesMonitorInternal

#pragma mark - ACPExtension methods
/**
 * @brief Returns the name of the extension
 *
 * @return NSString containing the name of the ACPExtension
 */
- (nullable NSString*) name {
    return ACPPlacesMonitorExtensionName;
}

/**
 * @brief Returns the version of the extension
 *
 * @return NSString containing the version of the ACPExtension
 */
- (NSString*) version {
    return ACPPlacesMonitorExtensionVersion;
}

/**
 * @brief Initializes the ACPPlacesMonitorInternal object
 *
 * @discussion The init method is called by the AEP SDK as part of the extension registration process. This method
 * performs the following tasks:
 *   - Registers listeners for various events
 *   - Loads data from persistence
 *   - Initializes all class properties
 *   - Assigns its locationDelegate property as a delegate to the shared CLLocationManager
 *
 * @return A new instance of ACPPlacesMonitorInternal
 */
- (instancetype) init {
    if (self = [super init]) {
        // register a listener for shared state changes
        NSError* error = nil;

        if ([self.api registerListener:[ACPPlacesMonitorListener class]
                             eventType:ACPPlacesMonitorEventTypeHub
                           eventSource:ACPPlacesMonitorEventSourceSharedState
                                 error:&error]) {
            [ACPCore log:ACPMobileLogLevelVerbose
                     tag:ACPPlacesMonitorExtensionName
                 message:@"Listener successfully registered for Event Hub shared state events"];
        } else {
            [ACPCore log:ACPMobileLogLevelError
                     tag:ACPPlacesMonitorExtensionName
                 message:[NSString stringWithFormat:@"There was an error registering for Event Hub shared state events: %@",
             error.localizedDescription ? : @"unknown"]];
        }

        if ([self.api registerListener:[ACPPlacesMonitorListener class]
                             eventType:ACPPlacesMonitorEventTypePlaces
                           eventSource:ACPPlacesMonitorEventSourceResponseContent
                                 error:&error]) {
            [ACPCore log:ACPMobileLogLevelVerbose
                     tag:ACPPlacesMonitorExtensionName
                 message:@"Listener successfully registered for Places response events"];
        } else {
            [ACPCore log:ACPMobileLogLevelError
                     tag:ACPPlacesMonitorExtensionName
                 message:[NSString stringWithFormat:@"There was an error registering for Places response events: %@",
             error.localizedDescription ? : @"unknown"]];
        }

        if ([self.api registerListener:[ACPPlacesMonitorListener class]
                             eventType:ACPPlacesMonitorEventTypeMonitor
                           eventSource:ACPPlacesMonitorEventSourceRequestContent
                                 error:&error]) {
            [ACPCore log:ACPMobileLogLevelVerbose
                     tag:ACPPlacesMonitorExtensionName
                 message:@"Listener successfully registered for Places Monitor request events"];
        } else {
            [ACPCore log:ACPMobileLogLevelError
                     tag:ACPPlacesMonitorExtensionName
                 message:[NSString stringWithFormat:@"There was an error registering for Places Monitor request events: %@",
             error.localizedDescription ? : @"unknown"]];
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
        } else {
            [ACPCore log:ACPMobileLogLevelDebug
                     tag:ACPPlacesMonitorExtensionName
                 message:@"Background location updates are not enabled for this app. If you are doing background region monitoring, you must enable this capability."];
        }
    }

    return self;
}

/**
 * @brief Called when the extension is unregistered with the AEP SDK's EventHub
 */
- (void) onUnregister {
    [super onUnregister];

    // the extension was unregistered
    // if the shared states are not used in the next registration they can be cleared in this method
    [[self api] clearSharedEventStates:nil];
}

/**
 * @brief Called by the AEP SDK in the event of an unexpected error
 *
 * @param error The NSError object containing information about the unexpected error
 */
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
        NSDictionary* configSharedState = [[self api] getSharedEventState:ACPPlacesMonitorConfigurationSharedState
                                                                  event:eventToProcess
                                                                  error:&error];

        // NOTE: configuration is mandatory for processing the event, so if shared state is null stop processing events
        if (!configSharedState.count) {
            [ACPCore log:ACPMobileLogLevelDebug
                     tag:ACPPlacesMonitorExtensionName
                 message:@"Waiting to process event, configuration shared state is pending"];
            return;
        }

        if (error != nil) {
            [ACPCore log:ACPMobileLogLevelWarning
                     tag:ACPPlacesMonitorExtensionName
                 message:[NSString stringWithFormat:@"Could not process event, an error occured while retrieving configuration shared state %ld",
                          (long)[error code]]];
            return;
        }

        if ([eventToProcess.eventName isEqualToString:ACPPlacesMonitorEventNameStart]) {
            [self startMonitoring];
        } else if ([eventToProcess.eventName isEqualToString:ACPPlacesMonitorEventNameStop]) {
            bool clearData = [[eventToProcess.eventData objectForKey:ACPPlacesMonitorEventDataClear] boolValue] ?: NO;
            [self stopAllMonitoring:clearData];
        } else if ([eventToProcess.eventName isEqualToString:ACPPlacesMonitorEventNameUpdateLocationNow]) {
            [self updateLocationNow];
        } else if ([eventToProcess.eventName isEqualToString:ACPPlacesMonitorEventNameUpdateMonitorConfiguration]) {
            NSNumber* modeNumber = [eventToProcess.eventData objectForKey:ACPPlacesMonitorEventDataMonitorMode];
            ACPPlacesMonitorMode newMode = modeNumber ? [modeNumber integerValue] : ACPPlacesMonitorModeSignificantChanges;
            [self updateMonitorMode:newMode];
        } else if ([eventToProcess.eventName isEqualToString:ACPPlacesMonitorEventNameSetRequestAuthorizationLevel]) {
            NSNumber* requestAuthNumber = [eventToProcess.eventData objectForKey:ACPPlacesMonitorEventDataRequestAuthorizationLevel];
            ACPPlacesMonitorRequestAuthorizationLevel newRequestAuthorizationLevel = requestAuthNumber ? [requestAuthNumber integerValue] : ACPPlacesRequestMonitorAuthorizationLevelAlways;
            [self updateRequestAuthorizationLevel:newRequestAuthorizationLevel];
        }

        [self.eventQueue poll];
    }
}

#pragma mark - Location Settings and State
- (void) stopAllMonitoring: (BOOL) clearData {
    [ACPCore log:ACPMobileLogLevelVerbose
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"Stopping all monitoring. Client-side data will %@be purged",
                  clearData ? @"" : @"not "]];
    
    if (clearData) {
        [ACPPlaces clear];
        [self clearMonitorData];
    }
    
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
                                        [ACPCore log:ACPMobileLogLevelDebug
                                                 tag:ACPPlacesMonitorExtensionName
                                             message:[NSString stringWithFormat:@"Received a new list of POIs from Places: %@", nearbyPoi]];
                                        [self startMonitoringGeoFences:nearbyPoi];
                                    } else {
                                        [ACPCore log:ACPMobileLogLevelDebug
                                                 tag:ACPPlacesMonitorExtensionName
                                             message:@"There are no POIs near the device location."];
                                    }
                                    
                                    [self removeNonMonitoredRegionsFromUserWithinRegions];
                                } errorCallback:^(ACPPlacesRequestError result) {
                                    [self handlePlacesRequestError:result];
                                }];
}

- (void) handlePlacesRequestError:(ACPPlacesRequestError) error {
    if (error == ACPPlacesRequestErrorNone) {
        return;
    }
    
    NSString *message = @"An error occurred while attempting to retrieve nearby points of interest: %@";
    NSString *errorString = nil;
    switch (error) {
        case ACPPlacesRequestErrorConfigurationError:
            errorString = @"Missing Places configuration.";
            [self stopAllMonitoring:YES];
            break;
        case ACPPlacesRequestErrorConnectivityError:
            errorString = @"No network connectivity.";
            break;
        case ACPPlacesRequestErrorInvalidLatLongError:
            errorString = @"An invalid latitude and/or longitude was provided.  Valid values are -90 to 90 (lat) and -180 to 180 (lon).";
            break;
        case ACPPlacesRequestErrorQueryServiceUnavailable:
            errorString = @"The Places Query Service is unavailable. Try again later.";
            break;
        case ACPPlacesRequestErrorServerResponseError:
            errorString = @"There is an error in the response from the server.";
            break;
        case ACPPlacesRequestErrorUnknownError:
        default:
            errorString = @"Unknown error.";
            break;
    }
    
    [ACPCore log:ACPMobileLogLevelWarning
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:message, errorString]];
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
    
    self.isMonitoringStarted = false;
    if([[[[NSUserDefaults standardUserDefaults] dictionaryRepresentation] allKeys] containsObject:ACPPlacesMonitorDefaultsIsMonitoringStarted]){
        self.isMonitoringStarted = [[NSUserDefaults standardUserDefaults] boolForKey:ACPPlacesMonitorDefaultsIsMonitoringStarted];
    }
    
    NSNumber* requestAuthorizationLevel = [[NSUserDefaults standardUserDefaults] objectForKey:ACPPlacesMonitorDefaultsRequestAuthorizationLevel];
    self.requestAuthorizationLevel = requestAuthorizationLevel ? [requestAuthorizationLevel longValue] : ACPPlacesRequestMonitorAuthorizationLevelAlways;
    
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

- (void) updateMonitorMode: (ACPPlacesMonitorMode) monitorMode {
    _monitorMode = monitorMode;
    [[NSUserDefaults standardUserDefaults] setInteger:monitorMode forKey:ACPPlacesMonitorDefaultsMonitorMode];
    [[NSUserDefaults standardUserDefaults] synchronize];

    // a call to refresh how we are monitoring based on the new mode
    [self beginTrackingLocation];
}


- (void) updateRequestAuthorizationLevel: (ACPPlacesMonitorRequestAuthorizationLevel) requestAuthorizationLevel {
    _requestAuthorizationLevel = requestAuthorizationLevel;
    [[NSUserDefaults standardUserDefaults] setInteger:requestAuthorizationLevel forKey:ACPPlacesMonitorDefaultsRequestAuthorizationLevel];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // enchance the authorization level if the monitoring has already started
    if (_isMonitoringStarted) {
        [self startMonitoring];
    }
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
    [self persistMonitoringStatus];
    [self updateLocationNow];
}

- (void) startMonitoring {
    CLAuthorizationStatus auth = [CLLocationManager authorizationStatus];
    
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:@"Permission to use location data has been denied by the user"];
    
    // if the user has denied location services, bail out early
    if ([self userHasDeclinedLocationPermission:auth]) {
        [ACPCore log:ACPMobileLogLevelDebug
                 tag:ACPPlacesMonitorExtensionName
             message:@"Unable to start monitoring. Permission to use location data has been denied by the user"];
        return;
    }
    
    // for Request Authorization "whenInUse"
    if(_requestAuthorizationLevel == ACPPlacesMonitorRequestAuthorizationLevelWhenInUse) {
        // Ask for "whenInUse" location permission, only if the user hasn't been asked for location permission yet.
        if (auth == kCLAuthorizationStatusNotDetermined) {
            // attempt to request whenInUse authorization
            if ([_locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)]) {
                [_locationManager requestWhenInUseAuthorization];
            }
        }
    }
    
    // for Request Authorization "Always"
    if(_requestAuthorizationLevel == ACPPlacesRequestMonitorAuthorizationLevelAlways) {        
        // Ask for "always" location permission, only if the user hasn't been asked for location permission yet or has accepted "WhenInUse" authorization
        if (auth == kCLAuthorizationStatusNotDetermined || auth == kCLAuthorizationStatusAuthorizedWhenInUse) {
             // attempt to request always authorization
            if ([_locationManager respondsToSelector:@selector(requestAlwaysAuthorization)]) {
                [_locationManager requestAlwaysAuthorization];
            }
        }
    }
    
    [self beginTrackingLocation];
}

- (void) startMonitoringGeoFences: (NSArray*) newGeoFences {
    if ([self userHasDeclinedLocationPermission:[CLLocationManager authorizationStatus]]) {
        return;
    }

    // make sure the device support monitoring geofences
    if (![CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]) {
        [ACPCore log:ACPMobileLogLevelDebug
                 tag:ACPPlacesMonitorExtensionName
             message:@"This device's GPS capabilities do not support monitoring geofence regions"];
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
        if (currentRegion.userIsWithin) {
            if ([_userWithinRegions containsObject:currentRegion.identifier]) {
                [ACPCore log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName
                     message:[NSString stringWithFormat:@"Suppressing an entry event for region %@, the device is already known to be in this region", currentRegion.identifier]];
            } else {
                [self addDeviceToRegion:currentCLRegion];
                [ACPPlaces processRegionEvent:currentCLRegion forRegionEventType:ACPRegionEventTypeEntry];
            }
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
        _isMonitoringStarted = true;
        [_locationManager startMonitoringSignificantLocationChanges];
        [ACPCore log:ACPMobileLogLevelDebug
                 tag:ACPPlacesMonitorExtensionName
             message:@"Significant location collection is enabled"];
    }
}

- (void) stopMonitoringSignificantLocationChanges {
    if ([CLLocationManager significantLocationChangeMonitoringAvailable]) {
        _isMonitoringStarted = false;
        [_locationManager stopMonitoringSignificantLocationChanges];
        [ACPCore log:ACPMobileLogLevelDebug
                 tag:ACPPlacesMonitorExtensionName
             message:@"Significant location collection is disabled"];
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
        _isMonitoringStarted = true;
        [ACPCore log:ACPMobileLogLevelDebug
                 tag:ACPPlacesMonitorExtensionName
             message:@"Continuous location collection is enabled"];
    }
}

- (void) stopMonitoringContinuousLocationChanges {
    [_locationManager stopUpdatingLocation];
    _isMonitoringStarted = false;
    [ACPCore log:ACPMobileLogLevelDebug
             tag:ACPPlacesMonitorExtensionName
         message:@"Continuous location collection is disabled"];
}
#endif

/**
 * @brief Removes all objects from currently monitored regions and user within regions, also clears them from persistence.
 */
- (void) clearMonitorData {
    [_currentlyMonitoredRegions removeAllObjects];
    [self updateCurrentlyMonitoredRegionsInPersistence];
    
    [_userWithinRegions removeAllObjects];
    [self updateUserWithinRegionsInPersistence];
}

- (void) persistMonitoringStatus {
    [[NSUserDefaults standardUserDefaults] setBool:_isMonitoringStarted forKey:ACPPlacesMonitorDefaultsIsMonitoringStarted];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL) userHasDeclinedLocationPermission: (CLAuthorizationStatus) status {
    return status == kCLAuthorizationStatusRestricted || status == kCLAuthorizationStatusDenied;
}

- (BOOL) backgroundLocationUpdatesEnabledInBundle {
    NSArray* backgroundModes = [NSBundle mainBundle].infoDictionary[@"UIBackgroundModes"];
    return [backgroundModes containsObject:@"location"];
}

@end
