//
//  MainViewController.h
//  TimeClock4iPhone
//
//  Created by israel on 8/19/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#import "Utilities.h"

@interface MainViewController : UIViewController <UITextFieldDelegate, UIAlertViewDelegate>{
	//id <MainViewControllerDelegate> delegate;
	UITextField *textField;
	UILabel *timeLabel;
	UILabel *userLabel;
	NSTimer	*updateTimer;
	NSDate *currentDate;
	NSString *punchtype;
	bool useTimeRounding;
	IBOutlet UIButton *punchButton;
	NSMutableDictionary *usersDict;
	
	Utilities *utils;
    
    NSManagedObjectContext *managedObjectContext;	    
}

@property (assign) NSTimer *updateTimer;
@property (nonatomic, retain) NSMutableDictionary *usersDict;
@property (nonatomic, retain) IBOutlet UITextField *textField;
@property (nonatomic, retain) IBOutlet UILabel *timeLabel;
@property (nonatomic, retain) IBOutlet UILabel *userLabel;
@property (nonatomic, retain) NSDate *currentDate;
@property (nonatomic, retain) Utilities *utils;

- (IBAction)saveAction:sender;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

//@property (nonatomic, assign) id <MainViewControllerDelegate> delegate;


- (IBAction)startRepeatingTimer:(id)sender;
- (IBAction)stopRepeatingTimer:(id)sender;
- (IBAction)setTime:(id)sender;
- (IBAction)punchButtonPressed:(id)sender;
- (void) finalizePunch:(NSNotification *)notification;
- (void) recordNetworkPunch:(NSNotification *)notificication;
- (void) recordNetworkPunchStageTwo:(NSNotification *)notification;
- (void) recordLocalPunch:(NSNotification *)notificication;
//- (IBAction)showInfo;
- (IBAction)updatePunchType;
- (void)recievePunchType:(NSNotification *)notification;
- (void)setUtilsWithUtils:(Utilities *)newUtils;
- (void) requestPunchType:(NSNotification *)notificiation;
- (void) checkForLocalPunches;
- (void) runViewLoadChecks:(NSNotification *) notification;

@end

//@protocol MainViewControllerDelegate
//@property (nonatomic, retain) NSArray *usersDict;
//@end
