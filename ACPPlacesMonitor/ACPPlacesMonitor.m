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
// ACPPlacesMonitor.m
//

#import <ACPCore/ACPCore.h>
#import <ACPCore/ACPExtensionEvent.h>
#import "ACPPlacesMonitor.h"
#import "ACPPlacesMonitorConstants.h"
#import "ACPPlacesMonitorInternal.h"

@implementation ACPPlacesMonitor

+ (nonnull NSString*) extensionVersion {
    return ACPPlacesMonitorExtensionVersion;
}

+ (void) registerExtension {
    NSError* error = nil;

    if ([ACPCore registerExtension:[ACPPlacesMonitorInternal class] error:&error]) {
        [ACPCore log:ACPMobileLogLevelDebug
                 tag:ACPPlacesMonitorExtensionName
             message:[NSString stringWithFormat:@"The ACPPlacesMonitor extension was successfully registered. Version : %@",ACPPlacesMonitorExtensionVersion]];
    } else {
        [ACPCore log:ACPMobileLogLevelError
                 tag:ACPPlacesMonitorExtensionName
             message:[NSString stringWithFormat:@"An error occurred while attempting to register the ACPPlacesMonitor extension: %@. For more details refer to %@",
         [error localizedDescription] ? : @"unknown error", ACPPlacesMonitorRegisterExtensionDocs]];
    }
}

+ (void) setPlacesMonitorMode: (ACPPlacesMonitorMode) monitorMode {
    NSDictionary* data = @ {ACPPlacesMonitorEventDataMonitorMode: @(monitorMode)};
    [ACPPlacesMonitor dispatchMonitorEvent:ACPPlacesMonitorEventNameUpdateMonitorConfiguration withData:data];
}

+ (void) setRequestAuthorizationLevel: (ACPPlacesMonitorRequestAuthorizationLevel) requestAuthorizationLevel {
    NSDictionary* data = @ {ACPPlacesMonitorEventDataRequestAuthorizationLevel: @(requestAuthorizationLevel)};
    [ACPPlacesMonitor dispatchMonitorEvent:ACPPlacesMonitorEventNameSetRequestAuthorizationLevel withData:data];
}

+ (void) start {
    [ACPPlacesMonitor dispatchMonitorEvent:ACPPlacesMonitorEventNameStart withData:@ {}];
}

+ (void) stop:(BOOL) clearData {
    [ACPPlacesMonitor dispatchMonitorEvent:ACPPlacesMonitorEventNameStop withData:@ {
        ACPPlacesMonitorEventDataClear : @(clearData)
    }];
}

+ (void) updateLocationNow {
    [ACPPlacesMonitor dispatchMonitorEvent:ACPPlacesMonitorEventNameUpdateLocationNow withData:@ {}];
}

#pragma mark - private methods
+ (void) dispatchMonitorEvent: (NSString*) eventName withData: (NSDictionary*) eventData {
    NSError* eventCreationError = nil;
    ACPExtensionEvent* event = [ACPExtensionEvent extensionEventWithName:eventName
                                                                    type:ACPPlacesMonitorEventTypeMonitor
                                                                  source:ACPPlacesMonitorEventSourceRequestContent
                                                                    data:eventData
                                                                   error:&eventCreationError];

    if (!event) {
        [ACPCore log:ACPMobileLogLevelWarning
                 tag:ACPPlacesMonitorExtensionName
             message:[NSString stringWithFormat:@"An error occurred while creating event '%@': %@", eventName,
         [eventCreationError localizedDescription] ? : @"unknown error"]];
        return;
    }

    NSError* dispatchError = nil;

    if (![ACPCore dispatchEvent:event error:&dispatchError]) {
        [ACPCore log:ACPMobileLogLevelWarning
                 tag:ACPPlacesMonitorExtensionName
             message:[NSString stringWithFormat:@"An error occurred while dispatching event '%@': %@", eventName,
         [dispatchError localizedDescription] ? : @"unknown error"]];
    }
}

@end
