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
// ACPPlacesMonitorTests.m
//

#import <XCTest/XCTest.h>
#import "OCMock.h"
#import <Foundation/Foundation.h>
#import "ACPCore.h"
#import "ACPPlacesMonitor.h"
#import "ACPPlacesMonitorConstantsTests.h"
#import "ACPPlacesMonitorInternal.h"

// expose private methods for testing
@interface ACPPlacesMonitor()
+ (void) dispatchMonitorEvent: (NSString*) eventName withData: (NSDictionary*) eventData;
@end


@interface ACPPlacesMonitorTests : XCTestCase
@property (nonatomic, strong) id monitorMock;
@property (nonatomic, strong) id coreMock;
@end

@implementation ACPPlacesMonitorTests

- (void) setUp {
    _monitorMock = OCMClassMock([ACPPlacesMonitor class]);
    _coreMock = OCMClassMock([ACPCore class]);
}

- (void) testExtensionVersion {
    NSString *result = [ACPPlacesMonitor extensionVersion];
    XCTAssertEqual(ACPPlacesMonitorExtensionVersion_Test, result);
}

- (void) testRegisterExtension {
    // setup
    NSError *error = nil;
    OCMStub([_coreMock registerExtension:[ACPPlacesMonitorInternal class] error:[OCMArg setTo:error]]).andReturn(YES);
    
    // test
    [ACPPlacesMonitor registerExtension];
    

    NSString* expectedLog  =  [NSString stringWithFormat:@"The ACPPlacesMonitor extension was successfully registered. Version : %@",ACPPlacesMonitorExtensionVersion_Test];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelDebug
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:expectedLog]);
}

- (void) testRegisterExtensionFailure {
    // setup
    NSError *error = nil;
    OCMStub([_coreMock registerExtension:[ACPPlacesMonitorInternal class] error:[OCMArg setTo:error]]).andReturn(NO);
    
    // test
    [ACPPlacesMonitor registerExtension];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelError
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"An error occurred while attempting to register the ACPPlacesMonitor extension: unknown error. For more details refer to https://docs.adobe.com/content/help/en/places/using/places-ext-aep-sdks/places-monitor-extension/places-monitor-api-reference.html#registerextension-ios"]);
}

- (void) testSetPlacesMonitorMode {
    // setup
    ACPPlacesMonitorMode mode = ACPPlacesMonitorModeContinuous;
    NSDictionary *testData = @{ACPPlacesMonitorEventDataMonitorMode_Test: @(mode)};
    
    // test
    [ACPPlacesMonitor setPlacesMonitorMode:mode];
    
    // verify
    OCMVerify([_monitorMock dispatchMonitorEvent:ACPPlacesMonitorEventNameUpdateMonitorConfiguration_Test
                                        withData:testData]);
}

- (void) testSetPlacesMonitorModeDualOptions {
    // setup
    ACPPlacesMonitorMode mode = ACPPlacesMonitorModeContinuous | ACPPlacesMonitorModeSignificantChanges;
    NSDictionary *testData = @{ACPPlacesMonitorEventDataMonitorMode_Test: @(mode)};
    
    // test
    [ACPPlacesMonitor setPlacesMonitorMode:mode];
    
    // verify
    OCMVerify([_monitorMock dispatchMonitorEvent:ACPPlacesMonitorEventNameUpdateMonitorConfiguration_Test
                                        withData:testData]);
}

- (void) testSetRequestAuthorizationLevel {
    // setup
    ACPPlacesMonitorRequestAuthorizationLevel authLevel = ACPPlacesMonitorRequestAuthorizationLevelWhenInUse;
    NSDictionary *testData = @{ACPPlacesMonitorEventDataRequestAuthorizationLevel_Test: @(authLevel)};
    
    // test
    [ACPPlacesMonitor setRequestAuthorizationLevel:authLevel];
    
    // verify
    OCMVerify([_monitorMock dispatchMonitorEvent:ACPPlacesMonitorEventNameSetRequestAuthorizationLevel_Test
                                        withData:testData]);
}


