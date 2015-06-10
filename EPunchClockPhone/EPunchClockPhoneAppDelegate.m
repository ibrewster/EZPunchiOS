//
//  EPunchClockPhoneAppDelegate.m
//  EPunchClockPhone
//
//  Created by Macavenger on 4/23/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "EPunchClockPhoneAppDelegate.h"
#import "syncViewController.h"
#import "MainViewController.h"
#import "punchViewController.h"
#import "loginViewController.h"


@implementation EPunchClockPhoneAppDelegate


@synthesize window=_window;
@synthesize locationManager;
@synthesize deviceLocation;

@synthesize tabBarController=_tabBarController;
@synthesize navigationController=_navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	//configure location manager and start checking for updates
	if (locationManager==nil) {
		locationManager=[[CLLocationManager alloc] init];
	}
	locationManager.delegate=self;
	
	locationManager.delegate=self;
	if ([CLLocationManager locationServicesEnabled] ){
		locationManager.desiredAccuracy=kCLLocationAccuracyBest;
		locationManager.distanceFilter=500; //only update if they move half a klick or more
		[locationManager requestWhenInUseAuthorization];
		[locationManager startUpdatingLocation];
	}
	
	id checkForWarnSetting=[[NSUserDefaults standardUserDefaults] objectForKey:@"showLocalWarning"];
	
	if(checkForWarnSetting==nil) //key does not exist
		[[NSUserDefaults standardUserDefaults]setBool:YES forKey:@"showLocalWarning"];
    // Override point for customization after application launch.
    // Add the tab bar controller's current view as a subview of the window
	
	self.window.rootViewController=self.navigationController;
	loginViewController *loginView=[[self.navigationController viewControllers] objectAtIndex:0];
	[loginView setAppDelegate:self];
	
	//see if we need to sync first
	//Load the user list and last punches
    NSDictionary *usersDict=[NSMutableDictionary dictionaryWithDictionary:[[NSUserDefaults standardUserDefaults] dictionaryForKey:@"users"]];
    
    //if no users, don't log in
	//NSString *loginReq=[[NSUserDefaults standardUserDefaults] valueForKey:@"login"];
    if([usersDict count]==0)
    {
		[self.navigationController pushViewController:self.tabBarController animated:YES];
		pushedController=true;
    }	

    //self.window.rootViewController = self.tabBarController;
	util=[[Utilities alloc] init];
	
	NSString *hostname=[[NSUserDefaults standardUserDefaults] stringForKey:@"ManualHost"];
    NSString *portString=[[NSUserDefaults standardUserDefaults] stringForKey:@"ManualPort"];
    if(hostname!=nil || portString!=nil)
	{
		int port=[portString intValue];
		[util.communicator initalizeConnectionForServer:hostname WithPort:port];
	}
	NSArray *views=[self.tabBarController viewControllers];
	
	punchViewController *punchesTab=[views objectAtIndex:2];
	[punchesTab setUtils:util];
	MainViewController *mainTab=[views objectAtIndex:0];
	[mainTab setUtilsWithUtils:util];
	syncViewController *syncTab=[views objectAtIndex:3];
	[syncTab setUtils:util];
	
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    /*
     Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
     Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
     */
	if(locationManager!=nil){
		[locationManager stopUpdatingLocation];
	}
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    /*
     Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
     If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
     */
	NSArray *viewControllers=[self.navigationController viewControllers];
	
	if ([viewControllers containsObject:self.tabBarController] && 
		[[[NSUserDefaults standardUserDefaults] valueForKey:@"login"] isEqualToString:@"True"]) {
		[self.navigationController popViewControllerAnimated:NO];
		pushedController=false;
	}
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    /*
     Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
     */
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    /*
     Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
     */
	if(locationManager!=nil){
		[locationManager startUpdatingLocation];
	}
	
	NSArray *viewControllers=[self.navigationController viewControllers];
	
	if(!pushedController && ![viewControllers containsObject:self.tabBarController] && ![[[NSUserDefaults standardUserDefaults] valueForKey:@"login"] isEqualToString:@"True"])
    {
		[self.navigationController pushViewController:self.tabBarController animated:NO];
		pushedController=true;
    }	
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    /*
     Called when the application is about to terminate.
     Save data if appropriate.
     See also applicationDidEnterBackground:.
     */
}

- (void)dealloc
{
    [_window release];
    [_tabBarController release];
    [super dealloc];
}

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didSelectViewController:(UIViewController *)viewController
{
}
*/

/*
// Optional UITabBarControllerDelegate method.
- (void)tabBarController:(UITabBarController *)tabBarController didEndCustomizingViewControllers:(NSArray *)viewControllers changed:(BOOL)changed
{
}
*/

- (IBAction)submitLogin:(id)sender withUser:(NSString *)user
{
	
	[self.navigationController pushViewController:self.tabBarController animated:YES];
	pushedController=true;
}

#pragma mark -
#pragma mark Core Location Delegate
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	CLLocation *location = [locations lastObject];
	CLGeocoder *geocoder=[[CLGeocoder alloc]init];

	[geocoder reverseGeocodeLocation:location completionHandler:^(NSArray *placemarks, NSError *error)
	 {
		 if (deviceLocation!=nil) {
			 [deviceLocation release]; //let my old strings go!
		 }
		 
		 if (error == nil && [placemarks count] > 0)
		 {
			 // CLPlacemark * placemark = [placemarks lastObject];
			 CLPlacemark * placemark = [placemarks objectAtIndex:0];
			 
			 // strAdd -> take bydefault value nil
			 NSString *strAdd = nil;
			 
			 if ([placemark.subThoroughfare length] != 0)
				 strAdd = placemark.subThoroughfare;
			 
			 if ([placemark.thoroughfare length] != 0)
			 {
				 // strAdd -> store value of current location
				 if ([strAdd length] != 0)
					 strAdd = [NSString stringWithFormat:@"%@ %@",strAdd,[placemark thoroughfare]];
				 else
				 {
					 // strAdd -> store only this value,which is not null
					 strAdd = placemark.thoroughfare;
				 }
			 }
			 
			 if ([placemark.postalCode length] != 0)
			 {
				 if ([strAdd length] != 0)
					 strAdd = [NSString stringWithFormat:@"%@, %@",strAdd,[placemark postalCode]];
				 else
					 strAdd = placemark.postalCode;
			 }
			 deviceLocation=[[NSString stringWithString:strAdd] retain];
		 }
		 else{
			 deviceLocation=[[NSString stringWithFormat:@"lat: %f lng: %f",
							 location.coordinate.latitude,
							 location.coordinate.longitude] retain];
		 }
	 }];
	 
//	NSLog(@"latitude %+.6f, longitude %+.6f\n",
//		  location.coordinate.latitude,
//		  location.coordinate.longitude);
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error{
	NSLog(@"%@",error);
}

@end
