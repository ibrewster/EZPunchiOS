//
//  punches.h
//  TimeClock4iPhone
//
//  Created by israel on 8/21/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <CoreData/CoreData.h>


@interface punches :  NSManagedObject  
{
}

@property (nonatomic, retain) NSString * punchdate;
@property (nonatomic, retain) NSString * punchtype;
@property (nonatomic, retain) NSString * notes;
@property (nonatomic, retain) NSString * punchtime;
@property (nonatomic, retain) NSString * user;
@property (nonatomic, retain) NSDate * timestamp;

@end



