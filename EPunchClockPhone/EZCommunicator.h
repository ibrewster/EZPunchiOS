//
//  EZCommunicator.h
//  EZPunchPhone
//
//  Created by Israel Brewster on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EZCommunicator : NSObject <NSStreamDelegate>

@property (nonatomic, retain) NSInputStream * inStream;
@property (nonatomic, retain) NSOutputStream * outStream;
@property (nonatomic, retain) NSOutputStream * checkOutStream;
@property (nonatomic, retain) NSInputStream * checkInStream;
@property (nonatomic, retain) NSTimer *checkTimer;
@property (nonatomic) BOOL initalized;
@property (nonatomic, retain) NSString *serverAddr;
@property (nonatomic) int serverPort;
@property (nonatomic, retain) NSMutableData *recievedData;

-(void) initalizeConnectionForServer:(NSString *)server WithPort:(int)port;
-(BOOL) connectToServer:(NSString *)server WithPort:(int)port;
-(BOOL) openConnection;
-(void) closeConnection;
-(NSData *)read;
-(void) setStreamDelegates:(id)delegate;
-(BOOL) sendDataWithData:(NSData *)data;
-(void) showAlert:(NSString *)alertData;
- (void) sendPunchesFromContext:(NSManagedObjectContext *)context;
-(void) checkNetwork;
- (IBAction)checkTimeout:(id)sender;

@end
