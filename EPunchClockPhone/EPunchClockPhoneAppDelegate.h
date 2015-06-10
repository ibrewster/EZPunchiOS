//
//  EPunchClockPhoneAppDelegate.h
//  EPunchClockPhone
//
//  Created by Macavenger on 4/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"
#import <CoreLocation/CoreLocation.h>


@interface EPunchClockPhoneAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, UINavigationControllerDelegate, CLLocationManagerDelegate> {
	Utilities *util;
	BOOL pushedController;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;
@property (nonatomic, retain) CLLocationManager *locationManager;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;
@property (nonatomic, retain) NSString *deviceLocation;


-(IBAction)submitLogin:(id)sender withUser:(NSString *)user;

@end
