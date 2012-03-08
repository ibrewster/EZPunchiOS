//
//  syncViewController.m
//  TimeClock4iPhone
//
//  Created by israel on 9/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "syncViewController.h"
#import "punches.h"
#import "unistd.h"
#include <arpa/inet.h>
#define kAppIdentifier		@"EPunchClock"

@interface NSNetService (syncViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService *)aService;
@end

@implementation NSNetService (syncViewControllerAdditions)
- (NSComparisonResult) localizedCaseInsensitiveCompareByName:(NSNetService *)aService {
	return [[self name] localizedCaseInsensitiveCompare:[aService name]];
}
@end


@implementation syncViewController

@synthesize initialWaitOver = _initialWaitOver;
@synthesize services = _services;
@synthesize tableView;
@synthesize currentResolve = _currentResolve;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize needsActivityIndicator = _needsActivityIndicator;
@synthesize showDisclosureIndicators = _showDisclosureIndicators;
@synthesize lastResolve = _lastResolve;
@synthesize ownEntry = _ownEntry;
@dynamic timer;
@synthesize managedObjectContext;
@synthesize arrayUsers;
@synthesize usersDict;
@synthesize utils;
@synthesize syncLabel;
@synthesize manualHost;
@synthesize manualPort;
@synthesize manualSync;
@synthesize passwordsDict;

#pragma mark -
#pragma mark Initalization

// The designated initializer.  Override if you create the controller programmatically and want to perform customization that is not appropriate for viewDidLoad.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        self.title=@"Computers";
		_services = [[NSMutableArray alloc] init];
    }
    return self;
}
-(IBAction)hideKeyboard:(id)Sender
{
	[manualPort resignFirstResponder];
	[manualHost resignFirstResponder];
}
- (BOOL)textFieldShouldReturn:(UITextField *)theTextField {
	[theTextField resignFirstResponder];
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	activeField=textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	activeField=nil;
}

- (void)keyboardWasShown:(NSNotification *)aNotification {
    if ( keyboardShown )
        return;
	
	NSDictionary *info = [aNotification userInfo];
	NSValue *aValue = [info objectForKey:UIKeyboardFrameBeginUserInfoKey];
	CGSize keyboardSize = [aValue CGRectValue].size;
	
	NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
	CGRect frame = self.view.frame;
	frame.origin.y -= keyboardSize.height-44;
	frame.size.height += keyboardSize.height-44;
	[UIView beginAnimations:@"ResizeForKeyboard" context:nil];
	[UIView setAnimationDuration:animationDuration];
	self.view.frame = frame;
	[UIView commitAnimations];
	
	viewMoved = YES;
	
    keyboardShown = YES;
}

- (void)keyboardWasHidden:(NSNotification *)aNotification {
    if ( viewMoved ) {
        NSDictionary *info = [aNotification userInfo];
        NSValue *aValue = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
        CGSize keyboardSize = [aValue CGRectValue].size;
		
        NSTimeInterval animationDuration = [[info objectForKey:UIKeyboardAnimationDurationUserInfoKey] doubleValue];
        CGRect frame = self.view.frame;
        frame.origin.y += keyboardSize.height-44;
        frame.size.height -= keyboardSize.height-44;
        [UIView beginAnimations:@"ResizeForKeyboard" context:nil];
        [UIView setAnimationDuration:animationDuration];
        self.view.frame = frame;
        [UIView commitAnimations];
		
        viewMoved = NO;
    }
	
    keyboardShown = NO;
}
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasShown:)
												 name:UIKeyboardDidShowNotification
											   object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWasHidden:)
												 name:UIKeyboardDidHideNotification
											   object:nil];
	[[NSNotificationCenter defaultCenter] addObserver:self 
											 selector:@selector(processData:) 
												 name:@"EZPDataRecieved" 
											   object:utils.communicator];
	
	[self.view setBackgroundColor:[self.tableView backgroundColor]];
    _services = [[NSMutableArray alloc] init];
    managedObjectContext=utils.managedObjectContext;
	self.searchingForServicesString=@"Searching for computers...";
	[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(initialWaitOver:) userInfo:nil repeats:NO];
	[syncLabel setText:[NSString stringWithFormat:@"Last Sync: %@",
						[[NSUserDefaults standardUserDefaults] stringForKey:@"LastSync"]]];
	[manualHost setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"ManualHost"]];
	[manualPort setText:[[NSUserDefaults standardUserDefaults] stringForKey:@"ManualPort"]];
	
    //	syncLabel.textColor = [UIColor colorWithRed: 76/255.0 green: 86/255.0 blue: 108/255.0 alpha:1.0];
    //	syncLabel.font=[UIFont boldSystemFontOfSize:17];
    //	syncLabel.shadowColor=[UIColor whiteColor];
    //	syncLabel.shadowOffset=CGSizeMake(0.0, 1.0);
	usersDict=0;
	passwordsDict=0;
}

