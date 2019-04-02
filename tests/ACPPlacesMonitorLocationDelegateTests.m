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

@interface ACPPlacesMonitorLocationDelegateTests : XCTestCase
@property (nonatomic, strong) ACPPlacesMonitorLocationDelegate *locationDelegate;
@property (nonatomic, strong) id placesMock;
@property (nonatomic, strong) id coreMock;
@property (nonatomic, strong) CLLocationManager *manager;
@property (nonatomic, strong) CLLocation *fakeLocation;
@property (nonatomic, strong) CLRegion *fakeRegion;
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
    OCMVerify([_placesMock stopAllMonitoring]);
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:[OCMArg any]]);
}

@end
