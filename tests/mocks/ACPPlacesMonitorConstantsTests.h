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
// ACPPlacesMonitorConstantsTests.h
//

#ifndef ACPPlacesMonitorConstantsTests_h
#define ACPPlacesMonitorConstantsTests_h

#pragma mark - Monitor Properties
static NSString* const ACPPlacesMonitorExtensionVersion_Test = @"2.1.4";
static NSString* const ACPPlacesMonitorExtensionName_Test = @"com.adobe.placesMonitor";
static int const ACPPlacesMonitorDefaultMaxMonitoredRegionCount_Test = 20;

static NSString* const ACPPlacesMonitorDefaultsMonitoredRegions_Test = @"acpplacesmonitor.monitoredregions";
static NSString* const ACPPlacesMonitorDefaultsUserWithinRegions_Test = @"acpplacesmonitor.userwithinregions";
static NSString* const ACPPlacesMonitorDefaultsMonitorMode_Test = @"acpplacesmonitor.monitormode";
static NSString* const ACPPlacesMonitorDefaultsRequestAuthorizationLevel_Test = @"acpplacesmonitor.requestauthorizationlevel";
static NSString* const ACPPlacesMonitorDefaultsIsMonitoringStarted_Test = @"acpplacesmonitor.ismonitoringstarted";

#pragma mark - Event Data Keys
// event sources
static NSString* const ACPPlacesMonitorEventSourceResponseContent_Test = @"com.adobe.eventSource.responseContent";
static NSString* const ACPPlacesMonitorEventSourceRequestContent_Test = @"com.adobe.eventSource.requestContent";
static NSString* const ACPPlacesMonitorEventSourceSharedState_Test = @"com.adobe.eventSource.sharedState";;

// event types
static NSString* const ACPPlacesMonitorEventTypeHub_Test = @"com.adobe.eventType.hub";
static NSString* const ACPPlacesMonitorEventTypeMonitor_Test = @"com.adobe.eventType.placesMonitor";
static NSString* const ACPPlacesMonitorEventTypePlaces_Test = @"com.adobe.eventType.places";
static NSString* const ACPPlacesMonitorEventTypeRules_Test = @"com.adobe.eventType.rulesEngine";

// shared state
static NSString* const ACPPlacesMonitorStateOwner_Test = @"stateowner";

// configuration
static NSString* const ACPPlacesMonitorConfigurationSharedState_Test = @"com.adobe.module.configuration";

// places
static NSString* const ACPPlacesMonitorPlacesSharedState_Test = @"com.adobe.module.places";

// rules
static NSString* const ACPPlacesMonitorRulesTriggeredConsequence_Test = @"triggeredconsequence";
static NSString* const ACPPlacesMonitorRulesConsequenceType_Test = @"type";
static NSString* const ACPPlacesMonitorRulesConsequenceDetail_Test = @"detail";

// places monitor
static NSString* const ACPPlacesMonitorEventNameStart_Test = @"start monitoring";
static NSString* const ACPPlacesMonitorEventNameStop_Test = @"stop monitoring";
static NSString* const ACPPlacesMonitorEventNameUpdateLocationNow_Test = @"update location now";
static NSString* const ACPPlacesMonitorEventNameUpdateMonitorConfiguration_Test = @"update monitor configuration";
static NSString* const ACPPlacesMonitorEventNameSetRequestAuthorizationLevel_Test = @"set request authorization level";

static NSString* const ACPPlacesMonitorEventDataMonitorMode_Test = @"monitormode";
static NSString* const ACPPlacesMonitorEventDataClear_Test = @"clearclientdata";
static NSString* const ACPPlacesMonitorEventDataRequestAuthorizationLevel_Test = @"requestauthorizationlevel";

#endif /* ACPPlacesMonitorConstantsTests_h */
