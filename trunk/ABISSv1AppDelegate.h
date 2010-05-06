//
//  ABISSv1AppDelegate.h
//  ABISSv1
//
//  Created by Andrew Burks on 9/1/09.
//	Copyright (c) 2010 Andrew Burks, Ben Wallingford
//
//	Permission is hereby granted, free of charge, to any person obtaining a copy
//	of this software and associated documentation files (the "Software"), to deal
//	in the Software without restriction, including without limitation the rights
//	to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//	copies of the Software, and to permit persons to whom the Software is
//	furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//	OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//	THE SOFTWARE.

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
