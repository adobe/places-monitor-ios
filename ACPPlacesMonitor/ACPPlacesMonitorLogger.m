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
// ACPPlacesMonitorLogger.m
//

#import "ACPPlacesMonitorLogger.h"

static BOOL ACPDebugLogging = NO;
void ACPPlacesMonitorSetDebugLogging(BOOL enabled) {
    ACPDebugLogging = enabled;
}

BOOL ACPPlacesMonitorGetDebugLogging() {
    return ACPDebugLogging;
}

void ACPPlacesMonitorLogError(NSString* format, ...) {
    va_list argList;
    va_start(argList, format);
    NSString* formattedMessage = [[NSString alloc] initWithFormat:format arguments:argList];
    NSLog(@"ACPPlacesMonitor <<Error>> : %@", formattedMessage);
    va_end(argList);
}

// log warning message, only logs when debug enabled
// this will be used to warn the user when something unexpected occured
void ACPPlacesMonitorLogWarning(NSString* format, ...) {
    if (ACPPlacesMonitorGetDebugLogging()) {
        va_list argList;
        va_start(argList, format);
        NSString* formattedMessage = [[NSString alloc] initWithFormat:format arguments:argList];
        NSLog(@"ACPPlacesMonitor <<Warning>> : %@", formattedMessage);
        va_end(argList);
    }
}

// log debug message, only logs when debug enabled
// this will be used to inform the user of whats happening (ex. attempting to send hit)
void ACPPlacesMonitorLogDebug(NSString* format, ...) {
    if (ACPPlacesMonitorGetDebugLogging()) {
        va_list argList;
        va_start(argList, format);
        NSString* formattedMessage = [[NSString alloc] initWithFormat:format arguments:argList];
        NSLog(@"ACPPlacesMonitor <<Debug>> : %@", formattedMessage);
        va_end(argList);
    }
}
