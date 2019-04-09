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
// ACPPlacesMonitorInternalTests.m
//

#import <XCTest/XCTest.h>
#import "OCMock.h"
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "ACPCore.h"
#import "ACPPlaces.h"
#import "ACPPlacesMonitor.h"
#import "ACPPlacesMonitorConstantsTests.h"
#import "ACPPlacesMonitorInternal.h"
#import "ACPPlacesMonitorLocationDelegate.h"
#import "ACPPlacesQueue.h"

// private properties and methods exposed for testing
@interface ACPPlacesMonitorInternal()
@property(nonatomic, strong) ACPPlacesQueue* eventQueue;
@property(nonatomic, strong) ACPPlacesMonitorLocationDelegate* locationDelegate;
@property(nonatomic, strong) CLLocationManager* locationManager;
@property(nonatomic, strong) NSMutableArray<NSString*>* currentlyMonitoredRegions;
@property(nonatomic, strong) NSMutableArray<NSString*>* userWithinRegions;
@property(nonatomic) ACPPlacesMonitorMode monitorMode;
- (void) loadPersistedValues;
- (void) resetMonitoredGeofences;
- (void) setMonitorMode: (ACPPlacesMonitorMode) monitorMode;
- (void) beginTrackingLocation;
- (void) updateUserWithinRegionsInPersistence;
- (void) updateCurrentlyMonitoredRegionsInPersistence;
- (void) startMonitoring;
- (void) startMonitoringGeoFences: (NSArray*) newGeoFences;
- (void) stopMonitoringGeoFences;
- (void) removeNonMonitoredRegionsFromUserWithinRegions;
- (void) startMonitoringSignificantLocationChanges;
- (void) stopMonitoringSignificantLocationChanges;
- (void) startMonitoringContinuousLocationChanges;
- (void) stopMonitoringContinuousLocationChanges;
- (BOOL) userHasDeclinedLocationPermission: (CLAuthorizationStatus) status;
- (BOOL) backgroundLocationUpdatesEnabledInBundle;
@end

@interface ACPPlacesMonitorInternalTests : XCTestCase

@property (nonatomic, strong) ACPPlacesMonitorInternal* monitor;
@property (nonatomic, strong) id placesMock;
@property (nonatomic, strong) id extensionApiMock;
@property (nonatomic, strong) id coreMock;
@property (nonatomic, strong) NSDictionary *validPlacesConfig;
@property (nonatomic, strong) CLLocation *fakeLocation;
@property (nonatomic, strong) CLRegion *fakeRegion;
@property (nonatomic, strong) ACPPlacesPoi *fakePoi;

@end

@implementation ACPPlacesMonitorInternalTests

- (void) setUp {
    _validPlacesConfig = @{@"validConfig":@"not actually used by this extension"};
    
    ACPPlacesMonitorInternal *tempMonitor = [[ACPPlacesMonitorInternal alloc] init];
    _monitor = OCMPartialMock(tempMonitor);
    _placesMock = OCMClassMock([ACPPlaces class]);
    _coreMock = OCMClassMock([ACPCore class]);
    _extensionApiMock = OCMClassMock([ACPExtensionApi class]);
    NSError *error = nil;
    OCMStub([_extensionApiMock getSharedEventState:ACPPlacesMonitorConfigurationSharedState_Test
                                             event:[OCMArg any]
                                             error:[OCMArg setTo:error]]).andReturn(_validPlacesConfig);
    OCMStub([_monitor api]).andReturn(_extensionApiMock);
    
    _fakeLocation = [[CLLocation alloc] initWithLatitude:12.34 longitude:23.45];
    _fakePoi = [[ACPPlacesPoi alloc] init];
    _fakePoi.latitude = 12.34;
    _fakePoi.longitude = 23.45;
    _fakePoi.radius = 500;
    _fakePoi.identifier = @"region identifier";
    _fakePoi.userIsWithin = YES;
    _fakeRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(12.34, 23.45)
                                                    radius:500
                                                identifier:@"region identifier"];
}

- (void) tearDown {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACPPlacesMonitorDefaultsMonitorMode_Test];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACPPlacesMonitorDefaultsMonitoredRegions_Test];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:ACPPlacesMonitorDefaultsUserWithinRegions_Test];
}

- (void) testGetName {
    XCTAssertEqual(ACPPlacesMonitorExtensionName_Test, [_monitor name]);
}

- (void) testGetVersion {
    XCTAssertEqual(ACPPlacesMonitorExtensionVersion_Test, [_monitor version]);
}

- (void) testInit {
    // setup
    NSError *error = nil;
    OCMStub([_extensionApiMock registerListener:[OCMArg any]
                                      eventType:[OCMArg any]
                                    eventSource:[OCMArg any]
                                          error:[OCMArg setTo:error]]).andReturn(YES);
    
    // test
    ACPPlacesMonitorInternal *monitor = [[ACPPlacesMonitorInternal alloc] init];
    
    // verify
    XCTAssertNotNil(monitor);
    XCTAssertNotNil(monitor.eventQueue);
    XCTAssertEqual(ACPPlacesMonitorModeSignificantChanges, monitor.monitorMode);
    XCTAssertNotNil(monitor.currentlyMonitoredRegions);
    XCTAssertEqual(0, monitor.currentlyMonitoredRegions.count);
    XCTAssertNotNil(monitor.userWithinRegions);
    XCTAssertEqual(0, monitor.userWithinRegions.count);
    XCTAssertNotNil(monitor.locationManager);
    XCTAssertNotNil(monitor.locationManager.delegate);
    XCTAssertTrue([monitor.locationManager.delegate isKindOfClass:ACPPlacesMonitorLocationDelegate.class]);
    XCTAssertEqual(100, monitor.locationManager.distanceFilter);
    XCTAssertEqual(kCLLocationAccuracyBest, monitor.locationManager.desiredAccuracy);
    XCTAssertEqual(monitor, monitor.locationDelegate.parent);
}

