//
//  punchView.m
//  EPunchClockPhone
//
//  Created by israel on 4/25/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "punchViewController.h"
#import "punches.h"


@implementation punchViewController

@synthesize utils;
@synthesize managedObjectContext;
@synthesize tableView;
@synthesize headerLabel;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	managedObjectContext=[utils managedObjectContext];
	punchCounts=[[NSMutableDictionary dictionaryWithCapacity:0] retain];
	
	headerLabel.textColor = [UIColor colorWithRed: 76/255.0 green: 86/255.0 blue: 108/255.0 alpha:1.0];
	headerLabel.font=[UIFont boldSystemFontOfSize:17];
	headerLabel.shadowColor=[UIColor whiteColor];
	headerLabel.shadowOffset=CGSizeMake(0.0, 1.0);
	
	// Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
	[managedObjectContext release];
	[punchCounts release];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated{
	if (users==nil) {
		users=[[[[[NSUserDefaults standardUserDefaults]
				  dictionaryForKey:@"users"]
				 allKeys]
				sortedArrayUsingSelector:@selector(caseInsensitiveCompare:)]
			   retain];

	}
	
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	
	
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"punches" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	NSSortDescriptor *dateColumn = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:dateColumn, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[dateColumn release];
	
	NSError *error;
	fetchResults = [[managedObjectContext executeFetchRequest:request error:&error] retain];
	if (fetchResults == nil) {
        // Handle the error.
	}
	NSInteger count=0;
	for (NSString *user in users) {
		count=0;
		for (punches *punch in fetchResults) {
			if ([punch.user isEqualToString:user]) {
				count++;
			}
		}
		[punchCounts setValue:[NSNumber numberWithInteger:count] forKey:user];
	}
	[tableView reloadData];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
	[users release];
	users=nil;
	[fetchResults release];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

#pragma mark -
#pragma mark TableViewDelegate code
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
	NSNumber *count=[punchCounts valueForKey:[users objectAtIndex:section]];
	return [count integerValue];
	
}

// Row display. Implementers should *always* try to reuse cells by setting each cell's reuseIdentifier and querying for available reusable cells with dequeueReusableCellWithIdentifier:
// Cell gets various attributes set automatically based on table (separators) and data source (accessory views, editing controls)

- (UITableViewCell *)tableView:(UITableView *)tableView2 cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	static NSString *tableCellIdentifier = @"UITableViewCell";
	UITableViewCell *cell = (UITableViewCell *)[tableView2 dequeueReusableCellWithIdentifier:tableCellIdentifier];
	if (cell == nil) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:tableCellIdentifier] autorelease];
	}
	
	NSDate* punchDate;
	
	NSDateFormatter *punchParser=[[[NSDateFormatter alloc] init] autorelease];
	[punchParser setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss"];
	
	NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
	[dateFormatter setDateStyle:NSDateFormatterShortStyle];
	[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
	
	NSInteger count=-1;
	for (punches *punch in fetchResults) {
		if ([punch.user isEqualToString:[users objectAtIndex:indexPath.section]]) {
			count++;
			if (count==indexPath.row) {
				punchDate=[punchParser dateFromString:[NSString stringWithFormat:@"%@T%@",punch.punchdate,punch.punchtime]];
				cell.textLabel.text=[[NSString stringWithFormat:@"%@ - %@",
									  punch.punchtype,
									  [dateFormatter stringFromDate:punchDate]
									  ] uppercaseString];
			}
		}
	}
	
	return cell;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
	return [users count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    // The header for the section is the user name
    return [users objectAtIndex:section];
}

@end
