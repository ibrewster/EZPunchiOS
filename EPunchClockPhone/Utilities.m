//
//  Utilities.m
//  EPunchClockPhone
//
//  Created by israel on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Utilities.h"
#import "EPunchClockPhoneAppDelegate.h"

//BOOL checkNetwork()
//{
//    NSString *hostname=[[NSUserDefaults standardUserDefaults] stringForKey:@"ManualHost"];
//    NSString *portString=[[NSUserDefaults standardUserDefaults] stringForKey:@"ManualPort"];
//    if(hostname==nil || portString==nil)
//        return NO;
//    int port=[portString intValue];
//    CFReadStreamRef readStream;
//	CFWriteStreamRef writeStream;
//	CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)hostname, port, &readStream, &writeStream);
//	
//	if(!readStream || !writeStream)
//	{
//		return NO;
//	}
//    NSInputStream * readNSStream=(NSInputStream *)readStream;
//    NSOutputStream * writeNSStream=(NSOutputStream *)writeStream;
//    [readNSStream open];
//    [writeNSStream open];
//    NSStreamStatus inStreamStatus=[readNSStream streamStatus];
//    NSStreamStatus outStreamStatus=[writeNSStream streamStatus];
//    
//	int loopCount=0;
//    while (inStreamStatus==NSStreamStatusOpening && loopCount<8) {
//        inStreamStatus=[readNSStream streamStatus];
//		[NSThread sleepForTimeInterval:.25];
//		loopCount++;
//    }
//    
//    outStreamStatus=[writeNSStream streamStatus];
//    
//    if(inStreamStatus!=NSStreamStatusOpen || 
//       outStreamStatus!=NSStreamStatusOpen)
//    {
//        [readNSStream close];
//        [writeNSStream close];
//        return NO;
//    }
//    [readNSStream close];
//    [writeNSStream close];
//    return YES;
//}

NSData *encodePunchForSending(NSString *user, NSString *type,NSString *date, NSString *time, NSString *notes)
{
    NSMutableString *data=[NSMutableString stringWithCapacity:20];
    [data setString:@"NewPunch\n"];
    [data appendFormat:@"%@\n",user];
    [data appendFormat:@"%@\n",type];
    [data appendFormat:@"%@T%@\n",date,time];
    
    if(notes==nil)
        notes=@"";
    [data appendFormat:@"%@\n",notes];
	
	//get the current location.
	EPunchClockPhoneAppDelegate *app=(EPunchClockPhoneAppDelegate *)[[UIApplication sharedApplication] delegate];
    NSString *location=app.deviceLocation;
	
    if (location==nil || [location isEqualToString:@""]) {
        location=@"iPhone";
    }
	
    [data appendFormat:@"%@|",location];
    return [data dataUsingEncoding:NSASCIIStringEncoding];
}

@implementation Utilities

@synthesize managedObjectContext;
@synthesize communicator;

-(id) init
{
	self=[super init];
	if(self){
		managedObjectContext=[self managedObjectContext];
        communicator=[[[EZCommunicator alloc] init] retain];
	}
	return self;
}

#pragma mark -
#pragma mark Core Data stack

/**
 Returns the managed object context for the application.
 If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
 */
- (NSManagedObjectContext *) managedObjectContext {
	
    if (managedObjectContext != nil) {
        return managedObjectContext;
    }
	
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        managedObjectContext = [[NSManagedObjectContext alloc] init];
        [managedObjectContext setPersistentStoreCoordinator: coordinator];
    }
    return managedObjectContext;
}

/**
 Returns the persistent store coordinator for the application.
 If the coordinator doesn't already exist, it is created and the application's store added to it.
 */
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
	
    if (persistentStoreCoordinator != nil) {
        return persistentStoreCoordinator;
    }
	
    NSURL *storeUrl = [NSURL fileURLWithPath: [[self applicationDocumentsDirectory] stringByAppendingPathComponent: @"Punches.sqlite"]];
	
	NSError *error;
    persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel: [self managedObjectModel]];
    if (![persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeUrl options:nil error:&error]) {
        // Handle error
    }    
	
    return persistentStoreCoordinator;
}

/**
 Returns the managed object model for the application.
 If the model doesn't already exist, it is created by merging all of the models found in the application bundle.
 */
- (NSManagedObjectModel *)managedObjectModel {
	
    if (managedObjectModel != nil) {
        return managedObjectModel;
    }
    managedObjectModel = [[NSManagedObjectModel mergedModelFromBundles:nil] retain];    
    return managedObjectModel;
}

#pragma mark -
#pragma mark Application's documents directory

/**
 Returns the path to the application's documents directory.
 */
- (NSString *)applicationDocumentsDirectory {
	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    return basePath;
}

-(void) dealloc{
	[managedObjectModel release];
    [persistentStoreCoordinator release];
	[super dealloc];
}


@end