- (void) testInitFromBackgroundThread {
    // setup
    NSError *error = nil;
    OCMStub([_extensionApiMock registerListener:[OCMArg any]
                                      eventType:[OCMArg any]
                                    eventSource:[OCMArg any]
                                          error:[OCMArg setTo:error]]).andReturn(YES);
    
    // test
    __block ACPPlacesMonitorInternal *monitor;
    dispatch_sync(dispatch_queue_create("testqueue", 0), ^{
        monitor = [[ACPPlacesMonitorInternal alloc] init];
    });
    
    // verify
    XCTAssertNotNil(monitor);
    XCTAssertNotNil(monitor.eventQueue);
    XCTAssertEqual(ACPPlacesMonitorModeSignificantChanges, monitor.monitorMode);
    XCTAssertNotNil(monitor.currentlyMonitoredRegions);
    XCTAssertEqual(0, monitor.currentlyMonitoredRegions.count);
    XCTAssertNotNil(monitor.userWithinRegions);
    XCTAssertEqual(0, monitor.userWithinRegions.count);
    XCTAssertNotNil(monitor.locationManager);
    XCTAssertNotNil(monitor.locationManager.delegate);
    XCTAssertTrue([monitor.locationManager.delegate isKindOfClass:ACPPlacesMonitorLocationDelegate.class]);
    XCTAssertEqual(100, monitor.locationManager.distanceFilter);
    XCTAssertEqual(kCLLocationAccuracyBest, monitor.locationManager.desiredAccuracy);
    XCTAssertEqual(monitor, monitor.locationDelegate.parent);
}

- (void) testInitValuesInPersistence {
    // setup
    NSArray *persistedMonitoredRegions = @[@"regionid1", @"regionid2"];
    NSArray *persistedUserWithinRegions = @[@"regionid1"];
    ACPPlacesMonitorMode persistedMonitorMode = ACPPlacesMonitorModeContinuous;
    
    [[NSUserDefaults standardUserDefaults] setInteger:persistedMonitorMode
                                               forKey:ACPPlacesMonitorDefaultsMonitorMode_Test];
    [[NSUserDefaults standardUserDefaults] setObject:persistedMonitoredRegions
                                              forKey:ACPPlacesMonitorDefaultsMonitoredRegions_Test];
    [[NSUserDefaults standardUserDefaults] setObject:persistedUserWithinRegions
                                              forKey:ACPPlacesMonitorDefaultsUserWithinRegions_Test];
    
    // test
    ACPPlacesMonitorInternal *monitor = [[ACPPlacesMonitorInternal alloc] init];
    
    // verify
    XCTAssertNotNil(monitor);
    XCTAssertNotNil(monitor.eventQueue);
    XCTAssertEqual(ACPPlacesMonitorModeContinuous, monitor.monitorMode);
    XCTAssertNotNil(monitor.currentlyMonitoredRegions);
    XCTAssertEqual(2, monitor.currentlyMonitoredRegions.count);
    XCTAssertTrue([monitor.currentlyMonitoredRegions containsObject:@"regionid1"]);
    XCTAssertTrue([monitor.currentlyMonitoredRegions containsObject:@"regionid2"]);
    XCTAssertNotNil(monitor.userWithinRegions);
    XCTAssertEqual(1, monitor.userWithinRegions.count);
    XCTAssertTrue([monitor.userWithinRegions containsObject:@"regionid1"]);
    XCTAssertNotNil(monitor.locationManager);
    XCTAssertNotNil(monitor.locationManager.delegate);
    XCTAssertTrue([monitor.locationManager.delegate isKindOfClass:ACPPlacesMonitorLocationDelegate.class]);
    XCTAssertEqual(100, monitor.locationManager.distanceFilter);
    XCTAssertEqual(kCLLocationAccuracyBest, monitor.locationManager.desiredAccuracy);
    XCTAssertEqual(monitor, monitor.locationDelegate.parent);
}

- (void) testOnUnregister {
    // test
    [_monitor onUnregister];
    
    // verify
    OCMVerify([_extensionApiMock clearSharedEventStates:nil]);
}

- (void) testUnexpectedError {
    // setup
    NSError *error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain
                                                code:kCLErrorLocationUnknown
                                            userInfo:nil];
    
    // test
    [_monitor unexpectedError:error];
}

- (void) testQueueEvent {
    // setup
    ACPExtensionEvent *event = [[ACPExtensionEvent alloc] init];
    
    // test
    [_monitor queueEvent:event];
    
    // verify
    XCTAssertEqual(event, [_monitor.eventQueue peek]);
}

- (void) testQueueEventNilParam {
    // test
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [_monitor queueEvent:nil];
#pragma clang diagnostic pop
    
    // verify
    XCTAssertNil([_monitor.eventQueue peek]);
}

- (void) testProcessEventsEmptyQueue {
    // test
    [_monitor processEvents];
    
    // verify
    XCTAssertNil([_monitor.eventQueue peek]);
}

