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
// ACPPlacesMonitorLocationDelegate.h
//

#import <CoreLocation/CoreLocation.h>
#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ACPPlacesMonitorInternal;

/**
 * @class ACPPlacesMonitorLocationDelegate
 *
 * @discussion This class implements all the delegate methods in the CLLocationManagerDelegate protocol.
 *
 * More information about each method can be found in Apple's documentation:
 * https://developer.apple.com/documentation/corelocation/cllocationmanagerdelegate?language=objc
 */
@interface ACPPlacesMonitorLocationDelegate : NSObject <CLLocationManagerDelegate>

@property(nonatomic, strong) ACPPlacesMonitorInternal* parent;

@end

NS_ASSUME_NONNULL_END
