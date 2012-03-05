//
//  Utilities.h
//  EPunchClockPhone
//
//  Created by israel on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "EZCommunicator.h"

BOOL checkNetwork();
NSData *encodePunchForSending(NSString *user, NSString *type,NSString *date, NSString *time, NSString *notes);

@interface Utilities : NSObject {
	
	NSManagedObjectContext *managedObjectContext;
    NSManagedObjectModel *managedObjectModel;
    NSPersistentStoreCoordinator *persistentStoreCoordinator;
    EZCommunicator *communicator;
    
}

@property (nonatomic, retain, readonly) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, retain, readonly) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic, retain) EZCommunicator *communicator;
@property (nonatomic, readonly) NSString *applicationDocumentsDirectory;


@end
