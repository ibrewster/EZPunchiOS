//
//  loginViewController.h
//  EZPunchPhone
//
//  Created by Israel Brewster on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "EPunchClockPhoneAppDelegate.h"

@interface loginViewController : UIViewController <UITextFieldDelegate>

@property (nonatomic, retain)IBOutlet EPunchClockPhoneAppDelegate *appDelegate;
@property (nonatomic, retain)IBOutlet UITextField *password;
@property (nonatomic, retain)IBOutlet UITextField *username;

-(IBAction)login:(id)sender;

@end