- (void) testProcessEventsNoConfig {
    // setup
    ACPPlacesMonitorInternal *tempMonitor = [[ACPPlacesMonitorInternal alloc] init];
    _monitor = OCMPartialMock(tempMonitor);
    _placesMock = OCMClassMock([ACPPlaces class]);
    _coreMock = OCMClassMock([ACPCore class]);
    _extensionApiMock = OCMClassMock([ACPExtensionApi class]);
    NSError *error = nil;
    OCMStub([_extensionApiMock getSharedEventState:ACPPlacesMonitorConfigurationSharedState_Test
                                             event:[OCMArg any]
                                             error:[OCMArg setTo:error]]).andReturn(@{});
    OCMStub([_monitor api]).andReturn(_extensionApiMock);
    
    NSError* eventCreationError = nil;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:ACPPlacesMonitorEventNameStart_Test
                                                                    type:ACPPlacesMonitorEventTypeMonitor_Test
                                                                  source:ACPPlacesMonitorEventSourceRequestContent_Test
                                                                    data:nil
                                                                   error:&eventCreationError];
    [_monitor.eventQueue add:event];
    
    // test
    [_monitor processEvents];
    
    // verify
    XCTAssertNotNil([_monitor.eventQueue peek]);
}

- (void) testProcessEventsErrorFromGetSharedState {
    // setup
    ACPPlacesMonitorInternal *tempMonitor = [[ACPPlacesMonitorInternal alloc] init];
    _monitor = OCMPartialMock(tempMonitor);
    _placesMock = OCMClassMock([ACPPlaces class]);
    _coreMock = OCMClassMock([ACPCore class]);
    _extensionApiMock = OCMClassMock([ACPExtensionApi class]);
    NSError *error = [[NSError alloc] initWithDomain:NSCocoaErrorDomain
                                                code:kCLErrorLocationUnknown
                                            userInfo:nil];
    OCMStub([_extensionApiMock getSharedEventState:ACPPlacesMonitorConfigurationSharedState_Test
                                             event:[OCMArg any]
                                             error:[OCMArg setTo:error]]).andReturn(_validPlacesConfig);
    OCMStub([_monitor api]).andReturn(_extensionApiMock);
    
    NSError* eventCreationError = nil;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:ACPPlacesMonitorEventNameStart_Test
                                                                    type:ACPPlacesMonitorEventTypeMonitor_Test
                                                                  source:ACPPlacesMonitorEventSourceRequestContent_Test
                                                                    data:nil
                                                                   error:&eventCreationError];
    [_monitor.eventQueue add:event];
    
    // test
    [_monitor processEvents];
    
    // verify
    XCTAssertNotNil([_monitor.eventQueue peek]);
}

- (void) testProcessEventsStartEvent {
    // setup
    NSError* eventCreationError = nil;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:ACPPlacesMonitorEventNameStart_Test
                                                                    type:ACPPlacesMonitorEventTypeMonitor_Test
                                                                  source:ACPPlacesMonitorEventSourceRequestContent_Test
                                                                    data:nil
                                                                   error:&eventCreationError];
    [_monitor.eventQueue add:event];
    
    // test
    [_monitor processEvents];
    
    // verify
    XCTAssertNil([_monitor.eventQueue peek]);
    OCMVerify([_monitor startMonitoring]);
}

- (void) testProcessEventsStopEvent {
    // setup
    NSError* eventCreationError = nil;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:ACPPlacesMonitorEventNameStop_Test
                                                                    type:ACPPlacesMonitorEventTypeMonitor_Test
                                                                  source:ACPPlacesMonitorEventSourceRequestContent_Test
                                                                    data:nil
                                                                   error:&eventCreationError];
    [_monitor.eventQueue add:event];
    
    // test
    [_monitor processEvents];
    
    // verify
    XCTAssertNil([_monitor.eventQueue peek]);
    OCMVerify([_monitor stopAllMonitoring]);
}

- (void) testProcessEventsUpdateLocationNowEvent {
    // setup
    NSError* eventCreationError = nil;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:ACPPlacesMonitorEventNameUpdateLocationNow_Test
                                                                    type:ACPPlacesMonitorEventTypeMonitor_Test
                                                                  source:ACPPlacesMonitorEventSourceRequestContent_Test
                                                                    data:nil
                                                                   error:&eventCreationError];
    [_monitor.eventQueue add:event];
    
    // test
    [_monitor processEvents];
    
    // verify
    XCTAssertNil([_monitor.eventQueue peek]);
    OCMVerify([_monitor updateLocationNow]);
}

- (void) testProcessEventsConfigurationEvent {
    // setup
    NSError* eventCreationError = nil;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:ACPPlacesMonitorEventNameUpdateMonitorConfiguration_Test
                                                                    type:ACPPlacesMonitorEventTypeMonitor_Test
                                                                  source:ACPPlacesMonitorEventSourceRequestContent_Test
                                                                    data:@{ACPPlacesMonitorEventDataMonitorMode_Test:@(1)}
                                                                   error:&eventCreationError];
    [_monitor.eventQueue add:event];
    
    // test
    [_monitor processEvents];
    
    // verify
    XCTAssertNil([_monitor.eventQueue peek]);
    OCMVerify([_monitor setMonitorMode:ACPPlacesMonitorModeContinuous]);
}

- (void) testProcessEventsConfigurationEventNoModeInEventData {
    // setup
    NSError* eventCreationError = nil;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:ACPPlacesMonitorEventNameUpdateMonitorConfiguration_Test
                                                                    type:ACPPlacesMonitorEventTypeMonitor_Test
                                                                  source:ACPPlacesMonitorEventSourceRequestContent_Test
                                                                    data:nil
                                                                   error:&eventCreationError];
    [_monitor.eventQueue add:event];
    
    // test
    [_monitor processEvents];
    
    // verify
    XCTAssertNil([_monitor.eventQueue peek]);
    OCMVerify([_monitor setMonitorMode:ACPPlacesMonitorModeSignificantChanges]);
}

- (void) testStopAllMonitoring {
    // test
    [_monitor stopAllMonitoring];
    
    // verify
    OCMVerify([_monitor stopMonitoringContinuousLocationChanges]);
    OCMVerify([_monitor stopMonitoringSignificantLocationChanges]);
    OCMVerify([_monitor stopMonitoringGeoFences]);
}

