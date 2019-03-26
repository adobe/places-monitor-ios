//
//  TestablePlacesMonitorListener.h
//  ACPPlacesMonitor-iOS-unit-tests
//
//  Created by steve benedick on 3/19/19.
//  Copyright © 2019 Adobe Systems Incorporated. All rights reserved.
//

#ifndef TestablePlacesMonitorListener_h
#define TestablePlacesMonitorListener_h

#import "ACPPlacesMonitorListener.h"

@interface ACPPlacesMonitorListener()
- (nullable instancetype) initForTesting: (ACPExtension*_Nonnull) extension;
- (ACPPlacesMonitorInternal*_Nonnull) getParentExtension;
@end

#endif /* TestablePlacesMonitorListener_h */
