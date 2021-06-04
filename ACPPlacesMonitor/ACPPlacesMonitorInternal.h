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
// ACPPlacesMonitorInternal.h
//

#import <ACPCore/ACPExtension.h>
#import <AEPPlaces/AEPPlaces-Swift.h>

NS_ASSUME_NONNULL_BEGIN

@class ACPExtensionEvent, CLLocation, CLRegion;

@interface ACPPlacesMonitorInternal : ACPExtension

#pragma mark - Event Handling
/**
 * @brief Queues and event to be processed by the monitor
 *
 * @param event an ACPExtensionEvent which needs to be queued
 */
- (void) queueEvent: (nonnull ACPExtensionEvent*) event;

/**
 * @brief Indicates to the monitor that it should start processing events
 *
 * @discussion The monitor has some hard requirements, namely configuration of the Places
 * extension, which must be met prior to processing.  Calling this method will kick the processing.
 */
- (void) processEvents;

#pragma mark - Location Settings and State
/**
 * @brief Immediately causing the monitor to stop tracking the device's location and monitoring regions
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
- (void) stopAllMonitoring: (BOOL) clearData;

/**
 * @brief Adds the provided region to a list of regions that the device is currently within
 *
 * @discussion If the provided region is already in the list, calling this method has no effect.
 *
 * @param region A CLRegion object that the device is known to be within
 */
- (void) addDeviceToRegion: (CLRegion*) region;

/**
 * @brief Removes the provided region from a list of regions that the device is currently within
 *
 * @discussion If the provided region is not in the list, calling this method has no effect.
 *
 * @param region a CLRegion object that the device is no longer within
 */
- (void) removeDeviceFromRegion: (CLRegion*) region;

/**
 * @brief Determine if the device is currently within the provided region
 *
 * @param region a CLRegion object representing the region to check if the device is within
 * @return a BOOL indicating whether the device is within the provided region
 */
- (BOOL) deviceIsWithinRegion: (CLRegion*) region;

#pragma mark - Location Updates
/**
 * @brief Makes a request to the ACPPlaces extension to retrieve nearby Points of Interest
 *
 * @discussion Calling this method will result in a request to the Places Query Service to get Points of Interest (POIs)
 * that are near the device's location. Upon receiving a response, it will trigger the following actions:
 *   1. The internal list of monitored geo-fence regions will be reset.
 *   2. If the response contains any Points of Interest, regions will be created and registered with
 *      the CLLocationManager.
 *   3. Any regions that were previously registered with the CLLocationManager but are no longer in the list
 *      of nearby POIs will be unregistered.
 *
 * @param currentLocation a CLLocation object representing the current location of the device
 */
- (void) postLocationUpdate: (CLLocation*) currentLocation;

/**
 * @brief Signals to the ACPPlaces extension that a region monitoring event has occurred
 *
 * @param region the CLRegion for which there was a region event
 * @param type an AEPPlacesRegionEvent representing whether the event was an entry or an exit
 */
- (void) postRegionUpdate: (CLRegion*) region withEventType: (AEPPlacesRegionEvent) type;

/**
 * @brief Initiates a location request from the underlying CLLocationManager
 */
- (void) updateLocationNow;

@end

NS_ASSUME_NONNULL_END