- (void) testAddDeviceToRegion {
    // setup
    XCTAssertEqual(0, _monitor.userWithinRegions.count);
    
    // test
    [_monitor addDeviceToRegion:_fakeRegion];
    
    // verify
    XCTAssertEqual(1, _monitor.userWithinRegions.count);
    XCTAssertTrue([_fakeRegion.identifier isEqualToString:_monitor.userWithinRegions[0]]);
    OCMVerify([_monitor updateUserWithinRegionsInPersistence]);
}

- (void) testRemoveDeviceFromRegion {
    // setup
    _monitor.userWithinRegions[0] = _fakeRegion.identifier;
    
    // test
    [_monitor removeDeviceFromRegion:_fakeRegion];
    
    // verify
    XCTAssertEqual(0, _monitor.userWithinRegions.count);
    OCMVerify([_monitor updateUserWithinRegionsInPersistence]);
}

- (void) testUpdateUserWithinRegionsInPersistence {
    // setup
    _monitor.userWithinRegions[0] = _fakeRegion.identifier;
    XCTAssertFalse([[NSUserDefaults standardUserDefaults] objectForKey:ACPPlacesMonitorDefaultsUserWithinRegions_Test]);
    
    // test
    [_monitor updateUserWithinRegionsInPersistence];
    
    // verify
    NSArray *listFromDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:ACPPlacesMonitorDefaultsUserWithinRegions_Test];
    XCTAssertEqual(1, listFromDefaults.count);
    XCTAssertTrue([_fakeRegion.identifier isEqualToString:listFromDefaults[0]]);
}

- (void) testUpdateUserWithinRegionsInPersistenceEmptyRegions {
    // setup
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@[_fakeRegion.identifier] forKey:ACPPlacesMonitorDefaultsUserWithinRegions_Test];
    [defaults synchronize];
    
    // test
    [_monitor updateUserWithinRegionsInPersistence];
    
    // verify
    NSArray *listFromDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:ACPPlacesMonitorDefaultsUserWithinRegions_Test];
    XCTAssertEqual(0, listFromDefaults.count);
}

- (void) testUpdateCurrentlyMonitoredRegionsInPersistence {
    // setup
    _monitor.currentlyMonitoredRegions[0] = _fakeRegion.identifier;
    XCTAssertFalse([[NSUserDefaults standardUserDefaults] objectForKey:ACPPlacesMonitorDefaultsMonitoredRegions_Test]);
    
    // test
    [_monitor updateCurrentlyMonitoredRegionsInPersistence];
    
    // verify
    NSArray *listFromDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:ACPPlacesMonitorDefaultsMonitoredRegions_Test];
    XCTAssertEqual(1, listFromDefaults.count);
    XCTAssertTrue([_fakeRegion.identifier isEqualToString:listFromDefaults[0]]);
}

- (void) testUpdateCurrentlyMonitoredRegionsInPersistenceEmptyRegions {
    // setup
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@[_fakeRegion.identifier] forKey:ACPPlacesMonitorDefaultsMonitoredRegions_Test];
    [defaults synchronize];
    
    // test
    [_monitor updateCurrentlyMonitoredRegionsInPersistence];
    
    // verify
    NSArray *listFromDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:ACPPlacesMonitorDefaultsMonitoredRegions_Test];
    XCTAssertEqual(0, listFromDefaults.count);
}

- (void) testDeviceIsWithinRegionTrue {
    // setup
    [_monitor.userWithinRegions addObject:_fakeRegion.identifier];
    
    // test
    bool result = [_monitor deviceIsWithinRegion:_fakeRegion];
    
    // verify
    XCTAssertTrue(result);
}

- (void) testDeviceIsWithinRegionFalse {
    // setup
    [_monitor.userWithinRegions removeAllObjects];
    
    // test
    bool result = [_monitor deviceIsWithinRegion:_fakeRegion];
    
    // verify
    XCTAssertFalse(result);
}

- (void) testPostLocationUpdateNoPois {
    // setup
    OCMStub([_placesMock getNearbyPointsOfInterest:_fakeLocation
                                             limit:ACPPlacesMonitorDefaultMaxMonitoredRegionCount_Test
                                          callback:[OCMArg any]]).andDo(^(NSInvocation *invocation) {
        // get a reference to the Places callback
        void (^testableCallback)(NSArray<ACPPlacesPoi*>* _Nullable nearbyPoi);
        [invocation getArgument:&testableCallback atIndex:4];
        
        testableCallback(nil);
        
        // verify after callback processes
        OCMVerify([self.monitor resetMonitoredGeofences]);
        OCMVerify([self.coreMock log:ACPMobileLogLevelDebug
                             tag:ACPPlacesMonitorExtensionName_Test
                         message:@"No nearby Places were retrieved due to a network issue or no POIs near the device location."]);
        OCMVerify([self.monitor removeNonMonitoredRegionsFromUserWithinRegions]);
    });
    
    // test
    [_monitor postLocationUpdate:_fakeLocation];
}

