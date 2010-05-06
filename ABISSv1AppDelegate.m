//
//  ABISSv1AppDelegate.m
//  ABISSv1
//
//  Created by Andrew Burks on 9/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ABISSv1AppDelegate.h"

@implementation ABISSv1AppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	// Insert code here to initialize your application 
	[NSThread detachNewThreadSelector:@selector(checkSMS) toTarget:self withObject:nil];
	
	// StatusItem initialization
	manualMode = NO;
	prevRSSI = 50;
	systemBar = [NSStatusBar systemStatusBar];
	abissStatus = [[systemBar statusItemWithLength:NSSquareStatusItemLength] retain];
	NSBundle *abiss = [NSBundle mainBundle];
	NSImage *icon = [[NSImage alloc] retain];
	[icon initWithContentsOfFile:[NSString stringWithFormat:@"%@%@", [abiss resourcePath], @"/icon.png"]];
	NSImage *iconalt = [[NSImage alloc] retain];
	[iconalt initWithContentsOfFile:[NSString stringWithFormat:@"%@%@", [abiss resourcePath], @"/icon-alt.png"]];
	[abissStatus setImage:icon];
	[abissStatus setAlternateImage:iconalt];
	[abissStatus setHighlightMode:YES];
	[abissStatus setMenu:statusItemMenu];
	[statusItemMenu setAutoenablesItems:NO];
	//statusItemThread = [[NSThread alloc] initWithTarget:self selector:@selector(spinIcon) object:nil];
	
	hostController = [[IOBluetoothHostController defaultController] retain];
	[hostController setDelegate:self];
	
	AudioDeviceID currID;
//	AudioDeviceID internalSpeakersID = getRequestedDeviceID("Built-in Output", kAudioTypeOutput);
	NSArray *pairedDevices = [IOBluetoothDevice pairedDevices];
	NSMutableArray *abissValues = [NSMutableArray arrayWithCapacity:[pairedDevices count]];
	NSMutableArray *abissKeys = [NSMutableArray arrayWithCapacity:[pairedDevices count]];
	abissDeviceIDs = [[NSMutableArray arrayWithCapacity:[pairedDevices count]] retain];
	abissMenuItems = [[NSMutableArray arrayWithCapacity:[pairedDevices count]] retain];
	NSRange abissRange;
	NSMenuItem *currItem;
	NSImage *checkmark = [[statusItemMenu itemAtIndex:3] onStateImage];
	for (IOBluetoothDevice *currDevice in pairedDevices) {
		abissRange = [[currDevice name] rangeOfString:@"ABISS"];
		if (abissRange.location != NSNotFound) {
			currItem = [statusItemMenu insertItemWithTitle:[currDevice name] action:@selector(pairWithDevice:) keyEquivalent:@"" atIndex:1];
			[abissMenuItems addObject:currItem];
			[currItem setOnStateImage:checkmark];
			[currItem setEnabled:NO];
			if (kIOReturnSuccess != [currDevice openConnection]) {
				[currItem setHidden:YES];
			}
			else {
				[currDevice closeConnection];
			}
			[abissKeys addObject:[currDevice name]];
			currID = getRequestedDeviceID((char *)[[currDevice name] UTF8String], kAudioTypeOutput);
			[abissValues addObject:currDevice];
			[abissDeviceIDs addObject:[NSNumber numberWithInt:(int)(currID)]];
		}
	}
	abissReceivers = [[NSDictionary dictionaryWithObjects:abissValues forKeys:abissKeys] retain];
	[NSThread detachNewThreadSelector:@selector(initialScan) 
							 toTarget:self 
						   withObject:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	setDevice(getRequestedDeviceID((char *)[[NSString stringWithFormat:@"Built-in Output"] UTF8String], kAudioTypeOutput), kAudioTypeOutput);
	for (IOBluetoothDevice *currDevice in [abissReceivers allValues]) {
		[currDevice closeConnection];
	}
}

