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
// ACPPlacesQueue.h
//

#import <Foundation/Foundation.h>

@class ACPExtensionEvent;

@interface ACPPlacesQueue : NSObject

/**
 * @brief Adds an event to the end queue
 *
 * @param event the ACPExtensionEvent to be added to the queue
 */
- (void) add: (nonnull ACPExtensionEvent*) event;

/**
 * @brief Retrieve the event from the top of the queue
 *
 * @return the ACPExtensionEvent that was at the top of the queue or nil if the queue is empty
 */
- (ACPExtensionEvent* _Nonnull) peek;

/**
 * @brief Retrieve the event from the top of the queue and remove it from the queue
 *
 * @return the ACPExtensionEvent that was at the top of the queue or nil if the queue is empty
 */
- (ACPExtensionEvent* _Nonnull) poll;

/**
 * @brief Determine if there is another event in the queue
 *
 * @return a bool indicating whether there is another event in the queue
 */
- (bool) hasNext;

@end
