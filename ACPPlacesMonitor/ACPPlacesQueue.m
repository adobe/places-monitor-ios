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
// ACPPlacesQueue.m
//

#import "ACPExtensionEvent.h"
#import "ACPPlacesQueue.h"

@interface ACPPlacesQueue()
@property(nonatomic, strong) NSMutableArray* queuedEvents;
@end

@implementation ACPPlacesQueue

- (instancetype) init {
    if (self = [super init]) {
        self.queuedEvents = [[NSMutableArray alloc] init];
    }

    return self;
}

- (void) add: (ACPExtensionEvent*) event {
    [_queuedEvents addObject:event];
}

- (ACPExtensionEvent*) poll {
    id headObject = [self peek];

    if (headObject != nil) {
        [_queuedEvents removeObjectAtIndex:0];
    }

    return headObject;
}

- (ACPExtensionEvent*) peek {
    return [self hasNext] ? [_queuedEvents objectAtIndex:0] : nil;
}

- (bool) hasNext {
    return _queuedEvents.count;
}

@end
