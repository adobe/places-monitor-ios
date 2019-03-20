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
#import "ACPPlacesMonitorInternal.h"
#import "ACPPlaces.h"

// private methods exposed for testing
@interface ACPPlacesMonitorInternalTests : XCTestCase

@property (nonatomic, strong) ACPPlacesMonitorInternal* monitor;
@property (nonatomic, strong) id placesMock;

@end

@implementation ACPPlacesMonitorInternalTests

- (void) setUp {
    _monitor = [[ACPPlacesMonitorInternal alloc] init];
    _placesMock = OCMClassMock([ACPPlaces class]);
}

- (void) tearDown {
    
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
