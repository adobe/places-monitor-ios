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
// ACPPlacesMonitor.h
// Places Monitor Version: 2.1.3
//

#import <Foundation/Foundation.h>

/**
 * @brief An enum type representing different ways to monitor the user's location
 *
 * @discussion Location monitoring in iOS can be done with multiple strategies:
 *  - continuous (ACPPlacesMonitorModeContinuous) - the monitor will receive and process location updates once per second.
 *    Using this monitoring strategy consumes a lot power. For more information, see:
 *    https://developer.apple.com/documentation/corelocation/cllocationmanager/1423750-startupdatinglocation
 *  - significant changes (ACPPlacesMonitorModeSignificantChanges) - the monitor will only receive and process location
 *    updates when the device has moved a significant distance from the last time its location was processed.
 *    Using this monitoring strategy consumes far less power than continuous monitoring.  For more information, see:
 *    https://developer.apple.com/documentation/corelocation/cllocationmanager/1423531-startmonitoringsignificantlocati
 */
typedef NS_OPTIONS(NSInteger, ACPPlacesMonitorMode) {
    ACPPlacesMonitorModeContinuous = 1 << 0,           /*!< Enum value ACPPlacesMonitorModeContinuous */
    ACPPlacesMonitorModeSignificantChanges = 1 << 1    /*!< Enum value ACPPlacesMonitorModeSignificantChanges */
};

/**
 * @brief An enum indicating application's authorization to use location services
 * @discussion
 * - WhenInUse (ACPPlacesRequestAuthorizationLevelWhenInUse) : Requests the user’s permission to use location
 *   services while the app is in use. The user prompt contains the text from the NSLocationWhenInUseUsageDescription
 *   key in your app Info.plist file, and the presence of that key is required when calling this method. For more information
 *   see : https://developer.apple.com/documentation/corelocation/cllocationmanager/1620562-requestwheninuseauthorization
 * - Always (ACPPlacesRequestAuthorizationLevelAlways) : Use this enum to request for user permission to use location services
 *   whether or not the app is in use. You must have NSLocationAlwaysUsageDescription and NSLocationWhenInUseUsageDescription
 *   keys in your app’s Info.plist file definining the text that will appear during the user prompt.
 *   see : https://developer.apple.com/documentation/corelocation/cllocationmanager/1620551-requestalwaysauthorization
*/
typedef NS_OPTIONS(NSInteger, ACPPlacesMonitorRequestAuthorizationLevel) {
    ACPPlacesMonitorRequestAuthorizationLevelWhenInUse = 1 << 0,           /*!< Enum value ACPPlacesMonitorRequestAuthorizationLevelWhenInUse */
    ACPPlacesRequestMonitorAuthorizationLevelAlways = 1 << 1    /*!< Enum value ACPPlacesRequestMonitorAuthorizationLevelAlways */
};


/**
 * @class ACPPlacesMonitor
 *
 * The ACPPlacesMonitor handles OS-level management of tracking the user's location and region monitoring.  It works
 * in conjunction with the ACPPlaces extension in the Adobe Experience Platform SDK:
 * https://github.com/Adobe-Marketing-Cloud/acp-sdks
 *
 * If you are doing background location monitoring in your app, you will need to enable the application's capability to
 * update locations while the app is in the background.  More information can be found here:
 * https://developer.apple.com/documentation/corelocation/getting_the_user_s_location/handling_location_events_in_the_background?language=objc
 *
 * Before iOS will ask the user for permission to use GPS capabilities, you must provide a description of why your app
 * requires device location.  The description should be entered in your Info.plist file.  More information found here:
 * https://developer.apple.com/documentation/corelocation/choosing_the_authorization_level_for_location_services/requesting_always_authorization?language=objc
 *
 */
@interface ACPPlacesMonitor : NSObject {}

/**
 * @brief Returns the current version of the ACPPlacesMonitor Extension
 */
+ (nonnull NSString*) extensionVersion;

/**
 * @brief Registers the ACPPlacesMonitor extension with the Core Event Hub
 */
+ (void) registerExtension;

/**
 * @brief Set the monitoring mode for the user
 *
 * @discussion Calling this method while actively monitoring the user's location will cause the currently used
 * monitoring strategy to be updated immediately.
 *
 * The value provided in monitoringMode will be persisted to NSUserDefaults for use cross-session.
 *
 * @param monitorMode an ACPPlacesMonitorMode value indicating how the Places Monitor should track the user's location.
 */
+ (void) setPlacesMonitorMode: (ACPPlacesMonitorMode) monitorMode;

/**
* @brief This API sets the type of location authorization request, for which the user will be prompted for [ACPPlacesMonitor start].
*
* @discussion To set the appropriate authorization prompt to be shown to the user, call this API before the [ACPPlacesMonitor start].
* Calling this method while actively monitoring will upgrade the location authorization level to the requested authorization value.
* If the requested authorization level is either already provided or denied by the application user or when there is a downgrade of permission
* from ACPPlacesRequestAuthorizationLevelAlways to ACPPlacesRequestAuthorizationLevelWhenInUse authorization, this method has no effect.
*
* The value provided in requestAuthorizationLevel will be persisted to NSUserDefaults for cross-session usage.
* Important: Your app must be in the foreground to show a location authorization prompt.
*
* @param requestAuthorizationLevel an ACPPlacesRequestAuthorizationLevel value
*/
+ (void) setRequestAuthorizationLevel: (ACPPlacesMonitorRequestAuthorizationLevel) requestAuthorizationLevel;

/**
 * @brief Start tracking the device's location and monitoring their nearby Places
 *
 * @discussion When called, the Places Monitor will do the following:
 * 1. If the user has not yet been asked for authorization to use GPS, the OS will ask them.
 * 2. If available (based on device capabilities), the Places Monitor will begin tracking the user's location
 *    based on the currently set ACPPlacesMonitorMode.  By default, the monitor will use:
 *    ACPPlacesMonitorModeSignificantChanges.
 *
 * This method should be called as soon as the application needs access to the device's location. If access is needed
 * immediately as the app is launching, call this method from the callback provided as a parameter to the "start"
 * method in the ACPCore class.
 */
+ (void) start;

/**
 * @brief Stop tracking the device's location
 *
 * @discussion Calling this method will stop tracking the customer's location.  Additionally, it will unregister
 * all previously registered regions.  Optionally, you may purge client-side data by passing in YES for the clearData
 * parameter.
 *
 * Calling this method with YES for clearData will purge the data even if the monitor is not actively tracking
 * the device's location.
 *
 * @param clearData pass YES to clear all client-side Places data from the device.
 */
+ (void) stop: (BOOL) clearData;

/**
 * @brief Immediately gets an update for the device's location
 */
+ (void) updateLocationNow;

@end
