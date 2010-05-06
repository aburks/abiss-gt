//
//  ABISSv1AppDelegate.h
//  ABISSv1
//
//  Created by Andrew Burks on 9/1/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <CoreFoundation/CoreFoundation.h>

// include for SMSLib
#import "smslib.h"
#include <unistd.h>
#include <sysexits.h>

// include for Bluetooth
#import <IOBluetooth/IOBluetooth.h>
#import <IOBluetooth/Bluetooth.h>

// include AudioSwitcher
#include "audio_switch.h"

// conditions used for locking the spin icon thread
enum {
	kSpin = 0,
	kStopSpin = 1
};

@interface ABISSv1AppDelegate : NSObject <NSApplicationDelegate> {
	NSWindow *window;
	int prevRSSI;
	NSString *prevDevice; 
	BOOL manualMode;
	NSMutableDictionary *abissReceivers;
	NSMutableArray *abissDeviceIDs;
	NSStatusBar *systemBar;
	NSStatusItem *abissStatus;
	IBOutlet NSMenu *statusItemMenu;
	NSThread *statusItemThread;
	NSMutableArray *abissMenuItems;
	IOBluetoothHostController *hostController;
}

@property (assign) IBOutlet NSWindow *window;

- (void) initialScan;
- (void) checkSMS;
- (void) startSpinningIcon;
- (void) spinIcon;
- (void) stopSpinningIcon;
- (IBAction) pairWithDevice:(NSMenuItem *)sender;
- (IBAction) manualMode:(NSMenuItem *)sender;
- (IBAction) playThroughBuiltInOutput:(NSMenuItem *)sender;
- (void) setDeviceThread:(NSArray *) info;
- (void) turnItemOn:(NSNumber *)num;
- (void) updateRSSIValue:(NSArray *)values;
- (void) unhideMenuItem:(NSMenuItem *)currItem;
- (void) hideMenuItem:(NSMenuItem *)currItem;


@end
