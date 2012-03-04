//
//  HomeView.h
//  EPunchClockPhone
//
//  Created by israel on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"
#import "MainViewController.h"
#import "settingsViewController.h"


@interface HomeView : UIViewController {
    UIView *settingsView;
	UIView *punchView;
	MainViewController *punchViewController;
	settingsViewController *setViewCont;
	
	Utilities *utils;
	
}

@property (nonatomic, retain) Utilities *utils;
@property (nonatomic, assign) IBOutlet UIView *settingsView;
@property (nonatomic, assign) IBOutlet UIView *punchView;
@property (nonatomic, assign) IBOutlet MainViewController *punchViewController;
@property (nonatomic, assign) IBOutlet settingsViewController *setViewCont;
@end