- (void) testPostLocationUpdate {
    // setup
    OCMStub([_placesMock getNearbyPointsOfInterest:_fakeLocation
                                             limit:ACPPlacesMonitorDefaultMaxMonitoredRegionCount_Test
                                          callback:[OCMArg any]]).andDo((^(NSInvocation *invocation) {
        // get a reference to the Places callback
        void (^testableCallback)(NSArray<ACPPlacesPoi*>* _Nullable nearbyPoi);
        [invocation getArgument:&testableCallback atIndex:4];
        
        ACPPlacesPoi *myPoi = [[ACPPlacesPoi alloc] init];
        NSArray *poiArray = @[myPoi];
        NSString *message = [NSString stringWithFormat:@"Received a new list of POIs from Places: %@", poiArray];
        testableCallback(poiArray);
        
        // verify after callback processes
        OCMVerify([self.monitor resetMonitoredGeofences]);
        OCMVerify([self.coreMock log:ACPMobileLogLevelDebug
                                 tag:ACPPlacesMonitorExtensionName_Test
                             message:message]);
        OCMVerify([self.monitor startMonitoringGeoFences:poiArray]);
        OCMVerify([self.monitor removeNonMonitoredRegionsFromUserWithinRegions]);
    }));
    
    // test
    [_monitor postLocationUpdate:_fakeLocation];
}

- (void) testUpdateLocationNow {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    _monitor.locationManager = locationManagerMock;
    
    // test
    [_monitor updateLocationNow];
    
    // verify
    OCMVerify([locationManagerMock requestLocation]);
}

- (void) testProcessRegionUpdateWithEventType {
    // test
    [_monitor postRegionUpdate:_fakeRegion withEventType:ACPRegionEventTypeEntry];
    
    // verify
    OCMVerify([_placesMock processRegionEvent:_fakeRegion forRegionEventType:ACPRegionEventTypeEntry]);
}

- (void) testLoadPersistedValues {
    // setup
    _monitor.monitorMode = ACPPlacesMonitorModeContinuous;
    [_monitor.currentlyMonitoredRegions removeAllObjects];
    [_monitor.userWithinRegions removeAllObjects];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:@(ACPPlacesMonitorModeSignificantChanges) forKey:ACPPlacesMonitorDefaultsMonitorMode_Test];
    [defaults setObject:@[_fakeRegion.identifier] forKey:ACPPlacesMonitorDefaultsMonitoredRegions_Test];
    [defaults setObject:@[_fakeRegion.identifier] forKey:ACPPlacesMonitorDefaultsUserWithinRegions_Test];
    [defaults synchronize];
    
    // test
    [_monitor loadPersistedValues];
    
    // verify
    XCTAssertEqual(ACPPlacesMonitorModeSignificantChanges, _monitor.monitorMode);
    XCTAssertEqual(1, _monitor.currentlyMonitoredRegions.count);
    XCTAssertTrue([_fakeRegion.identifier isEqualToString:_monitor.currentlyMonitoredRegions[0]]);
    XCTAssertEqual(1, _monitor.userWithinRegions.count);
    XCTAssertTrue([_fakeRegion.identifier isEqualToString:_monitor.userWithinRegions[0]]);
}

- (void) testResetMonitoredGeofencesNoMonitoredRegions {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock monitoredRegions]).andReturn(@[]);
    _monitor.locationManager = locationManagerMock;
    OCMReject([locationManagerMock stopMonitoringForRegion:[OCMArg any]]);
    [_monitor.currentlyMonitoredRegions addObject:_fakeRegion.identifier];
    
    // test
    [_monitor resetMonitoredGeofences];
    
    // verify
    XCTAssertEqual(0, _monitor.currentlyMonitoredRegions.count);
    OCMVerify([_monitor updateCurrentlyMonitoredRegionsInPersistence]);
}

- (void) testResetMonitoredGeofencesMatchingMonitoredRegions {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock monitoredRegions]).andReturn(@[_fakeRegion]);
    _monitor.locationManager = locationManagerMock;
    [_monitor.currentlyMonitoredRegions addObject:_fakeRegion.identifier];
    
    // test
    [_monitor resetMonitoredGeofences];
    
    // verify
    OCMVerify([locationManagerMock stopMonitoringForRegion:_fakeRegion]);
    XCTAssertEqual(0, _monitor.currentlyMonitoredRegions.count);
    OCMVerify([_monitor updateCurrentlyMonitoredRegionsInPersistence]);
}

- (void) testResetMonitoredGeofencesNoMatchingMonitoredRegions {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock monitoredRegions]).andReturn(@[_fakeRegion]);
    OCMReject([locationManagerMock stopMonitoringForRegion:[OCMArg any]]);
    _monitor.locationManager = locationManagerMock;
    [_monitor.currentlyMonitoredRegions addObject:@"nonMatchingId"];
    
    // test
    [_monitor resetMonitoredGeofences];
    
    // verify
    XCTAssertEqual(0, _monitor.currentlyMonitoredRegions.count);
    OCMVerify([_monitor updateCurrentlyMonitoredRegionsInPersistence]);
}

- (void) testSetMonitorMode {
    // setup
    [[NSUserDefaults standardUserDefaults] setInteger:ACPPlacesMonitorModeSignificantChanges
                                               forKey:ACPPlacesMonitorDefaultsMonitorMode_Test];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    // test
    [_monitor setMonitorMode:ACPPlacesMonitorModeContinuous];
    
    // verify
    OCMVerify([_monitor beginTrackingLocation]);
    XCTAssertEqual(ACPPlacesMonitorModeContinuous, [[NSUserDefaults standardUserDefaults]
                                                    integerForKey:ACPPlacesMonitorDefaultsMonitorMode_Test]);
}

- (void) testBeginTrackingLocationContinuous {
    // setup
    _monitor.monitorMode = ACPPlacesMonitorModeContinuous;
    
    // test
    [_monitor beginTrackingLocation];
    
    // verify
    OCMVerify([_monitor startMonitoringContinuousLocationChanges]);
    OCMVerify([_monitor stopMonitoringSignificantLocationChanges]);
    OCMVerify([_monitor updateLocationNow]);
}

