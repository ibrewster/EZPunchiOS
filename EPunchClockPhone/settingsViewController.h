//
//  FlipsideViewController.h
//  TimeClock4iPhone
//
//  Created by israel on 8/19/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

@interface settingsViewController : UIViewController <UITextFieldDelegate, UIPickerViewDataSource, UIPickerViewDelegate> {
	UISwitch * roundTimes;
	UITextField *curLocation;
	IBOutlet UIPickerView *currentUser;
	NSMutableArray		*arrayUsers;
	NSTimer				*_timer;
	NSInputStream		*_inStream;
	NSOutputStream		*_outStream;
	BOOL				_inReady;
	BOOL				_outReady;
	int					updatedCount;
	UIWindow			*_window;
		
	NSDictionary		*usersDict;
}

@property (nonatomic, assign) IBOutlet UISwitch *roundTimes;
@property (nonatomic, assign) IBOutlet UITextField *curLocation;
@property (nonatomic, retain) NSDictionary *usersDict;
@property (nonatomic, retain) NSMutableArray *arrayUsers;
@property (nonatomic, assign) UIPickerView *currentUser;
@property (nonatomic, assign) NSManagedObjectContext *managedObjectContext;

- (IBAction)setRound:(id)sender;
- (IBAction)setLocation:(id)sender;

@end