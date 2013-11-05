#import "TaprRecognitionController.h"

@implementation TaprRecognitionController

@synthesize recognitionModel, appController, recognitionWindow, detectingTap;

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib {
	if (!awakedFromNib) {
		awakedFromNib = YES;
        
		[self hideRecognitionWindowWithFade:NO];
        
		recognitionModel = [[TaprRecognitionModel alloc] init];
        
		recentThreeFingerTouches = [NSMutableArray array];
	}
}

- (void)applicationDidFinishLaunching {
	eventHandler = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, kCGEventMaskForAllEvents, handleEvent, self);
	CFRunLoopSourceRef runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventHandler, 0);
	CFRunLoopAddSource(CFRunLoopGetMain(), runLoopSource, kCFRunLoopCommonModes);
	CGEventTapEnable(eventHandler, YES);
    
	[[MultitouchManager sharedMultitouchManager] addMultitouchListenerWithTarget:self callback:@selector(activationMultitouchEvent:) andThread:nil];
    
	[self layoutRecognitionWindow];
    
	[self hideRecognitionWindowWithFade:NO];
}

#pragma mark -

#pragma mark -
#pragma mark Recognition Utilities
- (void)shouldStartDetectingTap {
	if (!detectingTap) {
		[self configureAppIcons];
        
		[self showRecognitionWindow];
        
        lastAppSelection = -1;
        
		noTapTimer = [NSTimer scheduledTimerWithTimeInterval:1.4 target:self selector:@selector(noTapDetected) userInfo:nil repeats:NO];
        
		[NSApp activateIgnoringOtherApps:YES];
		CGAssociateMouseAndMouseCursorPosition(NO);
        
		[NSThread sleepForTimeInterval:0.2];
		[[MultitouchManager sharedMultitouchManager] addMultitouchListenerWithTarget:self callback:@selector(tapMultitouchEvent:) andThread:nil];
        
		detectingTap = YES;
	}
}

- (void)stopDetectingTapWithForce:(BOOL)force {
	if (detectingTap) {
        if (noTapTimer) {
			[noTapTimer invalidate];
			noTapTimer = nil;
		}
        
		[[MultitouchManager sharedMultitouchManager] removeMultitouchListenersWithTarget:self andCallback:@selector(tapMultitouchEvent:)];
		CGAssociateMouseAndMouseCursorPosition(YES);
        
        detectingTap = NO;
        
        [self hideRecognitionWindowWithFade:!force];
	}
    
    [recognitionModel generateActivatedAppDictionary];
}

- (void)noTapDetected {
	[self stopDetectingTapWithForce:YES];
}

#pragma mark -

#pragma mark -
#pragma mark Tap Event Handling
- (int)selectionFromCoordinateX:(float)x andY:(float)y {
    if (y > 0.5) {
        if (x < (1.0 / 3.0)) {
            return 0;
        }
        else if (x < (2.0 / 3.0)) {
            return 1;
        }
        else {
            return 2;
        }
    }
    else {
        if (x < (1.0 / 3.0)) {
            return 3;
        }
        else if (x < (2.0 / 3.0)) {
            return 4;
        }
        else {
            return 5;
        }
    }
}

- (void)tapMultitouchEvent:(MultitouchEvent *)event {
	if (detectingTap && event) {
        MultitouchTouch *tap;
        if (event.touches.count == 1 && (tap = [event.touches objectAtIndex:0]) && tap.state == MultitouchTouchStateActive) {
            if (noTapTimer) {
                [noTapTimer invalidate];
                noTapTimer = nil;
            }
        
            int newAppSelection = [self selectionFromCoordinateX:tap.x andY:tap.y];
        
            [self setAppIconShadowsWithSelection:newAppSelection];
        
            lastAppSelection = newAppSelection;
        } else if (event.touches.count == 0 && lastAppSelection > -1) {
            [self activateTappedApp:[appArrayToUse objectAtIndex:lastAppSelection]];
        }
	}
}