- (void) testBeginTrackingLocationSignificantChanges {
    // setup
    _monitor.monitorMode = ACPPlacesMonitorModeSignificantChanges;
    
    // test
    [_monitor beginTrackingLocation];
    
    // verify
    OCMVerify([_monitor stopMonitoringContinuousLocationChanges]);
    OCMVerify([_monitor startMonitoringSignificantLocationChanges]);
    OCMVerify([_monitor updateLocationNow]);
}

- (void) testBeginTrackingLocationContinuousAndSignificantChanges {
    // setup
    _monitor.monitorMode = ACPPlacesMonitorModeContinuous | ACPPlacesMonitorModeSignificantChanges;
    
    // test
    [_monitor beginTrackingLocation];
    
    // verify
    OCMVerify([_monitor startMonitoringContinuousLocationChanges]);
    OCMVerify([_monitor startMonitoringSignificantLocationChanges]);
    OCMVerify([_monitor updateLocationNow]);
}

- (void) testStartMonitoringNoAuthorization {
    // setup
    OCMStub([_monitor userHasDeclinedLocationPermission:kCLAuthorizationStatusRestricted]).andReturn(YES);
    OCMReject([_monitor beginTrackingLocation]);
    
    // test
    [_monitor startMonitoring];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"Permission to use location data has been denied by the user"]);
}

- (void) testStartMonitoringStatusNotDetermined {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock authorizationStatus]).andReturn(kCLAuthorizationStatusNotDetermined);
    _monitor.locationManager = locationManagerMock;
    OCMStub([_monitor userHasDeclinedLocationPermission:kCLAuthorizationStatusNotDetermined]).andReturn(NO);
    
    // test
    [_monitor startMonitoring];
    
    // verify
    OCMVerify([_monitor beginTrackingLocation]);
    OCMVerify([locationManagerMock requestAlwaysAuthorization]);
}

- (void) testStartMonitoringGeoFencesNoPermission {
    // setup
    NSArray *newGeoFences = @[_fakePoi];
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock isMonitoringAvailableForClass:[CLCircularRegion class]]).andReturn(YES);
    OCMStub([locationManagerMock maximumRegionMonitoringDistance]).andReturn(100);
    _monitor.locationManager = locationManagerMock;
    OCMStub([_monitor userHasDeclinedLocationPermission:kCLAuthorizationStatusRestricted]).andReturn(YES);
    id circularRegionMock = OCMClassMock([CLCircularRegion class]);
    OCMStub([circularRegionMock initWithCenter:CLLocationCoordinate2DMake(_fakePoi.latitude, _fakePoi.longitude)
                                        radius:_fakePoi.radius
                                    identifier:_fakePoi.identifier]).andReturn(_fakeRegion);
    [_monitor.userWithinRegions addObject:_fakeRegion.identifier];
    OCMReject([locationManagerMock startMonitoringForRegion:_fakeRegion]);
    OCMReject([_monitor addDeviceToRegion:_fakeRegion]);
    OCMReject([_placesMock processRegionEvent:_fakeRegion forRegionEventType:ACPRegionEventTypeEntry]);
    OCMReject([_monitor updateCurrentlyMonitoredRegionsInPersistence]);
    
    // test
    [_monitor startMonitoringGeoFences:newGeoFences];
    
    // verify
    XCTAssertEqual(0, _monitor.currentlyMonitoredRegions.count);
}

- (void) testStartMonitoringGeoFencesMonitoringNotAvailable {
    // setup
    NSArray *newGeoFences = @[_fakePoi];
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock isMonitoringAvailableForClass:[CLCircularRegion class]]).andReturn(NO);
    OCMStub([locationManagerMock maximumRegionMonitoringDistance]).andReturn(100);
    _monitor.locationManager = locationManagerMock;
    OCMStub([_monitor userHasDeclinedLocationPermission:kCLAuthorizationStatusRestricted]).andReturn(NO);
    id circularRegionMock = OCMClassMock([CLCircularRegion class]);
    OCMStub([circularRegionMock initWithCenter:CLLocationCoordinate2DMake(_fakePoi.latitude, _fakePoi.longitude)
                                        radius:_fakePoi.radius
                                    identifier:_fakePoi.identifier]).andReturn(_fakeRegion);
    [_monitor.userWithinRegions addObject:_fakeRegion.identifier];
    OCMReject([locationManagerMock startMonitoringForRegion:_fakeRegion]);
    OCMReject([_monitor addDeviceToRegion:_fakeRegion]);
    OCMReject([_placesMock processRegionEvent:_fakeRegion forRegionEventType:ACPRegionEventTypeEntry]);
    OCMReject([_monitor updateCurrentlyMonitoredRegionsInPersistence]);
    
    // test
    [_monitor startMonitoringGeoFences:newGeoFences];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"This device's GPS capabilities do not support monitoring geofence regions"]);
    XCTAssertEqual(0, _monitor.currentlyMonitoredRegions.count);
}

- (void) testStartMonitoringGeoFencesNoNewFences {
    // setup
    NSArray *newGeoFences = @[];
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock isMonitoringAvailableForClass:[CLCircularRegion class]]).andReturn(YES);
    OCMStub([locationManagerMock maximumRegionMonitoringDistance]).andReturn(100);
    _monitor.locationManager = locationManagerMock;
    OCMStub([_monitor userHasDeclinedLocationPermission:kCLAuthorizationStatusRestricted]).andReturn(NO);
    id circularRegionMock = OCMClassMock([CLCircularRegion class]);
    OCMStub([circularRegionMock initWithCenter:CLLocationCoordinate2DMake(_fakePoi.latitude, _fakePoi.longitude)
                                        radius:_fakePoi.radius
                                    identifier:_fakePoi.identifier]).andReturn(_fakeRegion);
    [_monitor.userWithinRegions addObject:_fakeRegion.identifier];
    OCMReject([locationManagerMock startMonitoringForRegion:_fakeRegion]);
    OCMReject([_monitor addDeviceToRegion:_fakeRegion]);
    OCMReject([_placesMock processRegionEvent:_fakeRegion forRegionEventType:ACPRegionEventTypeEntry]);
    
    // test
    [_monitor startMonitoringGeoFences:newGeoFences];
    
    // verify
    OCMVerify([_monitor updateCurrentlyMonitoredRegionsInPersistence]);
    XCTAssertEqual(0, _monitor.currentlyMonitoredRegions.count);
}