- (void) readRSSIForDeviceComplete:(id)controller 
							device:(IOBluetoothDevice *)device 
							  info:(BluetoothHCIRSSIInfo *)info 
							 error:(IOReturn)error {
	for (int i = 0; i < [abissReceivers count]; ++i) {
		NSString *currName = [[abissReceivers allKeys] objectAtIndex:i];
//		NSLog(@"reading RSSI");
		if ([[device name] compare:currName] == NSOrderedSame) {
			[self performSelectorOnMainThread:@selector(updateRSSIValue:) 
								   withObject:[NSArray arrayWithObjects:[NSNumber numberWithInt:i],
											   [NSNumber numberWithInt:(-1*(info->RSSIValue))],
											   [device name], nil] 
								waitUntilDone:YES];
//			[[abissMenuItems objectAtIndex:i] setTitle:[NSString stringWithFormat:@"%@\t\t\t%d", [device name], -1*(info->RSSIValue)]];
			if (((prevRSSI - (int)(-1*(info->RSSIValue)) > 1)) && ([[device name] compare:prevDevice] != NSOrderedSame)) {
//				NSLog(@"Comparing %@ and previous %@", [device name], prevDevice);
				//NSArray *items = [statusItemMenu itemArray];
//				for (int j = 0; j < [items count]; ++j) {
//					if ([[items objectAtIndex:j] state] == NSOnState) {
//						[[items objectAtIndex:j] setState:NSOffState];
//						break;
//					}
//				}
//				[[abissMenuItems objectAtIndex:i] setState:NSOnState];
				[NSThread detachNewThreadSelector:@selector(setDeviceThread:) 
										 toTarget:self 
									   withObject:[NSArray arrayWithObjects:[device name], 
												   [NSNumber numberWithInt:i], 
												   nil]];
			} 
			prevRSSI = -1*(info->RSSIValue);
			prevDevice = [[device name] retain];
			break;
		}
	}
}

- (void) updateRSSIValue:(NSArray *)values {
	int i = [[values objectAtIndex:0] intValue];
	int j = [[values objectAtIndex:1] intValue];
	NSString *name = [values objectAtIndex:2];
	[[abissMenuItems objectAtIndex:i] setTitle:[NSString stringWithFormat:@"%@\t\t\t%d", name, j]];	
}

- (void) setDeviceThread:(NSArray *) info {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSString *deviceName = [info objectAtIndex:0];
	int i = [[info objectAtIndex:1] intValue];
	setDevice(getRequestedDeviceID((char *)([deviceName UTF8String]), kAudioTypeOutput), kAudioTypeOutput);
	[self performSelectorOnMainThread:@selector(turnItemOn:) 
						   withObject:[NSNumber numberWithInt:i] 
						waitUntilDone:YES];
	
	[pool drain];
	
}

- (void) turnItemOn:(NSNumber *)num {
	[self unhideMenuItem:[abissMenuItems objectAtIndex:[num intValue]]];
	NSArray *items = [statusItemMenu itemArray];
	for (int j = 0; j < [items count]; ++j) {
		if ([[items objectAtIndex:j] state] == NSOnState) {
			[[items objectAtIndex:j] setState:NSOffState];
			break;
		}
	}
	[[abissMenuItems objectAtIndex:[num intValue]] setState:NSOnState];
}

- (void) startSpinningIcon {
	if (statusItemThread != nil) {
		if (![statusItemThread isExecuting]) {
			if ([statusItemThread isFinished]) {
				[statusItemThread release];
				statusItemThread = [[[NSThread alloc] initWithTarget:self 
															selector:@selector(spinIcon) 
															  object:nil] retain];
			}
			[statusItemThread start];
		}
	}
	else {
		statusItemThread = [[NSThread alloc] initWithTarget:self 
												   selector:@selector(spinIcon) 
													 object:nil];
		[self startSpinningIcon];
	}
}

