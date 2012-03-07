//
//  MainViewController.m
//  TimeClock4iPhone
//
//  Created by israel on 8/19/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "MainViewController.h"
#import "MainView.h"
#import "punches.h"

@implementation MainViewController

@synthesize textField;
@synthesize timeLabel;
@synthesize userLabel;
@synthesize usersDict;
@synthesize updateTimer;
@synthesize currentDate;
@synthesize managedObjectContext;
@synthesize utils;
//@synthesize delegate;


- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
		self.title=@"Punch Clock";
    }
    return self;
}

- (IBAction)startRepeatingTimer:(id)sender {
	
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:1.0
													  target:self selector:@selector(setTime:)
													userInfo:nil repeats:YES];
    self.updateTimer = timer;
}

- (IBAction)stopRepeatingTimer:(id)sender {
	if (self.updateTimer) {
		[updateTimer invalidate];
	}
    self.updateTimer = nil;
}

- (IBAction)updatePunchType{
	
	NSString *lastPunch;
	NSString *selectedUser;
	selectedUser=[[NSUserDefaults standardUserDefaults] stringForKey:@"selectedUser"];

	if(selectedUser!=nil)
	{
		lastPunch=[usersDict objectForKey:selectedUser];
		[punchButton setEnabled:YES];
		
	}
	else
	{
		[punchButton setEnabled:NO];
		//NSString *buttonTitle=@"Punch", punchtype];
		[punchButton setTitle:@"Punch" forState:UIControlStateNormal];
		return;
	}
	
	if([lastPunch isEqualToString:@"in"])
	{
		punchtype=@"out";
	}
	else
		punchtype=@"in";
	
	NSString *buttonTitle=[[NSString alloc] initWithFormat:@"Punch %@", punchtype];
	[punchButton setTitle:buttonTitle forState:UIControlStateNormal];
	[buttonTitle release];
	
}

- (IBAction)recordPunch:(id)sender{
	BOOL canSeeServer=checkNetwork();
	BOOL punchStored=NO;
	NSDateFormatter *dateFormatter =[[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"YYYY-MM-dd"];
	NSString *punchDate=[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:currentDate]];
	
	[dateFormatter setDateFormat:@"HH:mm:ss"];
	NSString *punchTime=[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:currentDate]];
	NSString *user=[[NSUserDefaults standardUserDefaults] stringForKey:@"selectedUser"];
	NSString *notes=textField.text;
	
	textField.text=nil;
	
    if (!canSeeServer || ![utils.communicator initalized])
    {
		if([[NSUserDefaults standardUserDefaults] boolForKey:@"showLocalWarning"])
		{
			UIAlertView *errorAlert = [[UIAlertView alloc]
									   initWithTitle: @"Server Not Reachable"
									   message:@"Punch will be stored locally until server can be reached"
									   delegate:nil
									   cancelButtonTitle:@"OK"
									   otherButtonTitles:nil];
			
			
			[errorAlert show];
			[errorAlert release];
		}
		punchStored=[self storeLocalPunch];
    }
	else {
		NSLog(@"Sent punch of type: %@",punchtype);
		NSData *encodedPunch=encodePunchForSending(user, punchtype, punchDate, punchTime, notes);
		if ([utils.communicator openConnection]) {
			punchStored=[utils.communicator sendDataWithData:encodedPunch];
			
			NSFetchRequest *request = [[NSFetchRequest alloc] init];
			NSEntityDescription *entity = [NSEntityDescription entityForName:@"punches" inManagedObjectContext:managedObjectContext];
			[request setEntity:entity];
			NSSortDescriptor *dateColumn = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
			NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:dateColumn, nil];
			[request setSortDescriptors:sortDescriptors];
			[sortDescriptors release];
			[dateColumn release];
			
			NSError *error;
			NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];

			if ([fetchResults count]>0) {
				UIAlertView *foundAlert = [[UIAlertView alloc]
										   initWithTitle: @"Local punches detected"
										   message:@"Would you like to sync all "
										   "locally stored punches to this server now?"
										   delegate:self
										   cancelButtonTitle:@"NO"
										   otherButtonTitles:@"YES", nil];
				[foundAlert show];
				[foundAlert release];

			}
			
			[utils.communicator closeConnection];
		}
		else {
			if([[NSUserDefaults standardUserDefaults] boolForKey:@"showLocalWarning"])
			{
				UIAlertView *errorAlert = [[UIAlertView alloc]
										   initWithTitle: @"Unable to connect to server"
										   message:@"Punch will be stored locally until server can be reached"
										   delegate:nil
										   cancelButtonTitle:@"OK"
										   otherButtonTitles:nil];
				[errorAlert show];
				[errorAlert release];
			}
			punchStored=[self storeLocalPunch];
		}
	}
	
	if (punchStored) {
		NSString *punchAlert;
		[dateFormatter setDateStyle:NSDateFormatterNoStyle];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		punchAlert=[[NSString alloc] initWithFormat:@"Your %@ punch for %@ on %@ at %@ has been recorded.\n\nNotes: %@", 
					punchtype,user,punchDate,
					[dateFormatter stringFromDate:currentDate],notes];
		[punchDate release];
		[punchTime release];
		
		
		UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle: @"Punch Status"
								   message:punchAlert
								   delegate:nil
								   cancelButtonTitle:@"OK"
								   otherButtonTitles:nil];
		
		
		[errorAlert show];
		[errorAlert release];
		[punchAlert release];
		if(punchtype==@"in")
		{
			punchtype=@"out";
			[self.usersDict setObject:@"in" forKey:user];
		}
		else
		{
			punchtype=@"in";
			[usersDict setValue:@"out" forKey:user];
		}
		[[NSUserDefaults standardUserDefaults] setObject:usersDict forKey:@"users"];
		
		NSString *buttonTitle=[[NSString alloc] initWithFormat:@"Punch %@", punchtype];
		[punchButton setTitle:buttonTitle forState:UIControlStateNormal];
		punchButton.titleLabel.text=buttonTitle;
		
	}
	
		//[buttonTitle release];
}