- (void) testStartMonitoringGeoFencesUserWithinNewRegion {
    // setup
    NSArray *newGeoFences = @[_fakePoi];
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock isMonitoringAvailableForClass:[CLCircularRegion class]]).andReturn(YES);
    OCMStub([locationManagerMock maximumRegionMonitoringDistance]).andReturn(100);
    _monitor.locationManager = locationManagerMock;
    OCMStub([_monitor userHasDeclinedLocationPermission:kCLAuthorizationStatusRestricted]).andReturn(NO);
    id circularRegionMock = OCMClassMock([CLCircularRegion class]);
    OCMStub([circularRegionMock initWithCenter:CLLocationCoordinate2DMake(_fakePoi.latitude, _fakePoi.longitude)
                                        radius:_fakePoi.radius
                                    identifier:_fakePoi.identifier]).andReturn(_fakeRegion);
    
    // test
    [_monitor startMonitoringGeoFences:newGeoFences];
    
    // verify
    OCMVerify([locationManagerMock startMonitoringForRegion:_fakeRegion]);
    XCTAssertEqual(1, _monitor.currentlyMonitoredRegions.count);
    XCTAssertTrue([_fakeRegion.identifier isEqualToString:_monitor.currentlyMonitoredRegions[0]]);
    OCMVerify([_monitor addDeviceToRegion:_fakeRegion]);
    OCMVerify([_placesMock processRegionEvent:_fakeRegion forRegionEventType:ACPRegionEventTypeEntry]);
    OCMVerify([_monitor updateCurrentlyMonitoredRegionsInPersistence]);
}

- (void) testStartMonitoringGeoFencesUserWithinNewRegionNoDuplicateEntryEvents {
    // setup
    NSArray *newGeoFences = @[_fakePoi];
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock isMonitoringAvailableForClass:[CLCircularRegion class]]).andReturn(YES);
    OCMStub([locationManagerMock maximumRegionMonitoringDistance]).andReturn(100);
    _monitor.locationManager = locationManagerMock;
    OCMStub([_monitor userHasDeclinedLocationPermission:kCLAuthorizationStatusRestricted]).andReturn(NO);
    id circularRegionMock = OCMClassMock([CLCircularRegion class]);
    OCMStub([circularRegionMock initWithCenter:CLLocationCoordinate2DMake(_fakePoi.latitude, _fakePoi.longitude)
                                        radius:_fakePoi.radius
                                    identifier:_fakePoi.identifier]).andReturn(_fakeRegion);
    [_monitor.userWithinRegions addObject:_fakeRegion.identifier];
    OCMReject([_monitor addDeviceToRegion:_fakeRegion]);
    OCMReject([_placesMock processRegionEvent:_fakeRegion forRegionEventType:ACPRegionEventTypeEntry]);
    
    // test
    [_monitor startMonitoringGeoFences:newGeoFences];
    
    // verify
    OCMVerify([locationManagerMock startMonitoringForRegion:_fakeRegion]);
    XCTAssertEqual(1, _monitor.currentlyMonitoredRegions.count);
    XCTAssertTrue([_fakeRegion.identifier isEqualToString:_monitor.currentlyMonitoredRegions[0]]);
    OCMVerify([_monitor updateCurrentlyMonitoredRegionsInPersistence]);
}

- (void) testStopMonitoringGeoFences {
    // setup
    [_monitor.currentlyMonitoredRegions addObject:_fakeRegion.identifier];
    CLBeaconRegion *fakeBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[NSUUID UUID] identifier:@"abc"];
    NSArray *fakeRegions = @[_fakeRegion, fakeBeaconRegion];
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock monitoredRegions]).andReturn(fakeRegions);
    _monitor.locationManager = locationManagerMock;
    OCMReject([locationManagerMock stopMonitoringForRegion:fakeBeaconRegion]);
    
    // test
    [_monitor stopMonitoringGeoFences];
    
    // verify
    OCMVerify([locationManagerMock stopMonitoringForRegion:_fakeRegion]);
}

- (void) testRemoveNonMonitoredRegionsFromUserWithinRegions {
    // setup
    [_monitor.userWithinRegions addObject:_fakeRegion.identifier];
    [_monitor.currentlyMonitoredRegions addObject:@"5678"];
    
    // test
    [_monitor removeNonMonitoredRegionsFromUserWithinRegions];
    
    // verify
    XCTAssertEqual(0, _monitor.userWithinRegions.count);
    OCMVerify([_monitor updateUserWithinRegionsInPersistence]);
}

- (void) testRemoveNonMonitoredRegionsFromUserWithinRegionsStillMonitoringRegion {
    // setup
    [_monitor.userWithinRegions addObject:_fakeRegion.identifier];
    [_monitor.currentlyMonitoredRegions addObject:_fakeRegion.identifier];
    
    // test
    [_monitor removeNonMonitoredRegionsFromUserWithinRegions];
    
    // verify
    XCTAssertEqual(1, _monitor.userWithinRegions.count);
    XCTAssertTrue([_fakeRegion.identifier isEqualToString:_monitor.userWithinRegions[0]]);
    OCMVerify([_monitor updateUserWithinRegionsInPersistence]);
}

