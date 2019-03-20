//
//  ViewController.h
//  PlacesDemoApp
//
//  Created by steve benedick on 11/12/18.
//  Copyright © 2018 Adobe Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>

@interface ViewController : UIViewController <MKMapViewDelegate, CLLocationManagerDelegate>

@property (nonatomic, assign) IBOutlet UITextField *txtName;
@property (nonatomic, assign) IBOutlet MKMapView *mapView;
@property (nonatomic, retain) CLLocationManager *manager;
@property (weak, nonatomic) IBOutlet UIView *settingsView;

@end

