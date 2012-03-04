//
//  loginViewController.m
//  EZPunchPhone
//
//  Created by Israel Brewster on 1/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "loginViewController.h"
#import <CommonCrypto/CommonDigest.h>

@implementation loginViewController

@synthesize appDelegate;
@synthesize password;
@synthesize username;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super init];
    if (self) {
		[self setTitle:@"login"];
    }
    return self;
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

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	[theTextField resignFirstResponder];
	if(theTextField == password)
	{
		[self login:self];
		return YES;
	}
	else
	{
		[self.password becomeFirstResponder];
		return NO;
	}
}

-(IBAction)login:(id)sender
{
	//Load the user list and last punches
    NSDictionary *passwordDict=[NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"passwords"]];
    	
	NSString *userPassword=[[passwordDict objectForKey:[username text]] uppercaseString];
	
	//hash the entered password for comparison
	const char *cStr=[[password text] UTF8String];
	unsigned char result[CC_MD5_DIGEST_LENGTH];
	CC_MD5(cStr,strlen(cStr),result);
	
	//convert to hex
	NSString *enteredPassword=[[NSString 
							   stringWithFormat: @"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",
							   result[0], result[1],
							   result[2], result[3],
							   result[4], result[5],
							   result[6], result[7],
							   result[8], result[9],
							   result[10], result[11],
							   result[12], result[13],
							   result[14], result[15]
							   ] uppercaseString];
	if (!userPassword || ![enteredPassword isEqualToString:userPassword]) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Unable to login" message:@"Incorrect password or user not found." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Ok", nil];
        [alertView show];
        [alertView release];
		[self.password becomeFirstResponder];
	}
	else
	{
		[[NSUserDefaults standardUserDefaults] setValue:[username text] forKey:@"selectedUser"];
		[appDelegate submitLogin:self withUser:[username text]];
	}
	[password setText:@""];
}

@end