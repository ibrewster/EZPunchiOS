//
//  HomeView.m
//  EPunchClockPhone
//
//  Created by israel on 5/12/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "HomeView.h"
#import "MainViewController.h"
#import "settingsViewController.h"


@implementation HomeView

@synthesize settingsView;
@synthesize punchView;
@synthesize utils;
@synthesize punchViewController;
@synthesize setViewCont;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	punchViewController=[[[MainViewController alloc] initWithNibName:@"MainView" bundle:[NSBundle mainBundle]] retain];
	setViewCont=[[[settingsViewController alloc] initWithNibName:@"SettingsView" bundle:[NSBundle mainBundle]] retain];
	[punchViewController setUtils:utils];

	


	[punchView addSubview:[punchViewController view]];
	for(UIView *subview in [self.punchView subviews])
		subview.center=self.punchView.center;
	
	[punchViewController viewDidAppear:true];
	
	[settingsView addSubview:[setViewCont view]];
	[[setViewCont view] setCenter:[settingsView center]];
	[setViewCont viewDidAppear:true];
	
	//[punchView retain];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
	return YES;
}

@end
