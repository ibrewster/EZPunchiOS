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

- (IBAction)punchButtonPressed:(id)sender{
	[utils.communicator checkNetwork];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(recordNetworkPunch:) 
												 name:@"EZPServerReachable" 
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(recordLocalPunch:) 
												 name:@"EZPServerUnreachable" 
											   object:nil];
}


-(void)recordLocalPunch:(NSNotification *)notificication
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:@"EZPServerReachable" 
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:@"EZPServerUnreachable" 
												  object:nil];
	
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
	
	if (!self.managedObjectContext) {
		UIAlertView *errorAlert = [[UIAlertView alloc]
								   initWithTitle: @"Unable to record punch"
								   message:@"No data file found. Please report this error."
								   delegate:nil
								   cancelButtonTitle:@"OK"
								   otherButtonTitles:nil];
		
		[errorAlert show];
		[errorAlert release];
		return;
		
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
		return;
	}

	[self finalizePunch:nil];

}

-(void)recordNetworkPunch:(NSNotification *)notificication
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:@"EZPServerReachable" 
												  object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:@"EZPServerUnreachable" 
												  object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(recordNetworkPunchStageTwo:) 
												 name:@"PunchTypeUpdated" 
											   object:nil];
	[self checkForLocalPunches];
	//wait untill complete



}

-(void) recordNetworkPunchStageTwo:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:@"PunchTypeUpdated" 
												  object:nil];
	NSString *user=[[NSUserDefaults standardUserDefaults] stringForKey:@"selectedUser"];
	NSString * requestString=[NSString stringWithFormat:@"GetPunchType\n%@|",user];
	if([utils.communicator openConnection])
	{
		[utils.communicator sendDataWithData:[requestString dataUsingEncoding:NSASCIIStringEncoding]];
		//the next piece of data we get should be our punch, so grab it.
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finalizePunch:) name:@"EZPDataRecieved" object:nil];
	}
	else {
		[self recordLocalPunch:nil];
		[self finalizePunch:nil];
	}
}

-(void)finalizePunch:(NSNotification *)notification
{	
	BOOL punchStored=NO;
	
	NSString *user=[[NSUserDefaults standardUserDefaults] stringForKey:@"selectedUser"];
	
	NSDateFormatter *dateFormatter =[[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:@"YYYY-MM-dd"];
	NSString *punchDate=[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:currentDate]];
	
	[dateFormatter setDateFormat:@"HH:mm:ss"];
	NSString *punchTime=[[NSString alloc] initWithFormat:@"%@", [dateFormatter stringFromDate:currentDate]];
	NSString *notes=textField.text;
	
	textField.text=nil;
	
	if(notification) //store to server, but only after reciving latest punch type
	{
		//see if we got a punch data set
		NSString *dataString=[NSString stringWithCString:[[[notification userInfo] objectForKey:@"data"] bytes] encoding:NSASCIIStringEncoding];
		NSArray *commandArray=[dataString componentsSeparatedByString:@"|"];
		NSString *commandString=nil;
		for (NSString *command in commandArray) {
			if ([command hasPrefix:@"PunchType"]) {
				commandString=command;
				break;
			}
		}
		if (commandString==nil) { //we didn't get the punch data we are waiting for
			return;
		}
		
		//Now that we have what we are looking for, stop looking
		[[NSNotificationCenter defaultCenter] removeObserver:self name:@"EZPDataRecieved" object:nil];
		

		NSArray *punchInfo=[commandString componentsSeparatedByString:@"\n"];
		NSString *SentUser=[[punchInfo objectAtIndex:2] stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]]; //the first entry is the command
		if ([SentUser isEqualToString:user]) {
			punchtype=[NSString stringWithString:[punchInfo objectAtIndex:1]];
		}
		
		//[self updatePunchType];
		NSData *encodedPunch=encodePunchForSending(user, punchtype, punchDate, punchTime, notes);
		//if ([utils.communicator openConnection]) {
		punchStored=[utils.communicator sendDataWithData:encodedPunch];
		[utils.communicator closeConnection];
		
		
//		//check for locally stored punches we can send to the server
//		NSFetchRequest *request = [[NSFetchRequest alloc] init];
//		NSEntityDescription *entity = [NSEntityDescription entityForName:@"punches" inManagedObjectContext:managedObjectContext];
//		[request setEntity:entity];
//		NSSortDescriptor *dateColumn = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
//		NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:dateColumn, nil];
//		[request setSortDescriptors:sortDescriptors];
//		[sortDescriptors release];
//		[dateColumn release];
//		
//		NSError *error;
//		NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
//		
//		if ([fetchResults count]>0) {
//			UIAlertView *foundAlert = [[UIAlertView alloc]
//									   initWithTitle: @"Local punches detected"
//									   message:@"Would you like to sync all "
//									   "locally stored punches to the server now?"
//									   delegate:self
//									   cancelButtonTitle:@"NO"
//									   otherButtonTitles:@"YES", nil];
//			[foundAlert show];
//			[foundAlert release];
//			
//		}
		
		//}
		
	}
	
	//if (punchStored) {
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
	if([punchtype isEqualToString:@"in"])
	{
		punchtype=@"out";
		[self.usersDict setValue:@"in" forKey:user];
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
	
	//}
	
	//[buttonTitle release];
	
}

