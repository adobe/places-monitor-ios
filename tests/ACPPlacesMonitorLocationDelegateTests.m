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
// ACPPlacesMonitorLocationDelegateTests.m
//

#import <Foundation/Foundation.h>
#import <XCTest/XCTest.h>
#import "OCMock.h"

#import "ACPCore.h"
#import "ACPPlacesMonitorConstantsTests.h"
#import "ACPPlacesMonitorLocationDelegate.h"
#import "ACPPlacesMonitorInternal.h"

// expose private methods for testing
@interface ACPPlacesMonitorLocationDelegate()
- (NSString*) authStatusString: (CLAuthorizationStatus) status;
@end

@interface ACPPlacesMonitorLocationDelegateTests : XCTestCase
@property (nonatomic, strong) ACPPlacesMonitorLocationDelegate *locationDelegate;
@property (nonatomic, strong) id placesMock;
@property (nonatomic, strong) id coreMock;
@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, strong) CLLocation *fakeLocation;
@property (nonatomic, strong) CLRegion *fakeRegion;
@property (nonatomic, strong) CLBeaconRegion *fakeBeaconRegion;
@property (nonatomic, strong) NSArray *locations;
@property (nonatomic, strong) NSError *fakeErrorLocationUnknown;
@property (nonatomic, strong) NSError *fakeErrorDenied;
@end

@implementation ACPPlacesMonitorLocationDelegateTests

- (void) setUp {
    _locationDelegate = [[ACPPlacesMonitorLocationDelegate alloc] init];
    _placesMock = OCMClassMock([ACPPlacesMonitorInternal class]);
    _coreMock = OCMClassMock([ACPCore class]);
    _locationDelegate.parent = _placesMock;
    _manager = [[CLLocationManager alloc] init];
    _fakeLocation = [[CLLocation alloc] initWithLatitude:12.34 longitude:23.45];
    _fakeRegion = [[CLCircularRegion alloc] initWithCenter:CLLocationCoordinate2DMake(12.34, 23.45)
                                                    radius:500
                                                identifier:@"region identifier"];
    _fakeBeaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:[NSUUID UUID]
                                                                major:1234
                                                                minor:5678
                                                           identifier:@"beacon identifier"];
    _locations = @[_fakeLocation];
    _fakeErrorLocationUnknown = [[NSError alloc] initWithDomain:NSCocoaErrorDomain
                                                           code:kCLErrorLocationUnknown
                                                       userInfo:nil];
    _fakeErrorDenied = [[NSError alloc] initWithDomain:NSCocoaErrorDomain
                                                  code:kCLErrorDenied
                                              userInfo:nil];
}

- (void) tearDown {
    
}

- (void) testInit {
    XCTAssertNotNil(_locationDelegate);
    XCTAssertNotNil(_locationDelegate.parent);
}

- (void) testDidUpdateLocations {
    // test
    [_locationDelegate locationManager:_manager didUpdateLocations:_locations];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    OCMVerify([_placesMock postLocationUpdate:_fakeLocation]);
}

- (void) testDidFailWithErrorLocationUnknown {
    // test
    [_locationDelegate locationManager:_manager didFailWithError:_fakeErrorLocationUnknown];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelWarning
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
}

- (void) testDidFailWithErrorDenied {
    // test
    [_locationDelegate locationManager:_manager didFailWithError:_fakeErrorDenied];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelWarning
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    OCMVerify([_placesMock stopAllMonitoring:YES]);
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
}

- (void) testDidEnterRegionHappy {
    // setup
    OCMStub([_placesMock deviceIsWithinRegion:[OCMArg any]]).andReturn(NO);
    
    // test
    [_locationDelegate locationManager:_manager didEnterRegion:_fakeRegion];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    OCMVerify([_placesMock postRegionUpdate:_fakeRegion withEventType:ACPRegionEventTypeEntry]);
    OCMVerify([_placesMock addDeviceToRegion:_fakeRegion]);
}