-(void)viewDidAppear:(BOOL)animated
{
	[self searchForServicesOfType:[NSString stringWithFormat:@"_%@._tcp.", kAppIdentifier] inDomain:@"local"];
}

-(void) viewDidDisappear:(BOOL)animated
{
	[self stopCurrentResolve];
	[self.netServiceBrowser stop];
	[self.services removeAllObjects];
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

// If necessary, sets up state to show an activity indicator to let the user know that a resolve is occuring.
- (void)showWaiting:(NSTimer *)timer {
	if (timer == self.timer)
	{
		self.needsActivityIndicator = YES;
		
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.services indexOfObject:self.lastResolve] inSection:0];
		if (indexPath.row != NSNotFound) {
			[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
			[self.tableView reloadRowsAtIndexPaths:[NSArray	arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
		}
	}
	
}

- (void)initialWaitOver:(NSTimer *)timer {
	self.initialWaitOver= YES;
	if (![self.services count])
		[self.tableView reloadData];
}

- (BOOL)searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain {
	
	[self stopCurrentResolve];
	[self.netServiceBrowser stop];
	[self.services removeAllObjects];
	
	NSNetServiceBrowser *aNetServiceBrowser = [[NSNetServiceBrowser alloc] init];
	if(!aNetServiceBrowser) {
        // The NSNetServiceBrowser couldn't be allocated and initialized.
		return NO;
	}
	
	aNetServiceBrowser.delegate = self;
	self.netServiceBrowser = aNetServiceBrowser;
	[aNetServiceBrowser release];
	[self.netServiceBrowser searchForServicesOfType:type inDomain:domain];
	
	[self.tableView reloadData];
	return YES;
}

- (NSTimer *)timer {
	return _timer;
}

// When this is called, invalidate the existing timer before releasing it.
- (void)setTimer:(NSTimer *)newTimer {
	[_timer invalidate];
	[newTimer retain];
	[_timer release];
	_timer = newTimer;
}


- (void)stopCurrentResolve {
	
	self.needsActivityIndicator = NO;
	
	[self.currentResolve stop];
	self.currentResolve = nil;
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


- (void)dealloc {
	[self.netServiceBrowser stop];
	[_netServiceBrowser release];
	[_services release];
    [super dealloc];
}

- (NSString *)searchingForServicesString {
	return _searchingForServicesString;
}

// Holds the string that's displayed in the table view during service discovery.
- (void)setSearchingForServicesString:(NSString *)searchingForServicesString {
	if (_searchingForServicesString != searchingForServicesString) {
		[_searchingForServicesString release];
		_searchingForServicesString = [searchingForServicesString copy];
		
        // If there are no services, reload the table to ensure that searchingForServicesString appears.
		if ([self.services count] == 0) {
			[self.tableView reloadData];
		}
	}
}

- (NSString *)ownName {
	return _ownName;
}

- (void)setOwnName:(NSString *)name {
	if (_ownName != name) {
		_ownName = [name copy];
		
		if (self.ownEntry)
			[self.services addObject:self.ownEntry];
		
		NSNetService* service;
		
		for (service in self.services) {
			if ([service.name isEqual:name]) {
				self.ownEntry = service;
				[_services removeObject:service];
				break;
			}
		}
		
		[self.tableView reloadData];
	}
}


#pragma mark -
#pragma mark Table View
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // Returns section title based on physical state: [solid, liquid, gas, artificial]
    return @"Discovered Servers";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	// If there are no services and searchingForServicesString is set, show one row to tell the user.
	NSUInteger count = [self.services count];
	if (count == 0 && self.searchingForServicesString && self.initialWaitOver)
		return 1;
	
	return count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView2 cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	
	static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell *)[tableView2 dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier] autorelease];
	}
	
	NSUInteger count = [self.services count];
	if (count == 0 && self.searchingForServicesString) {
        // If there are no services and searchingForServicesString is set, show one row explaining that to the user.
        cell.textLabel.text = self.searchingForServicesString;
		cell.textLabel.textColor = [UIColor colorWithWhite:0.5 alpha:0.5];
		cell.accessoryType = UITableViewCellAccessoryNone;
		// Make sure to get rid of the activity indicator that may be showing if we were resolving cell zero but
		// then got didRemoveService callbacks for all services (e.g. the network connection went down).
		if (cell.accessoryView)
			cell.accessoryView = nil;
		return cell;
	}
	
	// Set up the text for the cell
	NSNetService *service = [self.services objectAtIndex:indexPath.row];
	cell.textLabel.text = [service name];
	cell.textLabel.textColor = [UIColor blackColor];
	cell.accessoryType = self.showDisclosureIndicators ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
	
	// Note that the underlying array could have changed, and we want to show the activity indicator on the correct cell
	if (self.needsActivityIndicator && self.currentResolve == service) {
		if (!cell.accessoryView) {
			CGRect frame = CGRectMake(0.0, 0.0, kProgressIndicatorSize, kProgressIndicatorSize);
			UIActivityIndicatorView* spinner = [[UIActivityIndicatorView alloc] initWithFrame:frame];
			[spinner startAnimating];
			spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
			[spinner sizeToFit];
			spinner.autoresizingMask = (UIViewAutoresizingFlexibleLeftMargin |
										UIViewAutoresizingFlexibleRightMargin |
										UIViewAutoresizingFlexibleTopMargin |
										UIViewAutoresizingFlexibleBottomMargin);
			cell.accessoryView = spinner;
			[spinner release];
		}
	} else if (cell.accessoryView) {
		cell.accessoryView = nil;
	}
	
	return cell;
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// Ignore the selection if there are no services as the searchingForServicesString cell
	// may be visible and tapping it would do nothing
	if ([self.services count] == 0)
		return nil;
	
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	// If another resolve was running, stop it & remove the activity indicator from that cell
	if (self.currentResolve) {
		// Get the indexPath for the active resolve cell
		NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.services indexOfObject:self.currentResolve] inSection:0];
		
		// Stop the current resolve, which will also set self.needsActivityIndicator
		[self stopCurrentResolve];
		[self.netServiceBrowser stop];
		[self.services removeAllObjects];
		
		// If we found the indexPath for the row, reload that cell to remove the activity indicator
		if (indexPath.row != NSNotFound)
			[self.tableView reloadRowsAtIndexPaths:[NSArray	arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	}
 	
	// Then set the current resolve to the service corresponding to the tapped cell
	self.currentResolve = [self.services objectAtIndex:indexPath.row];
    
    //see if this is a different server than last time.
    NSString *serviceName=[self.currentResolve name];
    NSString *lastServer=[[NSUserDefaults standardUserDefaults] stringForKey:@"lastServer"];
    if (![serviceName isEqualToString:lastServer]) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Changing Server" message:@"Any punches for users not existing on the new server will be lost\n\nAll users on this device will be replaced by the users from the new server" delegate:self cancelButtonTitle:@"Cancel" otherButtonTitles:@"Sync",nil];
        [alertView show];
        [alertView release];
        
    }
    else
    {
        [self alertView:NULL clickedButtonAtIndex:1];
    }
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex==0) {
        self.needsActivityIndicator=NO;
        NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.services indexOfObject:self.currentResolve] inSection:0];
        if (indexPath.row != NSNotFound) {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
            [self.tableView reloadRowsAtIndexPaths:[NSArray	arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
        }  
        [self viewDidAppear:true];
        return;
    }
    else if (buttonIndex==1)
    {
        [[NSUserDefaults standardUserDefaults] setValue:[self.currentResolve name] forKey:@"lastServer"];
        [self.currentResolve setDelegate:self];
        self.lastResolve=self.currentResolve;
        // Attempt to resolve the service. A value of 0.0 sets an unlimited time to resolve it. The user can
        // choose to cancel the resolve by selecting another service in the table view.
        [self.currentResolve resolveWithTimeout:30.0];
        
        // Make sure we give the user some feedback that the resolve is happening.
        // We will be called back asynchronously, so we don't want the user to think we're just stuck.
        // We delay showing this activity indicator in case the service is resolved quickly.
        self.timer=[NSTimer scheduledTimerWithTimeInterval:0.01 target:self selector:@selector(showWaiting:) userInfo:self.currentResolve repeats:NO];
    }
    
    
    
}