- (void) stopSpinningIcon {
	if ([statusItemThread isExecuting]) {
		NSMutableDictionary* threadDict = [statusItemThread threadDictionary];
		[threadDict setValue:[NSNumber numberWithBool:YES] 
					  forKey:@"ThreadShouldExitNow"];
	}
}

- (void) initialScan {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	int i = 0;

	for (IOBluetoothDevice *device in [abissReceivers allValues]) {
		if ([device isConnected]) {
//			NSLog(@"%@ is already connected", [device name]);
			[self performSelectorOnMainThread:@selector(unhideMenuItem:) 
								   withObject:[abissMenuItems objectAtIndex:i] 
								waitUntilDone:YES];
			[hostController readRSSIForDevice:device];
		}
		else if (kIOReturnSuccess == [device openConnection]) {
//			NSLog(@"%@ is connected", [device name]);
			[self performSelectorOnMainThread:@selector(unhideMenuItem:) 
								   withObject:[abissMenuItems objectAtIndex:i] 
								waitUntilDone:YES];
			[hostController readRSSIForDevice:device];			
		}
		else {
			[self performSelectorOnMainThread:@selector(hideMenuItem:) 
								   withObject:[abissMenuItems objectAtIndex:i] 
								waitUntilDone:YES];
		}
		i++;
	}
	[pool drain]; 
}

- (void) unhideMenuItem:(NSMenuItem *)currItem {
	if ([currItem isHidden]) {
		[currItem setHidden:NO];
	}
	
}

- (void) hideMenuItem:(NSMenuItem *)currItem {
	if (![currItem isHidden]) {
		[currItem setHidden:YES];
	} 
}

- (void) checkSMS {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	float prevX, prevY, prevZ; 
	sms_acceleration accel;
	smsStartup(nil, nil);
	int isMoving;
//	smsLoadCalibration();
	sleep(1);
	while (YES) {
		isMoving = 0;
		smsGetUncalibratedData(&accel);
		prevX = accel.x;
		
		prevY = accel.y;
		prevZ = accel.z;
		
		sleep(2);
		
		//	printf("%f %f %f\n", accel.x, accel.y, accel.z);
		smsGetUncalibratedData(&accel);
		//	printf("%f %f %f\n", accel.x, accel.y, accel.z);
		if (fabs(prevX - accel.x) > 3.0) {
//			printf("moving in X\n");
			isMoving++;			
		}
		if (fabs(prevY - accel.y) > 3.0) {
//			printf("moving in Y\n");
			isMoving++;
		}
		if (fabs(prevZ - accel.z) > 3.0) {
//			printf("moving in Z\n");
			isMoving++;
		}
		
		if (isMoving >= 2) {
			[self startSpinningIcon];
			[NSThread detachNewThreadSelector:@selector(initialScan) toTarget:self withObject:nil];
		}
		else {
			[self stopSpinningIcon];
		}

	}
		
	printf("\n\n");
	[pool drain];
	
	
}