- (void) testDidEnterRegionDeviceAlreadyInRegion {
    // setup
    OCMStub([_placesMock deviceIsWithinRegion:[OCMArg any]]).andReturn(YES);
    OCMReject([_placesMock postRegionUpdate:[OCMArg any] withEventType:ACPRegionEventTypeEntry]);
    OCMReject([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    
    // test
    [_locationDelegate locationManager:_manager didEnterRegion:_fakeRegion];
    
    // verify
    [_placesMock verify];
    [_coreMock verify];
}

- (void) testDidEnterRegionBeaconRegionAndRangingAvailable {
    // setup
    OCMStub([_placesMock deviceIsWithinRegion:[OCMArg any]]).andReturn(NO);
    id managerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([managerMock isRangingAvailable]).andReturn(YES);
    
    // test
    [_locationDelegate locationManager:_manager didEnterRegion:_fakeBeaconRegion];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    OCMVerify([_placesMock postRegionUpdate:_fakeBeaconRegion withEventType:ACPRegionEventTypeEntry]);
    OCMVerify([_placesMock addDeviceToRegion:_fakeBeaconRegion]);
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    OCMVerify([_manager startRangingBeaconsInRegion:_fakeBeaconRegion]);
}

- (void) testDidExitRegionHappy {
    // setup
    OCMStub([_placesMock deviceIsWithinRegion:[OCMArg any]]).andReturn(YES);
    
    // test
    [_locationDelegate locationManager:_manager didExitRegion:_fakeRegion];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    OCMVerify([_placesMock postRegionUpdate:_fakeRegion withEventType:ACPRegionEventTypeExit]);
    OCMVerify([_placesMock removeDeviceFromRegion:_fakeRegion]);
}

- (void) testDidExitRegionDeviceNotInRegion {
    // setup
    OCMStub([_placesMock deviceIsWithinRegion:[OCMArg any]]).andReturn(NO);
    OCMReject([_placesMock postRegionUpdate:[OCMArg any] withEventType:ACPRegionEventTypeExit]);
    OCMReject([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    
    // test
    [_locationDelegate locationManager:_manager didExitRegion:_fakeRegion];
    
    // verify
    [_placesMock verify];
    [_coreMock verify];
}

- (void) testDidExitRegionBeaconRegionAndRangingAvailable {
    // setup
    OCMStub([_placesMock deviceIsWithinRegion:[OCMArg any]]).andReturn(YES);
    id managerMock = OCMClassMock([CLLocationManager class]);
    OCMStub([managerMock isRangingAvailable]).andReturn(YES);
    
    // test
    [_locationDelegate locationManager:_manager didExitRegion:_fakeBeaconRegion];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    OCMVerify([_placesMock postRegionUpdate:_fakeBeaconRegion withEventType:ACPRegionEventTypeExit]);
    OCMVerify([_placesMock removeDeviceFromRegion:_fakeBeaconRegion]);
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
    OCMVerify([_manager stopRangingBeaconsInRegion:_fakeBeaconRegion]);
}

- (void) testDidDetermineState {
    // test
    [_locationDelegate locationManager:_manager didDetermineState:CLRegionStateInside forRegion:_fakeRegion];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelVerbose
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
}

- (void) testMonitoringDidFail {
    // test
    [_locationDelegate locationManager:_manager monitoringDidFailForRegion:_fakeRegion withError:_fakeErrorLocationUnknown];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelWarning
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
}

- (void) testDidStartMonitoringForRegion {
    // test
    [_locationDelegate locationManager:_manager didStartMonitoringForRegion:_fakeRegion];
    
    // verify
    NSString *message = [NSString stringWithFormat:@"Started monitoring region: %@", _fakeRegion];
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:message]);
}

- (void) testDidRangeBeacons {
    // test
    [_locationDelegate locationManager:_manager didRangeBeacons:@[] inRegion:_fakeBeaconRegion];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
}

- (void) testRangingBeaconsDidFailForRegion {
    // test
    [_locationDelegate locationManager:_manager rangingBeaconsDidFailForRegion:_fakeBeaconRegion withError:_fakeErrorLocationUnknown];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
}

- (void) testDidPauseLocationUpdates {
    // test
    [_locationDelegate locationManagerDidPauseLocationUpdates:_manager];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"Location updates paused"]);
}

- (void) testDidResumeLocationUpdates {
    // test
    [_locationDelegate locationManagerDidResumeLocationUpdates:_manager];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"Location updates resumed"]);
}

- (void) testAuthStatusStringDenied {
    // setup
    CLAuthorizationStatus status = kCLAuthorizationStatusDenied;
    
    // test
    NSString *result = [_locationDelegate authStatusString:status];
    
    // verify
    XCTAssertEqual(@"Denied", result);
}

- (void) testAuthStatusStringRestricted {
    // setup
    CLAuthorizationStatus status = kCLAuthorizationStatusRestricted;
    
    // test
    NSString *result = [_locationDelegate authStatusString:status];
    
    // verify
    XCTAssertEqual(@"Restricted", result);
}

- (void) testAuthStatusStringNotDetermined {
    // setup
    CLAuthorizationStatus status = kCLAuthorizationStatusNotDetermined;
    
    // test
    NSString *result = [_locationDelegate authStatusString:status];
    
    // verify
    XCTAssertEqual(@"Not Determined", result);
}

- (void) testAuthStatusStringAlways {
    // setup
    CLAuthorizationStatus status = kCLAuthorizationStatusAuthorizedAlways;
    
    // test
    NSString *result = [_locationDelegate authStatusString:status];
    
    // verify
    XCTAssertEqual(@"Always", result);
}

- (void) testAuthStatusStringWhenInUse {
    // setup
    CLAuthorizationStatus status = kCLAuthorizationStatusAuthorizedWhenInUse;
    
    // test
    NSString *result = [_locationDelegate authStatusString:status];
    
    // verify
    XCTAssertEqual(@"When in use", result);
}

- (void) testAuthStatusStringDefaultCase {
    // setup
    CLAuthorizationStatus status = (CLAuthorizationStatus)552;
    
    // test
    NSString *result = [_locationDelegate authStatusString:status];
    
    // verify
    XCTAssertEqual(@"Not Determined", result);
}

@end