- (void)sortAndUpdateUI {
	// Sort the services by name.
	[self.services sortUsingSelector:@selector(localizedCaseInsensitiveCompareByName:)];
	[self.tableView reloadData];
}

#pragma mark -
#pragma mark Network
- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didRemoveService:(NSNetService *)service moreComing:(BOOL)moreComing {
	// If a service went away, stop resolving it if it's currently being resolved,
	// remove it from the list and update the table view if no more events are queued.
	
	if (self.currentResolve && [service isEqual:self.currentResolve]) {
		[self stopCurrentResolve];
	}
	[self.services removeObject:service];
	if (self.ownEntry == service)
		self.ownEntry = nil;
	
	// If moreComing is NO, it means that there are no more messages in the queue from the Bonjour daemon, so we should update the UI.
	// When moreComing is set, we don't update the UI so that it doesn't 'flash'.
	if (!moreComing) {
		[self sortAndUpdateUI];
	}
}	

- (void)netServiceBrowser:(NSNetServiceBrowser *)netServiceBrowser didFindService:(NSNetService *)service moreComing:(BOOL)moreComing {
	// If a service came online, add it to the list and update the table view if no more events are queued.
	if ([service.name isEqual:self.ownName])
		self.ownEntry = service;
	else
		[self.services addObject:service];
	// If moreComing is NO, it means that there are no more messages in the queue from the Bonjour daemon, so we should update the UI.
	// When moreComing is set, we don't update the UI so that it doesn't 'flash'.
	if (!moreComing) {
		[self sortAndUpdateUI];
	}
}	

