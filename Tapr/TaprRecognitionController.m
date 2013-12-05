#import "TaprRecognitionController.h"

@interface TaprRecognitionController ()

@property BOOL awakedFromNib;

@property IBOutlet NSImageView *appIcon1, *appIcon2, *appIcon3, *appIcon4, *appIcon5, *appIcon6;

@property NSArray *appArrayToUse;

@property NSArray *beforeThreeFingerTouches;
@property NSMutableArray *recentThreeFingerTouches;

@property BOOL ignoringActivation;

@property int lastAppSelection;

@property NSTimer *noTapTimer;

@end

@implementation TaprRecognitionController

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib {
	if (!self.awakedFromNib) {
		self.awakedFromNib = YES;

		[self hideRecognitionWindowWithFade:NO];

		self.recognitionModel = [[TaprRecognitionModel alloc] init];
		[self.recognitionModel setup];

		self.beforeThreeFingerTouches = @[@0, @0, @0];
		self.recentThreeFingerTouches = [NSMutableArray array];
	}
}

- (void)applicationDidFinishLaunching {
	eventHandler = CGEventTapCreate(kCGHIDEventTap, kCGHeadInsertEventTap, kCGEventTapOptionDefault, kCGEventMaskForAllEvents, handleEvent, (__bridge void *)(self));
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
	if (!self.listeningToTap) {
		self.listeningToTap = YES;

		[self configureAppIcons];

		[self showRecognitionWindow];

		self.lastAppSelection = -1;

		self.noTapTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(noTapDetected) userInfo:nil repeats:NO];

		[NSApp activateIgnoringOtherApps:YES];
		CGAssociateMouseAndMouseCursorPosition(NO);

		[NSThread sleepForTimeInterval:0.1];
		[[MultitouchManager sharedMultitouchManager] addMultitouchListenerWithTarget:self callback:@selector(tapMultitouchEvent:) andThread:nil];
	}
}

- (void)stopDetectingTapWithForce:(BOOL)force {
	if (self.listeningToTap) {
		self.listeningToTap = NO;

		if (self.noTapTimer) {
			[self.noTapTimer invalidate];
			self.noTapTimer = nil;
		}

		[[MultitouchManager sharedMultitouchManager] removeMultitouchListenersWithTarget:self andCallback:@selector(tapMultitouchEvent:)];
		CGAssociateMouseAndMouseCursorPosition(YES);

		[self hideRecognitionWindowWithFade:!force];
	}

	[self.recognitionModel generateActivatedAppDictionary];
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
	if (self.listeningToTap && event) {
		MultitouchTouch *tap;
		if (event.touches.count == 1 && (tap = (event.touches)[0]) && tap.state == MultitouchTouchStateActive) {
			if (self.noTapTimer) {
				[self.noTapTimer invalidate];
				self.noTapTimer = nil;
			}

			int newAppSelection = [self selectionFromCoordinateX:tap.x andY:tap.y];

			[self setAppIconShadowsWithSelection:newAppSelection];

			self.lastAppSelection = newAppSelection;
		}
		else if (event.touches.count == 0 && self.lastAppSelection > -1) {
			[self activateTappedApp:self.appArrayToUse[self.lastAppSelection]];
		}
		else if (event.touches.count > 1) {
			[self stopDetectingTapWithForce:YES];

			[self ignoreActivation:@[@YES, @0.25]];
		}
	}
}

- (void)activateTappedApp:(Application *)tappedApp {
	[tappedApp launchWithNewThread:YES];

	[self stopDetectingTapWithForce:NO];

	[self ignoreActivation:@[@YES, @0.1]];
}

#pragma mark -

#pragma mark -
#pragma mark Activation Event Handling
- (void)activationMultitouchEvent:(MultitouchEvent *)event {
	if (!self.listeningToTap && !self.ignoringActivation) {
		int activeTouches = 0;
		for (MultitouchTouch *touch in event.touches) {
			if (touch.state == MultitouchTouchStateActive) {
				activeTouches++;
			}
		}

		if (activeTouches == 3) {
			[self.recentThreeFingerTouches addObject:event];
		}
		else {
			if (self.recentThreeFingerTouches.count >= 3 && self.recentThreeFingerTouches.count <= 24) {
				int totalCount = 0;
				float totalVelocity = 0.0f;
				for (MultitouchEvent *fourFingerEvent in self.recentThreeFingerTouches) {
					for (MultitouchTouch *touch in fourFingerEvent.touches) {
						totalCount++;
						totalVelocity += (fabs(touch.velX) + fabs(touch.velY));
					}
				}

				NSCountedSet *countedBeforeThreeFingerTouches = [[NSCountedSet alloc] initWithArray:self.beforeThreeFingerTouches];
				if ((totalVelocity / totalCount) <= 0.4 && [countedBeforeThreeFingerTouches countForObject:@2] < 3 && [countedBeforeThreeFingerTouches countForObject:@4] < 3) {
					[self shouldStartDetectingTap];
				}
			}

			self.beforeThreeFingerTouches = @[self.beforeThreeFingerTouches[1], self.beforeThreeFingerTouches[2], @(activeTouches)];

			[self.recentThreeFingerTouches removeAllObjects];
		}
	}
}

