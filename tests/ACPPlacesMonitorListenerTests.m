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
// ACPPlacesMonitorListenerTests.m
//

#import <XCTest/XCTest.h>
#import "OCMock.h"
#import <Foundation/Foundation.h>
#import "ACPPlacesMonitorInternal.h"
#import "ACPPlacesMonitorListener.h"
#import "ACPPlacesMonitorConstantsTests.h"
#import "TestablePlacesMonitorListener.h"


@interface ACPPlacesMonitorListenerTests : XCTestCase

@property (nonatomic, strong) ACPPlacesMonitorListener* listener;
@property (nonatomic, strong) id parentMock;
@property (nonatomic) int counterProcessEventsCalled;
@property (nonatomic) int counterQueueEventCalled;

@end

@implementation ACPPlacesMonitorListenerTests

- (void) setUp {
    _counterProcessEventsCalled = 0;
    _counterQueueEventCalled = 0;
    _parentMock = OCMClassMock([ACPPlacesMonitorInternal class]);
    OCMStub([_parentMock processEvents]).andDo(^(NSInvocation*) {
        self.counterProcessEventsCalled++;
    });
    OCMStub([_parentMock queueEvent:[OCMArg any]]).andDo(^(NSInvocation*) {
        self.counterQueueEventCalled++;
    });
    
    _listener = [[ACPPlacesMonitorListener alloc] initForTesting:_parentMock];
}

- (void) tearDown {
    
}

- (void) testListenerShouldInitializeProperly {
    XCTAssertNotNil(_listener, @"listener should not be nil");
}

- (void) testHearEventWithEmptyType {
    // setup
    NSError* error;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:@"test"
                                                                    type:@""
                                                                  source:ACPPlacesMonitorEventSourceSharedState_Test
                                                                    data:@ {}
                                                                   error: &error];
    
    // execute
    [_listener hear:event];
    
    // verify
    XCTAssertEqual(0, _counterProcessEventsCalled, @"processEvents was unexpectedly called");
    XCTAssertEqual(0, _counterQueueEventCalled, @"queueEvent was unexpectedly called");
}

- (void) testHearEventWithEmptySource {
    // setup
    NSError* error;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:@"test"
                                                                    type:ACPPlacesMonitorEventTypeHub_Test
                                                                  source:@""
                                                                    data:@ {}
                                                                   error: &error];
    
    // execute
    [_listener hear:event];
    
    // verify
    XCTAssertEqual(0, _counterProcessEventsCalled);
    XCTAssertEqual(0, _counterQueueEventCalled);
}

- (void) testHearSharedStateEventWithNoOwner {
    // setup
    NSError* error;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:@"test"
                                                                    type:ACPPlacesMonitorEventTypeHub_Test
                                                                  source:ACPPlacesMonitorEventSourceSharedState_Test
                                                                    data:@ {}
                                                                   error: &error];
    
    // execute
    [_listener hear:event];
    
    // verify
    XCTAssertEqual(0, _counterProcessEventsCalled);
    XCTAssertEqual(0, _counterQueueEventCalled);
}

- (void) testSharedStateEventHappyPath {
    // setup
    NSError* error;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:@"test"
                                                                    type:ACPPlacesMonitorEventTypeHub_Test
                                                                  source:ACPPlacesMonitorEventSourceSharedState_Test
                                                                    data:@ {ACPPlacesMonitorStateOwner_Test:ACPPlacesMonitorConfigurationSharedState_Test}
                                                                   error: &error];
    
    // execute
    [_listener hear:event];
    
    // verify
    XCTAssertEqual(1, _counterProcessEventsCalled);
    XCTAssertEqual(0, _counterQueueEventCalled);
}

- (void) testPlacesResponseContentEventHappy {
    // setup
    NSError* error;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:@"test"
                                                                    type:ACPPlacesMonitorEventTypePlaces_Test
                                                                  source:ACPPlacesMonitorEventSourceResponseContent_Test
                                                                    data:@ {}
                                                                   error: &error];
    
    // execute
    [_listener hear:event];
    
    // verify
    XCTAssertEqual(1, _counterProcessEventsCalled);
    XCTAssertEqual(1, _counterQueueEventCalled);
}

- (void) testGetParentExtensionHappy {
    XCTAssertEqual(_parentMock, [_listener getParentExtension]);
}

@end