// This should never be called, since we resolve with a timeout of 0.0, which means infinite
- (void)netService:(NSNetService *)sender didNotResolve:(NSDictionary *)errorDict {
	[self stopCurrentResolve];
	[self.tableView reloadData];
}

- (void)netServiceDidResolveAddress:(NSNetService *)service {
	assert(service == self.currentResolve);
	
	[service retain];
	[self stopCurrentResolve];
	
	[self didResolveInstance:service];
	
    [service release];
}

- (void) didResolveInstance:(NSNetService *)netService
{
	if (!netService) {
		[utils.communicator closeConnection];
		return;
	}
	
	
	struct sockaddr_in  *socketAddress = nil;
	NSString            *ipString = nil;
	unsigned short int   port;
	BOOL				connected=NO;
	
	//make sure any old conenctions are closed
	[utils.communicator closeConnection];
	
	//try each address until one works (hopefully)
	for (NSData *data in [netService addresses]) {
		char addressBuffer[100];
		socketAddress=(struct sockaddr_in *)[data bytes];
		int sockFamily = socketAddress->sin_family;
		if (sockFamily == AF_INET || sockFamily == AF_INET6) {
			ipString=[NSString stringWithFormat:@"%s",inet_ntop(sockFamily,&(socketAddress->sin_addr),addressBuffer,sizeof(addressBuffer))];
			port=ntohs(socketAddress->sin_port);
			
			[utils.communicator initalizeConnectionForServer:ipString WithPort:port];
			NSLog(@"Server: %@ Port:%i",ipString,port);
			
			if ([self openStreams]) {
				connected=YES;
				break;
			}
		}
	}
	if(!connected)
	{
		[self _showAlert:@"Unable to connect- no valid address"];
		return;
	}
	else {
		[[NSUserDefaults standardUserDefaults] setValue:ipString forKey:@"ManualHost"];
		[[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%i",port] forKey:@"ManualPort"];
	}
	
	[self requestUsers];
	[self requestLogin];
	[utils.communicator sendPunchesFromContext:managedObjectContext];
}

- (BOOL) openStreams
{
	if([utils.communicator initalized])
	{
		//[utils.communicator setStreamDelegates:self];
		return [utils.communicator openConnection];
	}
	//else, but don't use else to avoid compiler warning.
	return NO; //if we get here, then the communicator has not been initalized,
			   //therfore we did not open the streams.
}

- (void)requestLogin
{
	NSString *request=@"GetLogin|";
	//[self send:[request dataUsingEncoding: NSASCIIStringEncoding]];
	[utils.communicator sendDataWithData:[request dataUsingEncoding: NSASCIIStringEncoding]];
}

- (BOOL)requestUsers
{
	//TODO:make users/punches store by id. Requires changes on Server as well as client
	//clear the existing user list
	if (usersDict) {
		[usersDict release];
		usersDict=0;
	}
	if(passwordsDict){
		[passwordsDict release];
		passwordsDict=0;
	}
	
	NSString *request=@"GetUserList|";
	//return [self send:[request dataUsingEncoding: NSASCIIStringEncoding]];
	return [utils.communicator sendDataWithData:[request dataUsingEncoding: NSASCIIStringEncoding]];
}

- (void) _showAlert:(NSString *)title
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];
}

