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

@synthesize tabBarController=_tabBarController;
@synthesize navigationController=_navigationController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
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
    }	

    //self.window.rootViewController = self.tabBarController;
	util=[[Utilities alloc] init];
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
	NSArray *viewControllers=[self.navigationController viewControllers];
	
	if(![viewControllers containsObject:self.tabBarController] && ![[[NSUserDefaults standardUserDefaults] valueForKey:@"login"] isEqualToString:@"True"])
    {
		[self.navigationController pushViewController:self.tabBarController animated:NO];
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
}

@end
