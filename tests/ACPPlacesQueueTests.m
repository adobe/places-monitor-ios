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
// ACPPlacesQueueTests.m
//

#import <XCTest/XCTest.h>
#import "OCMock.h"
#import <Foundation/Foundation.h>
#import "ACPExtensionEvent.h"
#import "ACPPlacesQueue.h"


// expose private members for testing
@interface ACPPlacesQueue()
@property(nonatomic, strong) NSMutableArray* queuedEvents;
@end


@interface ACPPlacesQueueTests : XCTestCase
@property (nonatomic, strong) ACPPlacesQueue *queue;
@property (nonatomic, strong) ACPExtensionEvent *event;
@end

@implementation ACPPlacesQueueTests

- (void) setUp {
    _queue = [[ACPPlacesQueue alloc] init];
    _event = [ACPExtensionEvent extensionEventWithName:@"name" type:@"type" source:@"source" data:nil error:nil];
}

- (void) testInit {
    XCTAssertNotNil(_queue);
    XCTAssertNotNil(_queue.queuedEvents);
}

- (void) testAdd {
    XCTAssertEqual(0, _queue.queuedEvents.count);
    [_queue add:_event];
    XCTAssertEqual(1, _queue.queuedEvents.count);
}

- (void) testAddNilEventParameter {
    XCTAssertEqual(0, _queue.queuedEvents.count);
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
    [_queue add:nil];
#pragma clang diagnostic pop
    XCTAssertEqual(0, _queue.queuedEvents.count);
}

- (void) testPoll {
    // setup
    [_queue.queuedEvents addObject:_event];
    
    // test
    ACPExtensionEvent *result = [_queue poll];
    
    // verify
    XCTAssertEqual(_event, result);
    XCTAssertEqual(0, _queue.queuedEvents.count);
}

- (void) testPollWithEmptyQueue {
    // test
    ACPExtensionEvent *result = [_queue poll];
    
    // verify
    XCTAssertNil(result);
    XCTAssertEqual(0, _queue.queuedEvents.count);
}

- (void) testPeek {
    // setup
    [_queue.queuedEvents addObject:_event];
    
    // test
    ACPExtensionEvent *result = [_queue peek];
    
    // verify
    XCTAssertEqual(_event, result);
    XCTAssertEqual(1, _queue.queuedEvents.count);
}

- (void) testPeekWithEmptyQueue {
    // test
    ACPExtensionEvent *result = [_queue peek];
    
    // verify
    XCTAssertNil(result);
    XCTAssertEqual(0, _queue.queuedEvents.count);
}

- (void) testHasNext {
    // setup
    [_queue.queuedEvents addObject:_event];
    
    // test
    bool result = [_queue hasNext];
    
    // verify
    XCTAssertTrue(result);
}

- (void) testHasNextEmptyQueue {
    // test
    bool result = [_queue hasNext];
    
    // verify
    XCTAssertFalse(result);
}

- (void) testHasNextNilQueue {
    // setup
    _queue.queuedEvents = nil;
    
    // test
    bool result = [_queue hasNext];
    
    // verify
    XCTAssertFalse(result);
}

@end