- (IBAction) runManualSync:(id)Sender
{
	NSString *serverHost=[manualHost text];
	int serverPort=[[manualPort text] intValue];
	if (!serverHost || !serverPort) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Please enter server info" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alertView show];
        [alertView release];
		return;
	}
	//save host and port for next run
	[[NSUserDefaults standardUserDefaults] setValue:serverHost forKey:@"ManualHost"];
	[[NSUserDefaults standardUserDefaults] setValue:[NSString stringWithFormat:@"%i",serverPort] forKey:@"ManualPort"];
	
	
	[manualHost resignFirstResponder];
	[manualPort resignFirstResponder];
	
	[utils.communicator initalizeConnectionForServer:serverHost WithPort:serverPort];
	
	if (![self openStreams]) {
		[self _showAlert:@"Unable to connect"];
		return;
	}
	if (![self requestUsers]) {
		return;
	}
	[self requestLogin];
	[utils.communicator sendPunchesFromContext:managedObjectContext];
}

#pragma mark -
#pragma mark Data Processing
- (void) updateUsers:(NSArray *)newUsers{
    if ([newUsers count]==0)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Data error" message:@"No users recieved from desktop." delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
        [alertView show];
        [alertView release];
        return;
    }
	
	NSMutableDictionary *temp;
	if ([self passwordsDict]) {
		temp=[NSMutableDictionary dictionaryWithDictionary:usersDict];
	}
	else {
		temp=[NSMutableDictionary dictionaryWithCapacity:1];
	}
	
	NSString *user,*password;
	
	for (int userNum=0; userNum<[newUsers count]; userNum+=2) {
		user=[NSString stringWithString:[newUsers objectAtIndex:userNum]];
		password=[NSString stringWithString:[newUsers objectAtIndex:userNum+1]];
		[temp setObject:password forKey:user];
	}
	self.passwordsDict=temp;
	
	self.arrayUsers=[NSArray arrayWithArray:[[passwordsDict allKeys] sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]];
	//get last punch type for each user
	updatedCount=0;
	NSUInteger i, count = [arrayUsers count];
	for (i = 0; i < count; i++) {
		NSString * user = [arrayUsers objectAtIndex:i];
		NSString * requestString=[NSString stringWithFormat:@"GetPunchType\n%@|",user];
		[utils.communicator sendDataWithData:[requestString dataUsingEncoding:NSASCIIStringEncoding]];
		//[self send:[requestString dataUsingEncoding:NSASCIIStringEncoding]];
	}
}

