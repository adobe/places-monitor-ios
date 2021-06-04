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
// ACPPlacesMonitorConstants.m
//

#import "ACPPlacesMonitorConstants.h"

#pragma mark - Monitor Properties
NSString* const ACPPlacesMonitorExtensionVersion = @"2.1.4";
NSString* const ACPPlacesMonitorExtensionName = @"com.adobe.placesMonitor";
int const ACPPlacesMonitorDefaultMaxMonitoredRegionCount = 20;

NSString* const ACPPlacesMonitorDefaultsMonitoredRegions = @"acpplacesmonitor.monitoredregions";
NSString* const ACPPlacesMonitorDefaultsUserWithinRegions = @"acpplacesmonitor.userwithinregions";
NSString* const ACPPlacesMonitorDefaultsMonitorMode = @"acpplacesmonitor.monitormode";
NSString* const ACPPlacesMonitorDefaultsRequestAuthorizationLevel = @"acpplacesmonitor.requestauthorizationlevel";
NSString* const ACPPlacesMonitorDefaultsIsMonitoringStarted = @"acpplacesmonitor.ismonitoringstarted";

#pragma mark - Event Data Keys
// event sources
NSString* const ACPPlacesMonitorEventSourceResponseContent = @"com.adobe.eventSource.responseContent";
NSString* const ACPPlacesMonitorEventSourceRequestContent = @"com.adobe.eventSource.requestContent";
NSString* const ACPPlacesMonitorEventSourceSharedState = @"com.adobe.eventSource.sharedState";;

// event types
NSString* const ACPPlacesMonitorEventTypeHub = @"com.adobe.eventType.hub";
NSString* const ACPPlacesMonitorEventTypeMonitor = @"com.adobe.eventType.placesMonitor";
NSString* const ACPPlacesMonitorEventTypePlaces = @"com.adobe.eventType.places";
NSString* const ACPPlacesMonitorEventTypeRules = @"com.adobe.eventType.rulesEngine";

// shared state
NSString* const ACPPlacesMonitorStateOwner = @"stateowner";

// configuration
NSString* const ACPPlacesMonitorConfigurationSharedState = @"com.adobe.module.configuration";

// places
NSString* const ACPPlacesMonitorPlacesSharedState = @"com.adobe.module.places";

// rules
NSString* const ACPPlacesMonitorRulesTriggeredConsequence = @"triggeredconsequence";
NSString* const ACPPlacesMonitorRulesConsequenceType = @"type";
NSString* const ACPPlacesMonitorRulesConsequenceDetail = @"detail";

// places monitor event name
NSString* const ACPPlacesMonitorEventNameStart = @"start monitoring";
NSString* const ACPPlacesMonitorEventNameStop = @"stop monitoring";
NSString* const ACPPlacesMonitorEventNameUpdateLocationNow = @"update location now";
NSString* const ACPPlacesMonitorEventNameUpdateMonitorConfiguration = @"update monitor configuration";
NSString* const ACPPlacesMonitorEventNameSetRequestAuthorizationLevel = @"set request authorization level";

// places monitor event data keys
NSString* const ACPPlacesMonitorEventDataMonitorMode = @"monitormode";
NSString* const ACPPlacesMonitorEventDataRequestAuthorizationLevel = @"requestauthorizationlevel";
NSString* const ACPPlacesMonitorEventDataClear = @"clearclientdata";

// places documentation Links
NSString* const ACPPlacesMonitorRegisterExtensionDocs = @"https://docs.adobe.com/content/help/en/places/using/places-ext-aep-sdks/places-monitor-extension/places-monitor-api-reference.html#registerextension-ios";
NSString* const ACPPlacesMonitorBackgroundLocationUpdatesDocs = @"https://docs.adobe.com/help/en/places/using/places-ext-aep-sdks/places-monitor-extension/using-places-monitor-extension.html#enable-location-updates-background";
NSString* const ACPPlacesMonitorConfigurePlistDocs = @"https://docs.adobe.com/content/help/en/places/using/places-ext-aep-sdks/places-monitor-extension/using-places-monitor-extension.html#configuring-the-plist-keys";