- (void) testStart {
    // test
    [ACPPlacesMonitor start];
    
    // verify
    OCMVerify([_monitorMock dispatchMonitorEvent:ACPPlacesMonitorEventNameStart_Test
                                        withData:@{}]);
}

- (void) testStopWithClear {
    // test
    [ACPPlacesMonitor stop:YES];
    
    // verify
    OCMVerify([_monitorMock dispatchMonitorEvent:ACPPlacesMonitorEventNameStop_Test
                                        withData:@{ACPPlacesMonitorEventDataClear_Test: @(YES)}]);
}

- (void) testStopWithoutClear {
    // test
    [ACPPlacesMonitor stop:NO];
    
    // verify
    OCMVerify([_monitorMock dispatchMonitorEvent:ACPPlacesMonitorEventNameStop_Test
                                        withData:@{ACPPlacesMonitorEventDataClear_Test: @(NO)}]);
}

- (void) testUpdateLocationNow {
    // test
    [ACPPlacesMonitor updateLocationNow];
    
    // verify
    OCMVerify([_monitorMock dispatchMonitorEvent:ACPPlacesMonitorEventNameUpdateLocationNow_Test
                                        withData:@{}]);
}

- (void) testDispatchMonitorEventWithData {
    // setup
    NSString *eventName = @"my event name";
    NSDictionary *eventData = @{@"key":@"value"};
    
    // test
    [ACPPlacesMonitor dispatchMonitorEvent:eventName withData:eventData];
    
    // verify
    NSError *error = nil;
    OCMVerify([_coreMock dispatchEvent:[OCMArg checkWithBlock:^BOOL(id obj) {
        ACPExtensionEvent *capturedEvent = (ACPExtensionEvent*)obj;
        XCTAssertTrue([eventName isEqualToString:capturedEvent.eventName]);
        NSDictionary *capturedData = capturedEvent.eventData;
        XCTAssertNotNil(capturedData);
        XCTAssertEqual(1, capturedData.count);
        NSString *value = capturedData[@"key"];
        XCTAssertNotNil(value);
        XCTAssertTrue([@"value" isEqualToString:value]);
        return YES;
    }] error:[OCMArg setTo:error]]);
}

- (void) testDispatchMonitorEventWithDataEventCreationFailed {
    // setup
    NSString *eventName = @"my event name";
    NSDictionary *eventData = @{@"key":@"value"};
    id extensionEventMock = OCMClassMock([ACPExtensionEvent class]);
    ACPExtensionEvent *nilEvent = nil;
    NSError *error = nil;
    OCMStub([extensionEventMock extensionEventWithName:eventName
                                                  type:ACPPlacesMonitorEventTypeMonitor_Test
                                                source:ACPPlacesMonitorEventSourceRequestContent_Test
                                                  data:eventData
                                                 error:[OCMArg setTo:error]]).andReturn(nilEvent);
    
    // test
    [ACPPlacesMonitor dispatchMonitorEvent:eventName withData:eventData];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelWarning
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"An error occurred while creating event 'my event name': unknown error"]);
}

- (void) testDispatchMonitorEventWithDataDispatchFailed {
    // setup
    NSString *eventName = @"my event name";
    NSDictionary *eventData = @{@"key":@"value"};
    NSError *error = nil;
    OCMStub([_coreMock dispatchEvent:[OCMArg any] error:[OCMArg setTo:error]]).andReturn(NO);
    
    // test
    [ACPPlacesMonitor dispatchMonitorEvent:eventName withData:eventData];
    
    // verify
    OCMVerify([_coreMock log:ACPMobileLogLevelWarning
                         tag:ACPPlacesMonitorExtensionName_Test
                     message:@"An error occurred while dispatching event 'my event name': unknown error"]);
}

@end