-(void) updatePunches:(NSArray *)punchInfo{
	updatedCount++;
	NSString *user=[punchInfo objectAtIndex:1];
	NSString *punchType=([[punchInfo objectAtIndex:0] isEqualToString:@"in"]?@"out":@"in");
	
	NSMutableDictionary *temp;
	if ([self usersDict]) {
		temp=[NSMutableDictionary dictionaryWithDictionary:usersDict];
	}
	else {
		temp=[NSMutableDictionary dictionaryWithCapacity:1];
	}
	
	[temp setObject:punchType forKey:user];
	self.usersDict=temp;
	if (updatedCount==[arrayUsers count]) { //we have all the user info
		[self finishSync];
	}
}


- (void) finishSync
{
	NSDate *curDate=[NSDate dateWithTimeIntervalSinceNow:0];
	NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[[NSUserDefaults standardUserDefaults] setValue:[dateFormatter stringFromDate:curDate] forKey:@"LastSync"];
	[dateFormatter release];
	[syncLabel setText:[NSString stringWithFormat:@"Last Sync: %@",
						[[NSUserDefaults standardUserDefaults] stringForKey:@"LastSync"]]];
	self.needsActivityIndicator=NO;
	NSIndexPath* indexPath = [NSIndexPath indexPathForRow:[self.services indexOfObject:self.lastResolve] inSection:0];
	if (indexPath.row != NSNotFound) {
		[self.tableView deselectRowAtIndexPath:indexPath animated:YES];
		[self.tableView reloadRowsAtIndexPaths:[NSArray	arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationNone];
	}
	
	[[NSUserDefaults standardUserDefaults] setObject:usersDict forKey:@"users"]; //save users to settings file
	[[NSUserDefaults standardUserDefaults] setObject:passwordsDict forKey:@"passwords"];
	
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sync Complete" message:nil delegate:nil cancelButtonTitle:nil otherButtonTitles:@"Continue", nil]; //display a complete message
	[alertView show];
	[alertView release];
	
	[utils.communicator closeConnection];
}

- (void) processDataWithData:(NSData *)data {
	NSString *dataString=[NSString stringWithCString:[data bytes] encoding:NSASCIIStringEncoding];
	
	//trim any non-printing/non-alphanumeric characters from the ends
	dataString=[dataString stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
	
	//NSLog(@"Data Recieved: %@",dataString);
	
	NSArray *commands=[dataString componentsSeparatedByString:@"|"];
	NSUInteger i, count = [commands count];
	for (i = 0; i < count; i++) {
		NSString * command = [commands objectAtIndex:i];
		if ([command hasPrefix:@"users"]) {
			NSMutableArray *recData=[NSMutableArray arrayWithArray:[command componentsSeparatedByString:@"\n"]];
			[recData removeObjectAtIndex:0];
			[self updateUsers:recData];
		}
		else if ([command hasPrefix:@"PunchType"]) {
			NSMutableArray *recData=[NSMutableArray arrayWithArray:[command componentsSeparatedByString:@"\n"]];
			[recData removeObjectAtIndex:0];
			[self updatePunches:recData];
		}
		else if ([command hasPrefix:@"LoginInfo"]) {
			NSMutableArray *recData=[NSMutableArray arrayWithArray:[command componentsSeparatedByString:@"\n"]];
			[recData removeObjectAtIndex:0];
			NSString *loginValue=[recData objectAtIndex:0];
			[[NSUserDefaults standardUserDefaults] setValue:loginValue forKey:@"login"];
		}
	}
}

- (void) processData:(NSNotification *)notification {
	NSData * data=[[notification userInfo] objectForKey:@"data"];
	NSString *dataString=[NSString stringWithCString:[data bytes] encoding:NSASCIIStringEncoding];
	
	//trim any non-printing/non-alphanumeric characters from the ends
	dataString=[dataString stringByTrimmingCharactersInSet:[[NSCharacterSet alphanumericCharacterSet] invertedSet]];
	
	//NSLog(@"Data Recieved: %@",dataString);
	
	NSArray *commands=[dataString componentsSeparatedByString:@"|"];
	NSUInteger i, count = [commands count];
	for (i = 0; i < count; i++) {
		NSString * command = [commands objectAtIndex:i];
		if ([command hasPrefix:@"users"]) {
			NSMutableArray *recData=[NSMutableArray arrayWithArray:[command componentsSeparatedByString:@"\n"]];
			[recData removeObjectAtIndex:0];
			[self updateUsers:recData];
		}
		else if ([command hasPrefix:@"PunchType"]) {
			NSMutableArray *recData=[NSMutableArray arrayWithArray:[command componentsSeparatedByString:@"\n"]];
			[recData removeObjectAtIndex:0];
			[self updatePunches:recData];
		}
		else if ([command hasPrefix:@"LoginInfo"]) {
			NSMutableArray *recData=[NSMutableArray arrayWithArray:[command componentsSeparatedByString:@"\n"]];
			[recData removeObjectAtIndex:0];
			NSString *loginValue=[recData objectAtIndex:0];
			[[NSUserDefaults standardUserDefaults] setValue:loginValue forKey:@"login"];
		}
	}
}
@end


@implementation syncViewController (NSStreamDelegate)

//- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
//{
//	switch(eventCode) {
//		case NSStreamEventHasBytesAvailable:
//		{
//			char b[255]="\0";
//			NSMutableData *data=[NSMutableData dataWithCapacity:0];
//			unsigned int len = 0;
//			while([(NSInputStream *)stream hasBytesAvailable])
//			{
//				len = [(NSInputStream *)stream read:(unsigned char *)b maxLength:254];
//				
//				if(!len) {
//					if ([stream streamStatus] != NSStreamStatusAtEnd)
//						[self _showAlert:@"Failed reading data from peer"];
//					else 
//						return;
//				} else {
//					//data recieved, append to data object
//					b[len]='\0'; //make sure we have a terminating null
//					[data appendBytes:b length:len];
//				}
//			}
//			//extract data
//			[self processDataWithData:data];
//			//}
//			break;
//		}
//		case NSStreamEventErrorOccurred:
//		{
//			//NSLog(@"%@", _cmd);
//			[self _showAlert:@"Error encountered on stream!"];			
//			break;
//		}
//			
//		case NSStreamEventEndEncountered:
//		{
//			UIAlertView	*alertView;
//			alertView = [[UIAlertView alloc] initWithTitle:@"Transfer Interupted" message:@"Remote host closed connection" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
//			[alertView show];
//			[alertView release];
//			break;
//		}
//	}
//}

@end