- (void)activateTappedApp:(Application *)tappedApp {
    [tappedApp launchWithNewThread:YES];
    
    [self stopDetectingTapWithForce:NO];
}

#pragma mark -

#pragma mark -
#pragma mark Activation Event Handling
- (void)activationMultitouchEvent:(MultitouchEvent *)event {
	if (!detectingTap) {
		if (event && event.touches.count == 3 && ((MultitouchTouch *)[event.touches objectAtIndex:0]).state == MultitouchTouchStateActive && ((MultitouchTouch *)[event.touches objectAtIndex:1]).state == MultitouchTouchStateActive && ((MultitouchTouch *)[event.touches objectAtIndex:2]).state == MultitouchTouchStateActive) {
			[recentThreeFingerTouches addObject:event];
		}
		else if (recentThreeFingerTouches.count > 0) {
			int totalCount = 0;
			float totalVelocity = 0.0f;
			for (MultitouchEvent *fourFingerEvent in recentThreeFingerTouches) {
				for (MultitouchTouch *touch in fourFingerEvent.touches) {
					totalCount++;
					totalVelocity += (fabs(touch.velX) + fabs(touch.velY));
				}
			}
            
			[recentThreeFingerTouches removeAllObjects];
            
			if (totalCount / 3 <= 20 && (totalVelocity / totalCount) <= 0.5) {
				[self shouldStartDetectingTap];
			}
		}
	}
}

- (CGEventRef)handleEvent:(CGEventRef)event withType:(int)type {
	if (detectingTap) {
		if (type == kCGEventKeyUp || type == kCGEventKeyDown) {
			[self stopDetectingTapWithForce:YES];
			return event;
		}
		else {
			return NULL;
		}
	}
    
	return event;
}

CFMachPortRef eventHandler;
CGEventRef handleEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef eventRef, void *refcon) {
	if (type == kCGEventTapDisabledByTimeout || type == kCGEventTapDisabledByUserInput) {
		CGEventTapEnable(eventHandler, true);
		return eventRef;
	}
    
	return [(TaprRecognitionController *)refcon handleEvent : eventRef withType : (int)type];
}

#pragma mark -

#pragma mark -
#pragma Activation Controls
- (void)configureAppIcons {
	if (recognitionModel.activatedAppDictionary.count > 5) {
		appArrayToUse = [recognitionModel getMostActivatedAppArray];
	}
	else {
		appArrayToUse = [recognitionModel getMostOpenedAppArray];
	}
    
	appIcon1.image = ((Application *)[appArrayToUse objectAtIndex:0]).icon;
	appIcon2.image = ((Application *)[appArrayToUse objectAtIndex:1]).icon;
	appIcon3.image = ((Application *)[appArrayToUse objectAtIndex:2]).icon;
	appIcon4.image = ((Application *)[appArrayToUse objectAtIndex:3]).icon;
	appIcon5.image = ((Application *)[appArrayToUse objectAtIndex:4]).icon;
	appIcon6.image = ((Application *)[appArrayToUse objectAtIndex:5]).icon;
    
	[self setAppIconShadowsWithSelection:-2];
}

- (void)setAppIconShadowsWithSelection:(int)selection {
    if (selection != lastAppSelection) {
        NSMutableArray *normalShadowAppIcons = [NSMutableArray arrayWithObjects:appIcon1, appIcon2, appIcon3, appIcon4, appIcon5, appIcon6, nil];
        
        if (selection > -1) {
            NSImageView *highlightedAppIcon = [normalShadowAppIcons objectAtIndex:selection];
            
            NSShadow *highlightShadow = [[NSShadow alloc] init];
            [highlightShadow setShadowBlurRadius:recognitionWindow.frame.size.height / 36];
            [highlightShadow setShadowOffset:NSMakeSize(0, 0)];
            [highlightShadow setShadowColor:myGreenColor];
            
            [highlightedAppIcon setShadow:highlightShadow];
            [highlightedAppIcon setNeedsDisplay:YES];
            
            [normalShadowAppIcons removeObjectAtIndex:selection];
        }
        
        for (NSImageView *normalShadowAppIcon in normalShadowAppIcons) {
            NSShadow *normalShadow = [[NSShadow alloc] init];
            [normalShadow setShadowBlurRadius:recognitionWindow.frame.size.height / 40];
            [normalShadow setShadowOffset:NSMakeSize(0, 0)];
            [normalShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.9]];
            
            [normalShadowAppIcon setShadow:normalShadow];
            [normalShadowAppIcon setNeedsDisplay:YES];
        }
    }
}

