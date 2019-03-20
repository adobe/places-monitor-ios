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

#import "ACPExtension.h"
#import "ACPPlacesMonitorConstants.h"
#import "ACPPlaces.h"

NS_ASSUME_NONNULL_BEGIN

@class ACPExtensionEvent, CLLocation, CLRegion;

@interface ACPPlacesMonitorInternal : ACPExtension

    // event handling
- (void) queueEvent: (ACPExtensionEvent*) event;
- (void) processEvents;

// location configuration
- (void) stopAllMonitoring;
- (void) addDeviceToRegion: (CLRegion*) region;
- (void) removeDeviceFromRegion: (CLRegion*) region;
- (BOOL) deviceIsWithinRegion: (CLRegion*) region;


// location updates
- (void) updateLocationNow;
- (void) postLocationUpdate: (CLLocation*) currentLocation;
- (void) postRegionUpdate: (CLRegion*) region withEventType: (ACPRegionEventType) type;


@end

NS_ASSUME_NONNULL_END