-(BOOL)storeLocalPunch
{
	if (!self.managedObjectContext) {
		UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle: @"Unable to record punch"
								   message:@"No data file found. Please report this error."
								   delegate:nil
								   cancelButtonTitle:@"OK"
								   otherButtonTitles:nil];
		
		
		[errorAlert show];
		[errorAlert release];
		return NO;
		
	}
	
	punches *punch = (punches *)[NSEntityDescription insertNewObjectForEntityForName:@"punches" inManagedObjectContext:managedObjectContext];
	
	NSDateFormatter *dateFormatter =[[[NSDateFormatter alloc] init] autorelease];
	
	[dateFormatter setDateFormat:@"YYYY-MM-dd"];
	NSString *punchDate=[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:currentDate]];
	
	[dateFormatter setDateFormat:@"HH:mm:ss"];
	NSString *punchTime=[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:currentDate]];
	NSString *notes=textField.text;
	NSString *user=[[NSUserDefaults standardUserDefaults] stringForKey:@"selectedUser"];
	
	textField.text=nil;
	
	[punch setUser:user];
	[punch setNotes:notes];
	[punch setPunchdate:punchDate];
	[punch setPunchtime:punchTime];
	[punch setPunchtype:punchtype];
	[punch setTimestamp:[NSDate date]];
	
	NSError *error;
	
	if (![managedObjectContext save:&error]){
		return NO;
	}
	return YES;

}

