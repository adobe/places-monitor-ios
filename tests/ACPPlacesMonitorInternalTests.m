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
@end

@interface ACPPlacesMonitorInternalTests : XCTestCase

@property (nonatomic, strong) ACPPlacesMonitorInternal* monitor;
@property (nonatomic, strong) id placesMock;
@property (nonatomic, strong) id extensionApiMock;
@property (nonatomic, strong) NSDictionary *validPlacesConfig;

@end

@implementation ACPPlacesMonitorInternalTests

- (void) setUp {
    _validPlacesConfig = @{@"validConfig":@"not actually used by this extension"};
    
    ACPPlacesMonitorInternal *tempMonitor = [[ACPPlacesMonitorInternal alloc] init];
    _monitor = OCMPartialMock(tempMonitor);
    _placesMock = OCMClassMock([ACPPlaces class]);
    _extensionApiMock = OCMClassMock([ACPExtensionApi class]);
    NSError *error = nil;
    OCMStub([_extensionApiMock getSharedEventState:ACPPlacesMonitorConfigurationSharedState_Test
                                             event:[OCMArg any]
                                             error:[OCMArg setTo:error]]).andReturn(_validPlacesConfig);
    OCMStub([_monitor api]).andReturn(_extensionApiMock);
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
}

- (void) testProcessRegionUpdate {
    // setup
    CLRegion* fakeRegion = OCMClassMock([CLRegion class]);
    __block BOOL methodCalled = NO;
    OCMStub([_placesMock processRegionEvent:fakeRegion forRegionEventType:ACPRegionEventTypeEntry]).andDo(^(NSInvocation*) {
        methodCalled = YES;
    });
    
    // test
    [_monitor postRegionUpdate:fakeRegion withEventType:ACPRegionEventTypeEntry];
    
    // verify
    XCTAssertTrue(methodCalled, @"callback for processRegionEvent: was not called");
}

@end