- (void) checkForLocalPunches
{
	//check for locally stored punches we can send to the server
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
								   "locally stored punches to the server now?"
								   delegate:self
								   cancelButtonTitle:@"NO"
								   otherButtonTitles:@"YES", nil];
		[foundAlert show];
		[foundAlert release];
		
	}
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PunchTypeUpdated" 
															object:self
														  userInfo:nil];
	}

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
	else {
		//check for updated punch type. Don't bother if there is no user
		[utils.communicator checkNetwork];
		[[NSNotificationCenter defaultCenter] addObserver:self 
												 selector:@selector(runViewLoadChecks:) 
													 name:@"EZPServerReachable" 
												   object:nil];
	}

	self.userLabel.text=[[NSString alloc] initWithFormat:@"Current user: %@",user];
	useTimeRounding=[[NSUserDefaults standardUserDefaults] boolForKey:@"useRounding"];
	
}

-(void) runViewLoadChecks:(NSNotification *)notification
{
	[[NSNotificationCenter defaultCenter] removeObserver:self 
													name:@"EZPServerReachable" 
												  object:nil];
	[self checkForLocalPunches];
}

-(void) requestPunchType:(NSNotification *)notificiation
{

	if([utils.communicator initalized] && [utils.communicator openConnection])
	{
		NSString *user=[[NSUserDefaults standardUserDefaults] stringForKey:@"selectedUser"];
		NSString * requestString=[NSString stringWithFormat:@"GetPunchType\n%@|",user];
		
		[utils.communicator sendDataWithData:[requestString dataUsingEncoding:NSASCIIStringEncoding]];
		//the next piece of data we get should be our punch, so grab it.
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(recievePunchType:) name:@"EZPDataRecieved" object:nil];
	}
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

-(void) recievePunchType:(NSNotification *)notification
{
	//see if we got a punch data set
	NSString *user=[[NSUserDefaults standardUserDefaults] stringForKey:@"selectedUser"];
    if (!user) {
        return; //we don't have a user selected, so don't do anything
    }
	NSString *dataString=[NSString stringWithCString:[[[notification userInfo] objectForKey:@"data"] bytes] encoding:NSASCIIStringEncoding];
	NSArray *commandArray=[dataString componentsSeparatedByString:@"|"];
	NSString *commandString=nil;
	for (NSString *command in commandArray) {
		if ([command hasPrefix:@"PunchType"]) {
			commandString=command;
			break;
		}
	}
	if (commandString==nil) { //we didn't get the punch data we are waiting for
		return;
	}
	
	//Now that we have what we are looking for, stop looking and close the connection
	[[NSNotificationCenter defaultCenter] removeObserver:self name:@"EZPDataRecieved" object:nil];
	[utils.communicator closeConnection];
	
	
	NSArray *punchInfo=[commandString componentsSeparatedByString:@"\n"];
	NSString *SentUser=[[punchInfo objectAtIndex:2] stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]]; //the first entry is the command
	if ([SentUser isEqualToString:user]) {
		punchtype=[NSString stringWithString:[punchInfo objectAtIndex:1]];
		if([punchtype isEqualToString:@"in"])
		{
			[self.usersDict setValue:@"out" forKey:user];
		}
		else
		{
			[usersDict setValue:@"in" forKey:user];
		}
		[[NSUserDefaults standardUserDefaults] setObject:usersDict forKey:@"users"]; //save users to settings file
		[self updatePunchType];
		
	}
	[[NSNotificationCenter defaultCenter] postNotificationName:@"PunchTypeUpdated" 
														object:self
													  userInfo:nil];
	
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
	else {
		[[NSNotificationCenter defaultCenter] postNotificationName:@"PunchTypeUpdated" 
															object:self
														  userInfo:nil];
	}
	[self requestPunchType:nil];
}


@end
