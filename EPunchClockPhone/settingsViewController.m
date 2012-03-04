//
//  FlipsideViewController.m
//  TimeClock4iPhone
//
//  Created by israel on 8/19/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "settingsViewController.h"
#import "punches.h"
#import "unistd.h"

@implementation settingsViewController

@synthesize roundTimes;
@synthesize curLocation;
@synthesize currentUser;
@synthesize arrayUsers;
@synthesize usersDict;
@synthesize managedObjectContext;

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
	
	NSString *lastUser=[[NSUserDefaults standardUserDefaults] stringForKey:@"selectedUser"];

	arrayUsers=[[NSMutableArray arrayWithCapacity:0] retain];
	NSString *needLogin=[[NSUserDefaults standardUserDefaults] stringForKey:@"login"];
	if ([needLogin isEqualToString:@"True"]) {
		if (lastUser && [[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"users"] allKeys] containsObject:lastUser]) {
			[arrayUsers addObject:lastUser];
		}
	}
	else
		[arrayUsers setArray:[[[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"users"] allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];

	//TODO: Make sure last user is valid
	
	[arrayUsers insertObject:@"" atIndex:0];
	[currentUser reloadAllComponents];
	//set the state of the time rounding toggle.
	[roundTimes setOn:[[NSUserDefaults standardUserDefaults] boolForKey:@"useRounding"] animated:NO];
	
	
	NSInteger index=0;
	while (index<[arrayUsers count] && ![lastUser isEqualToString:[arrayUsers objectAtIndex:index]]) {
		index++;
	}
	
    if (index<[arrayUsers count]) {
        [currentUser selectRow:(NSInteger)index inComponent:0 animated:NO];
    }
	else
		[currentUser selectRow:-1 inComponent:0 animated:NO];
	
	curLocation.text=[[NSUserDefaults standardUserDefaults] valueForKey:@"location"];
	if (curLocation.text==nil) {
		curLocation.text=@"iPhone";
	}
	
    //self.view.backgroundColor = [UIColor viewFlipsideBackgroundColor];
}

- (void) viewDidDisappear:(BOOL)animated
{
	[arrayUsers release];
}

// Code for the Rounding slider
- (IBAction)setRound:(id)sender{
	if (roundTimes.isOn )
	{
		[[NSUserDefaults standardUserDefaults]
		 setObject:@"YES" forKey:@"useRounding"];
		//useRounding=CFSTR("True");
	}
	else
	{
		[[NSUserDefaults standardUserDefaults]
		 setObject:@"NO" forKey:@"useRounding"];
	}
}

-(IBAction)setLocation:(id)sender{
	
	[[NSUserDefaults standardUserDefaults] setObject:curLocation.text forKey:@"location"];
	[curLocation resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	[theTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	
	NSTimeInterval animationDuration = 0.300000011920929;
	CGRect frame = self.view.frame;
	frame.origin.y -= 150;
	frame.size.height += 150;
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
	[UIView setAnimationDuration:animationDuration];
	self.view.frame = frame;
	[UIView commitAnimations];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	NSTimeInterval animationDuration = 0.300000011920929;
	CGRect frame = self.view.frame;
	frame.origin.y += 150;
	frame.size.height -= 150;
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
	[UIView setAnimationDuration:animationDuration];
	self.view.frame = frame;
	[UIView commitAnimations];
}


///////////////////////////////////////
// Code for the UIPickerView
//////////////////////////////////////
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)thePickerView {
	return 1;
}

- (NSInteger)pickerView:(UIPickerView *)thePickerView numberOfRowsInComponent:(NSInteger)component {
	return [arrayUsers count];
    //return 0;
}

- (NSString *)pickerView:(UIPickerView *)thePickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	
	return [arrayUsers objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)thePickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
	if(row>0) //Row zero is "nothing"
		[[NSUserDefaults standardUserDefaults] setObject:[arrayUsers objectAtIndex:row] forKey:@"selectedUser"];
}

//////////////////////////////////////
// end UIPickerView Code
/////////////////////////////////////


// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
	// Return YES for supported orientations
	return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}


- (void)dealloc {
    [super dealloc];
}

@end