- (void)ignoreActivation:(NSArray *)ignoreAndSeconds {
	if ([ignoreAndSeconds[0] boolValue]) {
		self.ignoringActivation = YES;

		[self performSelector:@selector(ignoreActivation:) withObject:@[@NO] afterDelay:[ignoreAndSeconds[1] floatValue]];
	}
	else {
		self.ignoringActivation = NO;
	}
}

- (CGEventRef)handleEvent:(CGEventRef)event withType:(int)type {
	if (self.listeningToTap) {
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

	return [(__bridge TaprRecognitionController *)refcon handleEvent : eventRef withType : (int)type];
}

#pragma mark -

#pragma mark -
#pragma Activation Controls
- (void)configureAppIcons {
	if (self.recognitionModel.activatedAppDictionary.count > 5) {
		self.appArrayToUse = [self.recognitionModel getMostActivatedAppArray];
	}
	else {
		self.appArrayToUse = [self.recognitionModel getMostOpenedAppArray];
	}

	self.appIcon1.image = ((Application *)self.appArrayToUse[0]).icon;
	self.appIcon2.image = ((Application *)self.appArrayToUse[1]).icon;
	self.appIcon3.image = ((Application *)self.appArrayToUse[2]).icon;
	self.appIcon4.image = ((Application *)self.appArrayToUse[3]).icon;
	self.appIcon5.image = ((Application *)self.appArrayToUse[4]).icon;
	self.appIcon6.image = ((Application *)self.appArrayToUse[5]).icon;

	[self setAppIconShadowsWithSelection:-2];
}

- (void)setAppIconShadowsWithSelection:(int)selection {
	if (selection != self.lastAppSelection) {
		NSMutableArray *normalShadowAppIcons = [NSMutableArray arrayWithObjects:self.appIcon1, self.appIcon2, self.appIcon3, self.appIcon4, self.appIcon5, self.appIcon6, nil];

		if (selection > -1) {
			NSImageView *highlightedAppIcon = normalShadowAppIcons[selection];

			NSShadow *highlightShadow = [[NSShadow alloc] init];
			[highlightShadow setShadowBlurRadius:self.recognitionWindow.frame.size.height / 58];
			[highlightShadow setShadowOffset:NSMakeSize(0, 0)];
			[highlightShadow setShadowColor:myGreenColor];

			[highlightedAppIcon setShadow:highlightShadow];
			[highlightedAppIcon setNeedsDisplay:YES];

			[normalShadowAppIcons removeObjectAtIndex:selection];
		}

		for (NSImageView *normalShadowAppIcon in normalShadowAppIcons) {
			NSShadow *normalShadow = [[NSShadow alloc] init];
			[normalShadow setShadowBlurRadius:self.recognitionWindow.frame.size.height / 38];
			[normalShadow setShadowOffset:NSMakeSize(0, 0)];
			[normalShadow setShadowColor:[NSColor colorWithCalibratedWhite:0.0 alpha:0.94]];

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

	self.recognitionWindow.alphaValue = 1.0;
	[self.recognitionWindow orderFrontRegardless];
	[self.recognitionWindow makeKeyWindow];
}

- (void)hideRecognitionWindowWithFade:(BOOL)fade {
	if (fade) {
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.3];
		[[NSAnimationContext currentContext] setCompletionHandler: ^{
		    [self hideRecognitionWindowWithFade:NO];
		}];
		[self.recognitionWindow.animator setAlphaValue:0.0];
		[NSAnimationContext endGrouping];
	}
	else {
		self.recognitionWindow.alphaValue = 0.0;
		[self.recognitionWindow orderOut:self];
		[self.recognitionWindow setFrameOrigin:NSMakePoint(-10000, -10000)];
		[NSApp hide:self];
	}
}

- (void)windowDidResignKey:(NSNotification *)notification {
	if (self.listeningToTap) {
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

	[self.recognitionWindow setFrame:windowRect display:NO];

	NSSize appIconSize = NSMakeSize(windowRect.size.height / 2.96, windowRect.size.height / 2.96);

	[self.appIcon1 setFrame:NSMakeRect(windowRect.size.height / 6.564, windowRect.size.height / 1.842, appIconSize.width, appIconSize.height)];
	[self.appIcon2 setFrame:NSMakeRect(windowRect.size.height / 1.716, windowRect.size.height / 1.842, appIconSize.width, appIconSize.height)];
	[self.appIcon3 setFrame:NSMakeRect(windowRect.size.height / 0.988, windowRect.size.height / 1.842, appIconSize.width, appIconSize.height)];
	[self.appIcon4 setFrame:NSMakeRect(windowRect.size.height / 6.564, windowRect.size.height / 8.572, appIconSize.width, appIconSize.height)];
	[self.appIcon5 setFrame:NSMakeRect(windowRect.size.height / 1.716, windowRect.size.height / 8.572, appIconSize.width, appIconSize.height)];
	[self.appIcon6 setFrame:NSMakeRect(windowRect.size.height / 0.988, windowRect.size.height / 8.572, appIconSize.width, appIconSize.height)];

	[self.recognitionWindow.contentView setNeedsDisplay:YES];
}

#pragma mark -

@end