#pragma mark -

#pragma mark -
#pragma mark Window Methods
- (void)showRecognitionWindow {
	[self layoutRecognitionWindow];
    
	recognitionWindow.alphaValue = 1.0;
	[recognitionWindow orderFrontRegardless];
	[recognitionWindow makeKeyWindow];
}

- (void)hideRecognitionWindowWithFade:(BOOL)fade {
    if (fade) {
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.3];
        [[NSAnimationContext currentContext] setCompletionHandler: ^{
            [self hideRecognitionWindowWithFade:NO];
        }];
        [recognitionWindow.animator setAlphaValue:0.0];
        [NSAnimationContext endGrouping];
    } else {
        recognitionWindow.alphaValue = 0.0;
        [recognitionWindow orderOut:self];
        [recognitionWindow setFrameOrigin:NSMakePoint(-10000, -10000)];
        [NSApp hide:self];
    }
}

- (void)windowDidResignKey:(NSNotification *)notification {
	if (detectingTap) {
		[self stopDetectingTapWithForce:YES];
	}
}

- (void)layoutRecognitionWindow {
	NSPoint mouseLoc = [NSEvent mouseLocation];
	NSEnumerator *screenEnum = [[NSScreen screens] objectEnumerator];
	NSScreen *screen;
	while ((screen = [screenEnum nextObject]) && !NSMouseInRect(mouseLoc, [screen frame], NO)) {
	}
	NSRect screenRect = [screen frame];
    
	NSRect windowRect = NSMakeRect(screenRect.origin.x, screenRect.origin.y, screenRect.size.width, screenRect.size.height);
    
	windowRect.size.height /= 2.0;
	windowRect.size.width = windowRect.size.height * 3 / 2;
	windowRect.origin.x += (screenRect.size.width - windowRect.size.width) / 2;
	windowRect.origin.y += (screenRect.size.height - windowRect.size.height) / 2;
    
	[recognitionWindow setFrame:windowRect display:NO];
    
	NSSize appIconSize = NSMakeSize(windowRect.size.height / 2.94, windowRect.size.height / 2.94);
    
	[appIcon1 setFrame:NSMakeRect(windowRect.size.height / 6.74, windowRect.size.height / 1.856, appIconSize.width, appIconSize.height)];
	[appIcon2 setFrame:NSMakeRect(windowRect.size.height / 1.722, windowRect.size.height / 1.856, appIconSize.width, appIconSize.height)];
	[appIcon3 setFrame:NSMakeRect(windowRect.size.height / 0.991, windowRect.size.height / 1.856, appIconSize.width, appIconSize.height)];
	[appIcon4 setFrame:NSMakeRect(windowRect.size.height / 6.74, windowRect.size.height / 8.6, appIconSize.width, appIconSize.height)];
	[appIcon5 setFrame:NSMakeRect(windowRect.size.height / 1.722, windowRect.size.height / 8.6, appIconSize.width, appIconSize.height)];
	[appIcon6 setFrame:NSMakeRect(windowRect.size.height / 0.991, windowRect.size.height / 8.6, appIconSize.width, appIconSize.height)];
    
	[recognitionWindow.contentView setNeedsDisplay:YES];
}

#pragma mark -

@end
