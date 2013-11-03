#import "TaprRecognitionController.h"

@implementation TaprRecognitionController

@synthesize recognitionModel, appController, recognitionWindow, detectingTap;

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib {
	if (!awakedFromNib) {
		awakedFromNib = YES;
        
		[self hideRecognitionWindow];
        
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
    
	[self hideRecognitionWindow];
}

#pragma mark -

#pragma mark -
#pragma mark Recognition Utilities
- (void)shouldStartDetectingTap {
	if (!detectingTap) {
		[self showRecognitionWindow];
        
        noTapTimer = [NSTimer scheduledTimerWithTimeInterval:1.4 target:self selector:@selector(noTapInput) userInfo:nil repeats:NO];
        
        [[MultitouchManager sharedMultitouchManager] removeMultitouchListenersWithTarget:self andCallback:@selector(tapMultitouchEvent:)];
        [self performSelector:@selector(startListeningForTapEvent) withObject:nil afterDelay:0.2];
        [NSApp activateIgnoringOtherApps:YES];
        CGAssociateMouseAndMouseCursorPosition(NO);
        
        detectingTap = YES;
	}
}

- (void)stopDetectingTap:(BOOL)force {
    if (detectingTap) {
        if (noTapTimer) {
            [noTapTimer invalidate];
            noTapTimer = nil;
        }
        
        [[MultitouchManager sharedMultitouchManager] removeMultitouchListenersWithTarget:self andCallback:@selector(tapMultitouchEvent:)];
        CGAssociateMouseAndMouseCursorPosition(YES);
        
        if (force) {
            [self hideRecognitionWindow];
            
            detectingTap = NO;
        } else {
            [NSAnimationContext beginGrouping];
            [[NSAnimationContext currentContext] setDuration:0.1];
            [[NSAnimationContext currentContext] setCompletionHandler: ^{
                [self hideRecognitionWindow];
                
                detectingTap = NO;
            }];
            [recognitionWindow.animator setAlphaValue:0.0];
            [NSAnimationContext endGrouping];
        }
    }
}

- (void)noTapInput {
    [self stopDetectingTap:YES];
}

#pragma mark -

#pragma mark -
#pragma mark Tap Event Handling
- (void)startListeningForTapEvent {
    [[MultitouchManager sharedMultitouchManager] addMultitouchListenerWithTarget:self callback:@selector(tapMultitouchEvent:) andThread:nil];
}

- (void)tapMultitouchEvent:(MultitouchEvent *)event {
    if (detectingTap && event && event.touches.count == 1 && ((MultitouchTouch *)[event.touches objectAtIndex:0]).state == MultitouchTouchStateActive) {
        [self stopDetectingTap:NO];
    }
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
            
			if (totalCount / 3 <= 30 && (totalVelocity / totalCount) <= 0.5) {
				[self shouldStartDetectingTap];
			}
		}
	}
}

- (CGEventRef)handleEvent:(CGEventRef)event withType:(int)type {
	if (detectingTap) {
        if (type == kCGEventKeyUp || type == kCGEventKeyDown) {
            [self stopDetectingTap:YES];
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
#pragma mark Window Methods
- (void)showRecognitionWindow {
	[self layoutRecognitionWindow];
    
	recognitionWindow.alphaValue = 1.0;
	[recognitionWindow orderFrontRegardless];
	[recognitionWindow makeKeyWindow];
}

- (void)hideRecognitionWindow {
	recognitionWindow.alphaValue = 0.0;
	[recognitionWindow orderOut:self];
	[recognitionWindow setFrameOrigin:NSMakePoint(-10000, -10000)];
	[NSApp hide:self];
}

- (void)windowDidResignKey:(NSNotification *)notification {
	if (detectingTap) {
		[self stopDetectingTap:YES];
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
}

#pragma mark -

@end
