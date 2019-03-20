//
//  ViewController.m
//  PlacesDemoApp
//
//  Created by steve benedick on 11/12/18.
//  Copyright © 2018 Adobe Inc. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import "ACPPlaces.h"
#import "ACPPlacesMonitor.h"
#import "ACPUserProfile.h"
#import "ACPCore.h"



@implementation ViewController {
    NSMutableArray *blueOverlayArray;
    BOOL isSettingsHidden;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.manager = [[CLLocationManager alloc] init];
    self.manager.delegate = self;
    blueOverlayArray = [[NSMutableArray alloc] init];
    

    UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc]  initWithTarget:self action:@selector(didSwipe:)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [self.settingsView addGestureRecognizer:swipeUp];
    
    UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(didSwipe:)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [self.settingsView addGestureRecognizer:swipeDown];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    // need a getter for attributes in user profile!!!
    _txtName.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"devicename"];
    
    
}

- (IBAction) updateLocationNow:(id)sender {
    [ACPPlacesMonitor updateLocationNow];
}

- (IBAction) setName:(id)sender {
    [ACPUserProfile updateUserAttribute:@"devicename" withValue:_txtName.text ?: @"you didn't set a device name.  oops."];
    NSLog(@"profile value for devicename updated: %@", _txtName.text);
    [[NSUserDefaults standardUserDefaults] setObject:_txtName.text forKey:@"devicename"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (IBAction) trackAction:(id)sender {
    [ACPCore trackAction:@"anAction" data:nil];
}

- (IBAction) continuous:(id)sender {
    [ACPPlacesMonitor setPlacesMonitorMode:ACPPlacesMonitorModeContinuous];
}

- (IBAction) significant:(id)sender {
    [ACPPlacesMonitor setPlacesMonitorMode:ACPPlacesMonitorModeSignificantChanges];
}

- (IBAction) both:(id)sender {
    [ACPPlacesMonitor setPlacesMonitorMode:ACPPlacesMonitorModeContinuous | ACPPlacesMonitorModeSignificantChanges];
}


- (IBAction)refreshClicked:(id)sender {
    
    // remove all the current POIs from the map
    [_mapView removeAnnotations:_mapView.annotations];
    [_mapView removeOverlays:_mapView.overlays];
    [blueOverlayArray removeAllObjects];
    
    NSString *countString = [NSString stringWithFormat:@"The monitoring count  %lu", (unsigned long)self.manager.monitoredRegions.count];
    NSLog(@"%@",countString);
    
    
    // get last known location
    [ACPPlaces getLastKnownLocation:^(CLLocation *location){
        if (location !=  nil){
            MKPointAnnotation *marker = [[MKPointAnnotation alloc] init];
            marker.coordinate = location.coordinate;
            marker.title = @"Last Known location";
            [self.mapView addAnnotation:marker];
        }
    }];
    
    // get current POI's
    [ACPPlaces getCurrentPointsOfInterest:^(NSArray *userWithinPOIs){
        
        for(CLRegion *eachRegion in self.manager.monitoredRegions) {
            if([eachRegion isKindOfClass:[CLCircularRegion class]]){
                CLCircularRegion *eachCircularRegion = (CLCircularRegion*) eachRegion;
                MKPointAnnotation *marker = [[MKPointAnnotation alloc] init];
                marker.coordinate = eachCircularRegion.center;
                marker.title = eachCircularRegion.identifier;
                MKCircle *poiOverlay = [MKCircle circleWithCenterCoordinate:marker.coordinate radius:eachCircularRegion.radius];
                
                for(ACPPlacesPoi *eachUserWithinPOI in userWithinPOIs) {
                    if ([eachUserWithinPOI.identifier isEqualToString:eachCircularRegion.identifier]){
                        NSString *hashValue = [NSString stringWithFormat:@"%lu",(unsigned long)[poiOverlay hash]];
                        [self->blueOverlayArray addObject:hashValue];
                    }
                }
                
                [self.mapView addOverlay:poiOverlay];
                [self.mapView addAnnotation:marker];
            }
        }
        
    }];
    
    


    [self focusMapToShowAllMarkers];
}

- (void)focusMapToShowAllMarkers {
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in self.mapView.annotations) {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(zoomRect)) {
            zoomRect = pointRect;
        } else {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }
    [self.mapView setVisibleMapRect:zoomRect animated:YES];
}




#pragma mark - MapKit Delegate
-(MKOverlayRenderer *)mapView:(MKMapView *)mapView rendererForOverlay:(id<MKOverlay>)overlay {
    
    if ([overlay isKindOfClass:[MKCircle class]])
    {
        MKCircleRenderer* aRenderer = [[MKCircleRenderer alloc] initWithCircle:(MKCircle *)overlay];
        
        NSString *hashValue = [NSString stringWithFormat:@"%lu",(unsigned long)[overlay hash]];
        if([blueOverlayArray containsObject:hashValue]) {
            aRenderer.strokeColor = [[UIColor blueColor] colorWithAlphaComponent:0.5];
            aRenderer.fillColor = [[UIColor blueColor] colorWithAlphaComponent:0.1];
        }
        else{
            aRenderer.strokeColor = [[UIColor redColor] colorWithAlphaComponent:0.5];
            aRenderer.fillColor = [[UIColor redColor] colorWithAlphaComponent:0.1];
        }
        
        aRenderer.lineWidth = 1;
        
        return aRenderer;
    }else{
        return nil;
    }
}

-(MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    
    if ([annotation.title isEqualToString:@"Last Known location"]){
        NSString *reuseId = @"annotationReuse";
        MKAnnotationView *point = (MKAnnotationView*)[mapView dequeueReusableAnnotationViewWithIdentifier:reuseId];
        if(point == nil){
            point = [[MKAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:reuseId];
        }
        point.canShowCallout = true;
        point.annotation = annotation;
        [point setImage:[UIImage imageNamed:@"currentLocation.png"]];
        return point;
    }
    return nil;
}


- (IBAction)animateClicked:(id)sender {
    isSettingsHidden?[self animateSettingsUp] : [self animateSettingsDown];
}

- (void) animateSettingsUp {
    [UIView animateWithDuration:0.25 animations:^{
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGRect settingsFrame = [self.settingsView frame];
        settingsFrame.origin.y = screenRect.size.height - settingsFrame.size.height;
        [self.settingsView setFrame:settingsFrame];
        self->isSettingsHidden = false;
    }];
}

- (void) animateSettingsDown {
    [UIView animateWithDuration:0.25 animations:^{
        CGRect screenRect = [[UIScreen mainScreen] bounds];
        CGRect settingsFrame = [self.settingsView frame];
        settingsFrame.origin.y = screenRect.size.height - 50;
        [self.settingsView setFrame:settingsFrame];
        self->isSettingsHidden = true;
    }];
    
}


- (void)didSwipe:(UISwipeGestureRecognizer*)swipe{
    
    if (swipe.direction == UISwipeGestureRecognizerDirectionUp) {
        [self animateSettingsUp];
    } else if (swipe.direction == UISwipeGestureRecognizerDirectionDown) {
        [self animateSettingsDown];
    }
}

@end