- (void) spinIcon {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	BOOL exitNow = NO;
	int status = 1;
	NSBundle *abiss = [NSBundle mainBundle];
	
	NSImage *icon20 = [NSImage alloc];
	[icon20 initWithContentsOfFile:[NSString stringWithFormat:@"%@%@", [abiss resourcePath], @"/icon20.png"]];
	
	NSImage *icon30 = [NSImage alloc];
	[icon30 initWithContentsOfFile:[NSString stringWithFormat:@"%@%@", [abiss resourcePath], @"/icon30.png"]];
	
	NSImage *icon = [NSImage alloc];
	[icon initWithContentsOfFile:[NSString stringWithFormat:@"%@%@", [abiss resourcePath], @"/icon.png"]];
	
	NSImage *icon20alt = [NSImage alloc];
	[icon20alt initWithContentsOfFile:[NSString stringWithFormat:@"%@%@", [abiss resourcePath], @"/icon20-alt.png"]];
	
	NSImage *icon30alt = [NSImage alloc];
	[icon30alt initWithContentsOfFile:[NSString stringWithFormat:@"%@%@", [abiss resourcePath], @"/icon30-alt.png"]];
	
	NSImage *iconalt = [NSImage alloc];
	[iconalt initWithContentsOfFile:[NSString stringWithFormat:@"%@%@", [abiss resourcePath], @"/icon-alt.png"]];
	
	NSMutableDictionary* threadDict = [[NSThread currentThread] threadDictionary];
    [threadDict setValue:[NSNumber numberWithBool:exitNow] forKey:@"ThreadShouldExitNow"];
	
	while (!exitNow) {
		if (status == 1) {
			[abissStatus setImage:icon20];
			[abissStatus setAlternateImage:icon20alt];
			status++;
			usleep(80000);
		}
		
		
		else if (status == 2) {
			[abissStatus setImage:icon30];
			[abissStatus setAlternateImage:icon30alt];
			status++;
			usleep(80000);
		}
		
		else if (status > 2) {
			[abissStatus setImage:icon];
			[abissStatus setAlternateImage:iconalt];
			status = 1;
			usleep(80000);
		}
		
		exitNow = [[threadDict valueForKey:@"ThreadShouldExitNow"] boolValue];
	}
	[abissStatus setImage:icon];
	[abissStatus setAlternateImage:iconalt];

	[pool drain];	
}

- (IBAction) manualMode:(NSMenuItem *)sender {
	if ([sender state] == NSOffState) {
		[sender setState:NSOnState];
		NSArray *items = [statusItemMenu itemArray];
		[[items objectAtIndex:([items count] - 4)] setHidden:NO];
		for (NSMenuItem *item in abissMenuItems) {
			[item setEnabled:YES];
			[item setHidden:NO];
		}
		AudioDeviceID currOutput = getCurrentlySelectedDeviceID(kAudioTypeOutput);
		if (currOutput == getRequestedDeviceID((char *)[[NSString stringWithFormat:@"Built-in Output"] UTF8String], kAudioTypeOutput)) {
			[[items objectAtIndex:([items count] - 4)] setState:NSOnState];
		}
	}
	else {
		[sender setState:NSOffState];
		for (NSMenuItem *item in abissMenuItems) {
			[item setEnabled:NO];
		}
		NSArray *items = [statusItemMenu itemArray];
		[[items objectAtIndex:([items count] - 4)] setHidden:YES];
	}

}

- (IBAction) playThroughBuiltInOutput:(NSMenuItem *)sender {
	setDevice(getRequestedDeviceID((char *)[[NSString stringWithFormat:@"Built-in Output"] UTF8String], kAudioTypeOutput), kAudioTypeOutput);
	NSArray *items = [statusItemMenu itemArray];
	for (int i = 0; i < ([items count] - 3); ++i) {
		if ([[items objectAtIndex:i] state] == NSOnState) {
			[[items objectAtIndex:i] setState:NSOffState];
			break;
		}
	}
	[sender setState:NSOnState];
	[self stopSpinningIcon];
}

- (IBAction) pairWithDevice:(NSMenuItem *)sender {
	[self startSpinningIcon];
//	int index = [statusItemMenu indexOfItem:sender];
	IOBluetoothDevice *currDevice = [abissReceivers objectForKey:[sender title]];
//	AudioDeviceID currID = (AudioDeviceID)([abissDeviceIDs objectAtIndex:index]);
	if (kIOReturnSuccess == [currDevice openConnection]) {
		setDevice(getRequestedDeviceID((char *)[[currDevice name] UTF8String], kAudioTypeOutput), kAudioTypeOutput);
		[hostController readRSSIForDevice:currDevice];
		NSArray *items = [statusItemMenu itemArray];
		for (int i = 0; i < ([items count] - 3); ++i) {
			if ([[items objectAtIndex:i] state] == NSOnState) {
				[[items objectAtIndex:i] setState:NSOffState];
				break;
			}
		}
		[sender setState:NSOnState];
	}
	
	
	//NSLog(@"%@", sender);
}

@end
