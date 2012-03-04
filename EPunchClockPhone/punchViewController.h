//
//  punchView.h
//  EPunchClockPhone
//
//  Created by israel on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"


@interface punchViewController : UIViewController <UITableViewDataSource,UITableViewDelegate>{
    Utilities *utils;
	UITableView	*tableView;
	UILabel *headerLabel;
	
	NSManagedObjectContext *managedObjectContext;
	NSArray *fetchResults;
	
	NSArray *users;
	NSMutableDictionary *punchCounts;
}

@property (nonatomic, assign) IBOutlet UILabel *headerLabel;
@property (nonatomic, retain) Utilities *utils;
@property (nonatomic, retain) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, assign) IBOutlet UITableView *tableView;

@end
