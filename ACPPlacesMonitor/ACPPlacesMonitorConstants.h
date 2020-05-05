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
// ACPPlacesMonitorConstants.h
//

#import <Foundation/Foundation.h>

#pragma mark - Monitor Properties
// extension
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorExtensionVersion;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorExtensionName;
FOUNDATION_EXPORT int const ACPPlacesMonitorDefaultMaxMonitoredRegionCount;

// persistance
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorDefaultsMonitoredRegions;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorDefaultsUserWithinRegions;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorDefaultsMonitorMode;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorDefaultsRequestAuthorizationLevel;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorDefaultsIsMonitoringStarted;

#pragma mark - Event Data Keys
// event sources
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventSourceResponseContent;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventSourceRequestContent;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventSourceSharedState;

// event types
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventTypeHub;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventTypeMonitor;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventTypePlaces;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventTypeRules;

// shared state
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorStateOwner;

// configuration
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorConfigurationSharedState;

// places
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorPlacesSharedState;

// rules
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorRulesTriggeredConsequence;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorRulesConsequenceType;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorRulesConsequenceDetail;

// places monitor event names
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventNameStart;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventNameStop;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventNameUpdateLocationNow;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventNameUpdateMonitorConfiguration;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventNameSetRequestAuthorizationLevel;


// places monitor event data keys
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventDataMonitorMode;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventDataRequestAuthorizationLevel;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorEventDataClear;

// places documentation Links
#pragma mark - Places Documentation Links
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorRegisterExtensionDocs;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorBackgroundLocationUpdatesDocs;
FOUNDATION_EXPORT NSString* const ACPPlacesMonitorConfigurePlistDocs;

#pragma mark - capability definitions by platform

#if TARGET_OS_SIMULATOR && ADBLOCATIONTESTING
#define BEACONS_SUPPORTED                                   1
#define GEOFENCES_SUPPORTED                                 1
#define CONTINUOUS_LOCATION_SUPPORTED                       1
#define SIGNIFICANT_LOCATION_CHANGE_MONITORING_SUPPORTED    0
#define ALWAYS_AUTHORIZATION_SUPPORTED                      1

#elif TARGET_OS_IOS
#define BEACONS_SUPPORTED                                   1
#define GEOFENCES_SUPPORTED                                 1
#define CONTINUOUS_LOCATION_SUPPORTED                       1
#define SIGNIFICANT_LOCATION_CHANGE_MONITORING_SUPPORTED    1
#define ALWAYS_AUTHORIZATION_SUPPORTED                      1

#elif TARGET_OS_WATCH
#define BEACONS_SUPPORTED                                   0
#define GEOFENCES_SUPPORTED                                 0
#define CONTINUOUS_LOCATION_SUPPORTED                       1
#define SIGNIFICANT_LOCATION_CHANGE_MONITORING_SUPPORTED    0
#define ALWAYS_AUTHORIZATION_SUPPORTED                      1

#elif TARGET_OS_TV
#define BEACONS_SUPPORTED                                   0
#define GEOFENCES_SUPPORTED                                 0
#define CONTINUOUS_LOCATION_SUPPORTED                       0
#define SIGNIFICANT_LOCATION_CHANGE_MONITORING_SUPPORTED    0
#define ALWAYS_AUTHORIZATION_SUPPORTED                      0
#endif
