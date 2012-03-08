//
//  EZCommunicator.m
//  EZPunchPhone
//
//  Created by Israel Brewster on 3/4/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "EZCommunicator.h"
#import "punches.h"
#import "Utilities.h"
#import "Reachability.h"

@implementation EZCommunicator

@synthesize inStream;
@synthesize outStream;
@synthesize initalized;
@synthesize serverAddr;
@synthesize serverPort;
@synthesize recievedData;
@synthesize checkOutStream;
@synthesize checkInStream;
@synthesize checkTimer;

-(id)init
{
	self=[super init];
	[self setInitalized:NO];
	return self;
}

-(void) initalizeConnectionForServer:(NSString *)server WithPort:(int)port
{
	assert(server != nil);
    assert( (port > 0) && (port < 65536) );
	
	if ([self inStream]) {
		[[self inStream] close];
		[[self inStream] release];
	}
	
	if([self outStream])
	{
		[[self outStream]close];
		[[self outStream] release];
	}
	[self setServerAddr:server];
	[self setServerPort:port];
	
    CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	
	readStream=NULL;
	writeStream=NULL;
	
	CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)server, port, &readStream, &writeStream);
    
    [self setInStream:(NSInputStream *)readStream];
    [self setOutStream:(NSOutputStream *)writeStream];
	[inStream setDelegate:self];
	[outStream setDelegate:self];
	[self setInitalized:YES];
}

-(BOOL) openConnection
{
	NSStreamStatus inStatus=[inStream streamStatus];    
	NSStreamStatus outStatus=[outStream streamStatus];
	
	//if we had closed the connection (or there is a connection error) try re-initalizing
	if(inStatus!=NSStreamStatusNotOpen || outStatus!=NSStreamStatusNotOpen)
		[self initalizeConnectionForServer:[self serverAddr] WithPort:[self serverPort]];
	
	[inStream open];
    [outStream open];
    
    //wait for inStream to open or error
    while ([inStream streamStatus]==NSStreamStatusOpening) {};
    inStatus=[inStream streamStatus];
    
    //wait for outStream to open or error
    while ([outStream streamStatus]==NSStreamStatusOpening) {};
    outStatus=[outStream streamStatus];

    if(inStatus!=NSStreamStatusOpen || outStatus!=NSStreamStatusOpen)
    {
		NSLog(@"Stream error in: %@, out: %@",[inStream streamError],[outStream streamError]);
        [self closeConnection]; //probably not needed, since we never reached an open state
        return NO;
    }
    
	[inStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[outStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];

    return YES;
}

-(void)setStreamDelegates:(id)delegate
{
//	[inStream setDelegate:delegate];
//	[outStream setDelegate:delegate];
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
		if([outStream write:(const uint8_t *)[data bytes] maxLength:[data length]] == -1)
		{
			NSLog(@"Stream status: %i",[outStream streamStatus]);
			NSLog(@"Write error occured: %@",[outStream streamError]);
			[self showAlert:@"Failed sending data to peer"];
			return NO;
		}
		else
			return YES;
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

- (void) sendPunchesFromContext:(NSManagedObjectContext *)managedObjectContext{
	NSFetchRequest *request = [[NSFetchRequest alloc] init];
	NSEntityDescription *entity = [NSEntityDescription entityForName:@"punches" inManagedObjectContext:managedObjectContext];
	[request setEntity:entity];
	NSSortDescriptor *dateColumn = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:YES];
	NSArray *sortDescriptors = [[NSArray alloc] initWithObjects:dateColumn, nil];
	[request setSortDescriptors:sortDescriptors];
	[sortDescriptors release];
	[dateColumn release];
	
	NSError *error;
	NSArray *fetchResults = [managedObjectContext executeFetchRequest:request error:&error];
	punches *punch;
	if (fetchResults == nil) {
		[request release];
		return; //no punches to send
	}
	
    //submit each punch to the server
	for (int i=0; i<[fetchResults count]; i++) {
		//		[data setString:@"NewPunch\n"];
		punch=[fetchResults objectAtIndex:i];
        NSData *punchData=encodePunchForSending(punch.user, punch.punchtype, 
                                                punch.punchdate, punch.punchtime, 
                                                punch.notes);
		[self sendDataWithData:punchData];
	}
	
    //clear the punch database
	for (NSManagedObject *managedObject in fetchResults) {
        [managedObjectContext deleteObject:managedObject];
        //NSLog(@"%@ object deleted",@"punches");
    }
    if (![managedObjectContext save:&error]) {
        NSLog(@"Error deleting %@ - error:%@",@"punches",[error userInfo]);
    }
	
	[request release];
	
}

- (void) stream:(NSStream *)stream handleEvent:(NSStreamEvent)eventCode
{
	switch(eventCode) {
		case NSStreamEventHasBytesAvailable:
		{
			unsigned char b[255]="\0";
			NSMutableData *data=[NSMutableData dataWithCapacity:0];
			unsigned int len = 0;
			while([(NSInputStream *)stream hasBytesAvailable])
			{
				len = [(NSInputStream *)stream read:b maxLength:254];
				
				if(!len) {
					if ([stream streamStatus] != NSStreamStatusAtEnd)
						[self showAlert:@"Failed reading data from peer"];
					else 
						return;
				} else {
					//data recieved, append to data object
					b[len]='\0'; //make sure we have a terminating null
					[data appendBytes:b length:len];
				}
			}
			//[self.recievedData appendData:data];
			[[NSNotificationCenter defaultCenter] postNotificationName:@"EZPDataRecieved" 
																object:self
															  userInfo:[NSDictionary dictionaryWithObject:data forKey:@"data"]];
			break;
		}
		case NSStreamEventErrorOccurred:
		{
			//NSLog(@"%@", _cmd);
			//[self showAlert:@"Error encountered on stream!"];
			if (stream==checkOutStream) {
				[checkTimer invalidate];
				[[NSNotificationCenter defaultCenter] postNotificationName:@"EZPServerUnreachable" 
																	object:self
																  userInfo:nil];
			}
			break;
		}
			
		case NSStreamEventEndEncountered:
		{
			UIAlertView	*alertView;
			alertView = [[UIAlertView alloc] initWithTitle:@"Transfer Interupted" message:@"Remote host closed connection" delegate:self cancelButtonTitle:nil otherButtonTitles:@"Continue", nil];
			[alertView show];
			[alertView release];
			break;
		}
		case NSStreamEventOpenCompleted:
		{
			if(stream==checkOutStream)
			{
				//only send one notification for the in/out pair
				//I arbitrarily chose to do it for the output stream
				[[NSNotificationCenter defaultCenter] postNotificationName:@"EZPServerReachable" 
																	object:self
																  userInfo:nil];
				[checkOutStream close];
				[checkOutStream release];
				[checkTimer invalidate];
			}
			if(stream==checkInStream)
			{
				[checkInStream close];
				[checkInStream release];
			}
		}
	}
}

-(NSData *)read
{
	NSData *data=[NSData dataWithData:recievedData];
	[self.recievedData setLength:0];
	return data;
}

-(void) showAlert:(NSString *)alertData
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertData message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];

}

