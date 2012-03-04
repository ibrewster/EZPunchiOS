//
//  EPunchClockPhoneAppDelegate.h
//  EPunchClockPhone
//
//  Created by Macavenger on 4/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"

@interface EPunchClockPhoneAppDelegate : NSObject <UIApplicationDelegate, UITabBarControllerDelegate, UINavigationControllerDelegate> {
	Utilities *util;
}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet UINavigationController *navigationController;
@property (nonatomic, retain) IBOutlet UITabBarController *tabBarController;

-(IBAction)submitLogin:(id)sender withUser:(NSString *)user;

@end
