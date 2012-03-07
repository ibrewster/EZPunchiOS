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


@implementation EZCommunicator

@synthesize inStream;
@synthesize outStream;
@synthesize initalized;
@synthesize serverAddr;
@synthesize serverPort;

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
	[inStream setDelegate:delegate];
	[outStream setDelegate:delegate];
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

-(void) showAlert:(NSString *)alertData
{
	UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertData message:@"Check your networking configuration." delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
	[alertView show];
	[alertView release];

}
@end
