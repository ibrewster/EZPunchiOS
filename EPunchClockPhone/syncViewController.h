//
//  syncViewController.h
//  TimeClock4iPhone
//
//  Created by israel on 9/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Utilities.h"
#define kProgressIndicatorSize 20.0
@class syncViewController;


@interface syncViewController : UIViewController <NSNetServiceBrowserDelegate, 
NSNetServiceDelegate, UITableViewDelegate, UITableViewDataSource, 
NSStreamDelegate, UITextFieldDelegate, UIAlertViewDelegate> 
{
	//id<syncViewControllerDelegate> _delegate;
	NSMutableArray		*_services;
	UILabel				*syncLabel;
	UITableView			*tableView;
	UITextField			*manualHost;
	UITextField			*manualPort;
	UIButton			*manualSync;
	
	BOOL				_initialWaitOver;
	BOOL				_needsActivityIndicator;
	BOOL				_showDisclosureIndicators;
	NSNetService		*_currentResolve;
	NSNetServiceBrowser *_netServiceBrowser;
	NSString			*_searchingForServicesString;
	NSNetService		*_lastResolve;
	NSNetService		*_ownEntry;
	NSString			*_ownName;
	//NSInputStream		*_inStream;
	//NSOutputStream		*_outStream;
	//BOOL				_inReady;
	//BOOL				_outReady;
	int					updatedCount;
	NSTimer				*_timer;
    NSArray				*arrayUsers;
	NSDictionary		*passwordsDict;
    NSDictionary		*usersDict;
	
	Utilities			*utils;
	UITextField			*activeField;
	BOOL				keyboardShown,viewMoved;

    NSManagedObjectContext *managedObjectContext;
}

@property (nonatomic, retain) IBOutlet UIButton	*manualSync;
@property (nonatomic, retain) IBOutlet UITextField *manualHost;
@property (nonatomic, retain) IBOutlet UITextField *manualPort;
@property (nonatomic, retain) IBOutlet UILabel *syncLabel;
@property (nonatomic, assign) IBOutlet UITableView *tableView;
@property (nonatomic, assign, readwrite) BOOL initialWaitOver;
@property (nonatomic, retain, readwrite) NSMutableArray *services;
@property (nonatomic, retain, readwrite) NSNetService *currentResolve;
@property (nonatomic, retain, readwrite) NSNetServiceBrowser *netServiceBrowser;
@property (nonatomic, assign, readwrite) BOOL needsActivityIndicator;
@property (nonatomic, copy) NSString *searchingForServicesString;
@property (nonatomic, assign, readwrite) BOOL showDisclosureIndicators;
@property (nonatomic, retain, readwrite) NSNetService *lastResolve;
@property (nonatomic, retain, readwrite) NSTimer *timer;
@property (nonatomic, retain, readwrite) NSNetService *ownEntry;
@property (nonatomic, copy) NSString *ownName;
@property (nonatomic, copy) NSArray *arrayUsers;
@property (nonatomic, retain) NSDictionary *usersDict;
@property (nonatomic, retain) NSDictionary *passwordsDict;


@property (nonatomic, retain) Utilities	*utils;

@property (nonatomic, retain, readonly) NSManagedObjectContext *managedObjectContext;

- (void) initialWaitOver:(NSTimer *)timer;
- (BOOL) searchForServicesOfType:(NSString *)type inDomain:(NSString *)domain;
- (void) stopCurrentResolve;
- (void) showWaiting:(NSTimer *)timer;
//- (void) setupNetwork;
- (void) didResolveInstance:(NSNetService *)netService;
- (void) _showAlert:(NSString *)title;
//- (BOOL) send:(NSData *)message;
- (BOOL) openStreams;
- (void) requestLogin;
- (BOOL) requestUsers;
- (void) processDataWithData:(NSData *)data;
- (void) processData:(NSNotification *)notification;
- (void) updateUsers:(NSArray *)newUsers;
- (void) updatePunches:(NSArray *)punchInfo;
- (void) finishSync;
- (IBAction)hideKeyboard:(id)Sender;
- (void) keyboardWasShown:(NSNotification *)aNotification;
- (void) keyboardWasHidden:(NSNotification *)aNotificiation;
- (IBAction)runManualSync:(id)Sender;

@end