- (void) testStartMonitoringSignificantLocationChanges {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock significantLocationChangeMonitoringAvailable]).andReturn(YES);
    _monitor.locationManager = locationManagerMock;
    
    // test
    [_monitor startMonitoringSignificantLocationChanges];
    
    // verify
    OCMVerify([locationManagerMock startMonitoringSignificantLocationChanges]);
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"Significant location collection is enabled"]);
}

- (void) testStartMonitoringSignificantLocationChangesFeatureNotAvailable {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock significantLocationChangeMonitoringAvailable]).andReturn(NO);
    _monitor.locationManager = locationManagerMock;
    OCMReject([locationManagerMock startMonitoringSignificantLocationChanges]);

    // test
    [_monitor startMonitoringSignificantLocationChanges];
}

- (void) testStopMonitoringSignificantLocationChanges {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock significantLocationChangeMonitoringAvailable]).andReturn(YES);
    _monitor.locationManager = locationManagerMock;
    
    // test
    [_monitor stopMonitoringSignificantLocationChanges];
    
    // verify
    OCMVerify([locationManagerMock stopMonitoringSignificantLocationChanges]);
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"Significant location collection is disabled"]);
}

- (void) testStopMonitoringSignificantLocationChangesFeatureNotAvailable {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock significantLocationChangeMonitoringAvailable]).andReturn(NO);
    _monitor.locationManager = locationManagerMock;
    OCMReject([locationManagerMock stopMonitoringSignificantLocationChanges]);
    
    // test
    [_monitor stopMonitoringSignificantLocationChanges];
}

- (void) testStartMonitoringContinuousLocationChanges {
    // setup
    OCMStub([_monitor userHasDeclinedLocationPermission:kCLAuthorizationStatusRestricted]).andReturn(NO);
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock respondsToSelector:@selector(startUpdatingLocation)]).andReturn(YES);
    _monitor.locationManager = locationManagerMock;
    if ([locationManagerMock respondsToSelector:@selector(startUpdatingLocation)]) {
        [[locationManagerMock expect] startUpdatingLocation];
    }
    
    // test
    [_monitor startMonitoringContinuousLocationChanges];
    
    // verify
    [locationManagerMock verify];
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"Continuous location collection is enabled"]);
}

- (void) testStartMonitoringContinuousLocationChangesNoPermission {
    // setup
    OCMStub([_monitor userHasDeclinedLocationPermission:kCLAuthorizationStatusRestricted]).andReturn(YES);
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([locationManagerMock respondsToSelector:@selector(startUpdatingLocation)]).andReturn(YES);
    _monitor.locationManager = locationManagerMock;
    OCMReject([locationManagerMock respondsToSelector:@selector(startUpdatingLocation)]);
    OCMReject([locationManagerMock startUpdatingLocation]);
    
    // test
    [_monitor startMonitoringContinuousLocationChanges];
}

- (void) testStopMonitoringContinuousLocationChanges {
    // setup
    id locationManagerMock = OCMClassMock([CLLocationManager class]);
    _monitor.locationManager = locationManagerMock;
    
    // test
    [_monitor stopMonitoringContinuousLocationChanges];
    
    // verify
    OCMVerify([locationManagerMock stopUpdatingLocation]);
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"Continuous location collection is disabled"]);
}

- (void) testUserHasDeclinedLocationPermissionDenied {
    // setup
    CLAuthorizationStatus status = kCLAuthorizationStatusDenied;
    
    // test
    bool result = [_monitor userHasDeclinedLocationPermission:status];
    
    // verify
    XCTAssertTrue(result);
}

- (void) testUserHasDeclinedLocationPermissionRestricted {
    // setup
    CLAuthorizationStatus status = kCLAuthorizationStatusRestricted;
    
    // test
    bool result = [_monitor userHasDeclinedLocationPermission:status];
    
    // verify
    XCTAssertTrue(result);
}

- (void) testUserHasDeclinedLocationPermissionGranted {
    // setup
    CLAuthorizationStatus status = kCLAuthorizationStatusAuthorizedAlways;
    
    // test
    bool result = [_monitor userHasDeclinedLocationPermission:status];
    
    // verify
    XCTAssertFalse(result);
}

- (void) testBackgroundLocationUpdatesEnabledInBundleUpdatesEnabled {
    // setup
    id fakeBundle = OCMClassMock([NSBundle class]);
    NSArray *backgroundModesArray = @[@"location"];
    NSDictionary *fakeInfoDictionary = @{@"UIBackgroundModes":backgroundModesArray};
    OCMStub([fakeBundle infoDictionary]).andReturn(fakeInfoDictionary);
    id bundleMock = OCMClassMock([NSBundle class]);
    OCMStub([bundleMock mainBundle]).andReturn(fakeBundle);
    
    // test
    bool result = [_monitor backgroundLocationUpdatesEnabledInBundle];
    
    // verify
    XCTAssertTrue(result);
}

- (void) testBackgroundLocationUpdatesEnabledInBundleUpdatesNotEnabled {
    // setup
    id fakeBundle = OCMClassMock([NSBundle class]);
    NSArray *backgroundModesArray = @[];
    NSDictionary *fakeInfoDictionary = @{@"UIBackgroundModes":backgroundModesArray};
    OCMStub([fakeBundle infoDictionary]).andReturn(fakeInfoDictionary);
    id bundleMock = OCMClassMock([NSBundle class]);
    OCMStub([bundleMock mainBundle]).andReturn(fakeBundle);
    
    // test
    bool result = [_monitor backgroundLocationUpdatesEnabledInBundle];
    
    // verify
    XCTAssertFalse(result);
}

@end