-(void) checkNetwork
{
    NSString *hostname=[[NSUserDefaults standardUserDefaults] stringForKey:@"ManualHost"];
	
	Reachability *hostReachable=[Reachability reachabilityWithHostName:hostname];
    NetworkStatus status=[hostReachable currentReachabilityStatus];
	if (status==NotReachable) { //no network/wrong network. stop trying immediately.
		[[NSNotificationCenter defaultCenter] postNotificationName:@"EZPServerUnreachable" 
															object:self
														  userInfo:nil];
		return;
	}

	
    NSString *portString=[[NSUserDefaults standardUserDefaults] stringForKey:@"ManualPort"];
    if(hostname==nil || portString==nil)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"EZPServerUnreachable" 
															object:self
														  userInfo:nil];
		return;
	}
    int port=[portString intValue];
    CFReadStreamRef readStream;
	CFWriteStreamRef writeStream;
	CFStreamCreatePairWithSocketToHost(NULL, (CFStringRef)hostname, port, &readStream, &writeStream);
	
	if(!readStream || !writeStream)
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"EZPServerUnreachable" 
															object:self
														  userInfo:nil];
		return;
	}
	
	//just try the write stream - we only care if we can reach the server, we're not
	//trying to actually DO anything.
    [self setCheckOutStream:(NSOutputStream *)writeStream];
	[self setCheckInStream:(NSInputStream *)readStream];
	[checkOutStream setDelegate:self];
	[checkInStream setDelegate:self];
    [checkOutStream open];
	[checkInStream open];
	[checkOutStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	[checkInStream scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
	
	//set a two second timeout on trying to connect so the program doesn't hang
	checkTimer= [NSTimer scheduledTimerWithTimeInterval:2.0
												  target:self selector:@selector(checkTimeout:)
												userInfo:nil repeats:NO];

}

 -(IBAction)checkTimeout:(id)sender
{
	[checkInStream close];
	[checkOutStream close];
	[checkInStream release];
	[checkOutStream release];
	[[NSNotificationCenter defaultCenter] postNotificationName:@"EZPServerUnreachable" 
														object:self
													  userInfo:nil];
	[checkTimer invalidate];
}
@end
