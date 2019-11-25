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
// ACPPlacesMonitorListener.m
//

#import <ACPCore/ACPCore.h>
#import "ACPPlacesMonitorConstants.h"
#import "ACPPlacesMonitorInternal.h"
#import "ACPPlacesMonitorListener.h"

@implementation ACPPlacesMonitorListener

#ifdef ACP_TESTING
#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"
#pragma GCC diagnostic ignored "-Wundeclared-selector"
- (nullable instancetype) initForTesting: (ACPExtension*) extension {
    SEL constructor = @selector(initWithExtension:);

    if ([super respondsToSelector:constructor]) {
        self = [super performSelector:constructor withObject:extension];
    }

    return self;
}
#pragma GCC diagnostic pop
#endif

/**
 * @brief Called when the AEP EventHub processes an Event for which the ACPPlacesMonitor is listening
 *
 * @param event the ACPExtensionEvent processed by the AEP SDK's EventHub
 */
- (void) hear: (ACPExtensionEvent*) event {
    ACPPlacesMonitorInternal* parentExtension = [self getParentExtension];

    if (parentExtension == nil) {
        [ACPCore log:ACPMobileLogLevelError
                 tag:ACPPlacesMonitorExtensionName
             message:[NSString stringWithFormat:@"The parent extension is nil, unable to process the event: %@", event.eventName]];
        return;
    }
    
    [ACPCore log:ACPMobileLogLevelVerbose
             tag:ACPPlacesMonitorExtensionName
         message:[NSString stringWithFormat:@"ACPPlacesMonitor heard event '%@' (type:%@ - source:%@)", event.eventName, event.eventType, event.eventSource]];

    // handle SharedState events
    if ([event.eventType isEqualToString:ACPPlacesMonitorEventTypeHub] && [event.eventSource isEqualToString:ACPPlacesMonitorEventSourceSharedState]) {
        // only concerned with configuration changes at this point
        if ([event.eventData[ACPPlacesMonitorStateOwner] isEqualToString:ACPPlacesMonitorConfigurationSharedState]) {
            [parentExtension processEvents];
        }
    }

    // handle Places Extension response events
    else if ([event.eventType isEqualToString:ACPPlacesMonitorEventTypePlaces] && [event.eventSource isEqualToString:ACPPlacesMonitorEventSourceResponseContent]) {
        [parentExtension queueEvent:event];
        [parentExtension processEvents];
    }

    // handle Places Monitor events
    else if ([event.eventType isEqualToString:ACPPlacesMonitorEventTypeMonitor] && [event.eventSource isEqualToString:ACPPlacesMonitorEventSourceRequestContent]) {
        [parentExtension queueEvent:event];
        [parentExtension processEvents];
    }
}

/**
 * @brief Returns the parent extension that owns this listener
 *
 * @return an ACPPlacesMonitorInternal object that owns this listener
 */
- (ACPPlacesMonitorInternal*) getParentExtension {
    ACPPlacesMonitorInternal* parentExtension = nil;

    if ([[self extension] isKindOfClass:ACPPlacesMonitorInternal.class]) {
        parentExtension = (ACPPlacesMonitorInternal*) [self extension];
    }

    return parentExtension;
}

@end
