//
//  EZCommunicator.h
//  EZPunchPhone
//
//  Created by Israel Brewster on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EZCommunicator : NSObject

@property (nonatomic, retain) NSInputStream * inStream;
@property (nonatomic, retain) NSOutputStream * outStream;

-(void) initalizeConnectionForServer:(NSString *)server WithPort:(int)port;
-(BOOL) connectToServer:(NSString *)server WithPort:(int)port;
-(BOOL) openConnection;
-(void) closeConnection;
-(BOOL) sendDataWithData:(NSData *)data;
@end