- (IBAction)setTime:(id)sender {
	//get current date
	NSDate *currentTime = [NSDate date];
	//get the components of the current date
	NSDateComponents *roundedTime=[[NSCalendar currentCalendar] components: NSSecondCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSYearCalendarUnit|NSHourCalendarUnit | NSMinuteCalendarUnit fromDate:currentTime];
	//seperate the second out for flashing seperator
	NSInteger second=[roundedTime second];
	//we don't record seconds
	[roundedTime setSecond:0];
	
	//get the minute and round to the nearest 15 if rounding
	if(useTimeRounding)
	{
		NSInteger roundedMinute=round([roundedTime minute]/15.0)*15;
		[roundedTime setMinute:roundedMinute];
	}
	

	//update the current time with the rounded time
	//[currentTime release];
	currentTime=[[NSCalendar currentCalendar] dateFromComponents:roundedTime];
	[self setCurrentDate:currentTime];
	//create a date formater to display the time in the desired format
	NSDateFormatter *dateFormatter =[[[NSDateFormatter alloc] init] autorelease];
	if((second%2) == 0)
		[dateFormatter setDateFormat:@"HH mm"];
	else
		[dateFormatter setDateFormat:@"HH:mm"];
	NSString * formatedTime=[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:currentTime]];
	//NSString * greeting=[[NSString alloc] initWithFormat:@"%@", [currentTime description]];
	
	CGSize maximumSize=CGSizeMake(280, 160);
	UIFont *timeFont=timeLabel.font;
	CGSize timeStringSize=[formatedTime sizeWithFont:timeFont 
								   constrainedToSize:maximumSize 
									   lineBreakMode:self.timeLabel.lineBreakMode];
	CGRect timeFrame=CGRectMake(20, 20, 280, timeStringSize.height);
	self.timeLabel.frame=timeFrame;
    timeLabel.text = formatedTime;
    [formatedTime release];
		//[currentTime release];
}

- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
    if (theTextField == textField) {
        [textField resignFirstResponder];
    }
    return YES;
}


- (void)setUtilsWithUtils:(Utilities *)newUtils{
	[self setUtils:newUtils];
	managedObjectContext=self.utils.managedObjectContext;
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
	[super viewDidLoad];
    managedObjectContext=utils.managedObjectContext;
    [self startRepeatingTimer:self];

}

-(void)viewDidAppear:(BOOL)animated
{
	//Load the user list and last punches
    self.usersDict=[NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"users"]];
    
    //Display an error if no users
    if([usersDict count]==0)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Data Error" message:@"No users found. Please sync with desktop app to load users" delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
        [alertView show];
        [alertView release];
    }	
	
	[self updatePunchType];
    NSString *user=[[NSUserDefaults standardUserDefaults] stringForKey:@"selectedUser"];
    if (!user) {
        user=@"None";
    }
	self.userLabel.text=[[NSString alloc] initWithFormat:@"Current user: %@",user];
	useTimeRounding=[[NSUserDefaults standardUserDefaults] boolForKey:@"useRounding"];
	
}




 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return YES;
 }


/*
 // Override to allow orientations other than the default portrait orientation.
 - (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 // Return YES for supported orientations
 return (interfaceOrientation == UIInterfaceOrientationPortrait);
 }
 */

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
	
	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	[self stopRepeatingTimer:self];
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

///////////////////////////////////////////////////////
// CoreData stuff
///////////////////////////////////////////////////////
#pragma mark -
#pragma mark Saving

/**
 Performs the save action for the application, which is to send the save:
 message to the application's managed object context.
 */
- (IBAction)saveAction:(id)sender {
	
    NSError *error;
    if (![[self managedObjectContext] save:&error]) {
		// Handle error
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
    }
}

/**
 applicationWillTerminate: saves changes in the application's managed object context before the application terminates.
 */
- (void)applicationWillTerminate:(UIApplication *)application {
	[self stopRepeatingTimer:self];
    NSError *error;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
			// Handle error
			NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
			exit(-1);  // Fail
        } 
    }
}

#pragma mark -

- (void)dealloc {
	[managedObjectContext release];
	[self stopRepeatingTimer:self];
	
	[textField release];
    [timeLabel release];
    //[notes release];	
    [super dealloc];
}

#pragma mark Alert View Delegate
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	if (buttonIndex==1) {
		[utils.communicator openConnection];
		[utils.communicator sendPunchesFromContext:managedObjectContext];
		[utils.communicator closeConnection];
		UIAlertView *completeMessage = [[UIAlertView alloc]
								   initWithTitle: @"Sync Complete"
								   message:nil
								   delegate:nil
								   cancelButtonTitle:@"OK"
								   otherButtonTitles:nil];
		[completeMessage show];
		[completeMessage release];
	}
}


@end
