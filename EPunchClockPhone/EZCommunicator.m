//
//  EZCommunicator.m
//  EZPunchPhone
//
//  Created by Israel Brewster on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EZCommunicator.h"

@implementation EZCommunicator

@synthesize inStream;
@synthesize outStream;

-(void) initalizeConnectionForServer:(NSString *)server WithPort:(int)port
{
    NSString *hostname=server;
    
    CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)hostname, port, &readStream, &writeStream);
    
    [self setInStream:(NSInputStream *)readStream];
    [self setOutStream:(NSOutputStream *)writeStream];
}

-(BOOL) openConnection
{
    [inStream open];
    [outStream open];
    
    //wait for inStream to open or error
    while ([inStream streamStatus]==NSStreamStatusOpening) {};
    NSStreamStatus inStatus=[inStream streamStatus];
    
    //wait for outStream to open or error
    while ([outStream streamStatus]==NSStreamStatusOpening) {};
    NSStreamStatus outStatus=[outStream streamStatus];

    if(inStatus!=NSStreamStatusOpen || outStatus!=NSStreamStatusOpen)
    {
        [self closeConnection]; //probably not needed, since we never reached an open state
        return NO;
    }
    
    return YES;
}

-(BOOL) connectToServer:(NSString *)server WithPort:(int)port
{
    [self initalizeConnectionForServer:server WithPort:port];
    return [self openConnection];
}

-(void) closeConnection
{
    [inStream close];
    [outStream close];
}

-(BOOL) sendDataWithData:(NSData *)data
{
    unsigned short int waitCount=0; //counter for timeout to avoid infinite loop
	while(!(outStream && [outStream hasSpaceAvailable]) && waitCount<15)
	{
		if ([inStream streamStatus]==NSStreamStatusError || [outStream streamStatus]==NSStreamStatusError) {
			//stream error - no sense in waiting
			//[self _showAlert:@"Communications Error"];
			NSLog(@"Input Stream Status: %i",[inStream streamStatus]);
			NSLog(@"Output Stream Status: %i",[outStream streamStatus]);
			NSLog(@"Input Stream Error Code: %i, userInfo: %@",[[inStream streamError] code],[[inStream streamError] userInfo]);
			NSLog(@"Output Stream Error Code: %i, userInfo: %@",[[outStream streamError] code],[[outStream streamError]userInfo]);
			return NO;
		}
		sleep(1);
		waitCount++;
	}
	if(waitCount<15)
	{
		if (outStream) //&& [_outStream hasSpaceAvailable])
			if([outStream write:(const uint8_t *)[data bytes] maxLength:[data length]] == -1)
			{
				//[self _showAlert:@"Failed sending data to peer"];
				return NO;
			}
			else
				return YES;
            else
                return NO;
	}
	else
	{
		//[self _showAlert:@"Timeout waiting to send data."];
		NSLog(@"Input Stream Status: %i",[inStream streamStatus]);
		NSLog(@"Output Stream Status: %i",[outStream streamStatus]);
		NSLog(@"Input Stream Error Code: %i, userInfo: %@",[[inStream streamError] code],[[inStream streamError] userInfo]);
		NSLog(@"Output Stream Error Code: %i, userInfo: %@",[[outStream streamError] code],[[outStream streamError]userInfo]);
		return NO;
	}
	return NO; //should never get here
}

@end
