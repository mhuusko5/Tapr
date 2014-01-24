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
	if (!_awakedFromNib) {
		_awakedFromNib = YES;

		[self hideRecognitionWindowWithFade:NO];

		_recognitionModel = [[TaprRecognitionModel alloc] init];
		[_recognitionModel setup];

		_beforeThreeFingerTouches = @[@0, @0, @0];
		_recentThreeFingerTouches = [NSMutableArray array];
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
	if (!_listeningToTap) {
		_listeningToTap = YES;

		[self configureAppIcons];

		[self showRecognitionWindow];

		_lastAppSelection = -1;

		_noTapTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(noTapDetected) userInfo:nil repeats:NO];

		[NSApp activateIgnoringOtherApps:YES];
		CGAssociateMouseAndMouseCursorPosition(NO);

		[NSThread sleepForTimeInterval:0.1];
		[[MultitouchManager sharedMultitouchManager] addMultitouchListenerWithTarget:self callback:@selector(tapMultitouchEvent:) andThread:nil];
	}
}

- (void)stopDetectingTapWithForce:(BOOL)force {
	if (_listeningToTap) {
		_listeningToTap = NO;

		if (_noTapTimer) {
			[_noTapTimer invalidate];
			_noTapTimer = nil;
		}

		[[MultitouchManager sharedMultitouchManager] removeMultitouchListenersWithTarget:self andCallback:@selector(tapMultitouchEvent:)];
		CGAssociateMouseAndMouseCursorPosition(YES);

		[self hideRecognitionWindowWithFade:!force];
	}

	[_recognitionModel generateActivatedAppDictionary];
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
	if (_listeningToTap && event) {
		MultitouchTouch *tap;
		if (event.touches.count == 1 && (tap = (event.touches)[0]) && tap.state == MTTouchStateTouching) {
			if (_noTapTimer) {
				[_noTapTimer invalidate];
				_noTapTimer = nil;
			}

			int newAppSelection = [self selectionFromCoordinateX:tap.x andY:tap.y];

			[self setAppIconShadowsWithSelection:newAppSelection];

			_lastAppSelection = newAppSelection;
		}
		else if (event.touches.count == 0 && _lastAppSelection > -1) {
			[self activateTappedApp:_appArrayToUse[_lastAppSelection]];
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
	if (!_listeningToTap && !_ignoringActivation) {
		int activeTouches = 0;
		for (MultitouchTouch *touch in event.touches) {
			if (touch.state == MTTouchStateTouching) {
				activeTouches++;
			}
		}

		if (activeTouches == 3) {
			[_recentThreeFingerTouches addObject:event];
		}
		else {
			if (_recentThreeFingerTouches.count >= 3 && _recentThreeFingerTouches.count <= 24) {
				int totalCount = 0;
				float totalVelocity = 0.0f;
				for (MultitouchEvent *fourFingerEvent in _recentThreeFingerTouches) {
					for (MultitouchTouch *touch in fourFingerEvent.touches) {
						totalCount++;
						totalVelocity += (fabs(touch.velX) + fabs(touch.velY));
					}
				}

				NSCountedSet *countedBeforeThreeFingerTouches = [[NSCountedSet alloc] initWithArray:_beforeThreeFingerTouches];
				if ((totalVelocity / totalCount) <= 0.4 && [countedBeforeThreeFingerTouches countForObject:@2] < 3 && [countedBeforeThreeFingerTouches countForObject:@4] < 3) {
					[self shouldStartDetectingTap];
				}
			}

			_beforeThreeFingerTouches = @[_beforeThreeFingerTouches[1], _beforeThreeFingerTouches[2], @(activeTouches)];

			[_recentThreeFingerTouches removeAllObjects];
		}
	}
}

- (void)ignoreActivation:(NSArray *)ignoreAndSeconds {
	if ([ignoreAndSeconds[0] boolValue]) {
		_ignoringActivation = YES;

		[self performSelector:@selector(ignoreActivation:) withObject:@[@NO] afterDelay:[ignoreAndSeconds[1] floatValue]];
	}
	else {
		_ignoringActivation = NO;
	}
}

- (CGEventRef)handleEvent:(CGEventRef)event withType:(int)type {
	if (_listeningToTap) {
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
	if (_recognitionModel.activatedAppDictionary.count > 5) {
		_appArrayToUse = [_recognitionModel getMostActivatedAppArray];
	}
	else {
		_appArrayToUse = [_recognitionModel getMostOpenedAppArray];
	}

	_appIcon1.image = ((Application *)_appArrayToUse[0]).icon;
	_appIcon2.image = ((Application *)_appArrayToUse[1]).icon;
	_appIcon3.image = ((Application *)_appArrayToUse[2]).icon;
	_appIcon4.image = ((Application *)_appArrayToUse[3]).icon;
	_appIcon5.image = ((Application *)_appArrayToUse[4]).icon;
	_appIcon6.image = ((Application *)_appArrayToUse[5]).icon;

	[self setAppIconShadowsWithSelection:-2];
}

- (void)setAppIconShadowsWithSelection:(int)selection {
	if (selection != _lastAppSelection) {
		NSMutableArray *normalShadowAppIcons = [NSMutableArray arrayWithObjects:_appIcon1, _appIcon2, _appIcon3, _appIcon4, _appIcon5, _appIcon6, nil];

		if (selection > -1) {
			NSImageView *highlightedAppIcon = normalShadowAppIcons[selection];

			NSShadow *highlightShadow = [[NSShadow alloc] init];
			[highlightShadow setShadowBlurRadius:_recognitionWindow.frame.size.height / 58];
			[highlightShadow setShadowOffset:NSMakeSize(0, 0)];
			[highlightShadow setShadowColor:myGreenColor];

			[highlightedAppIcon setShadow:highlightShadow];
			[highlightedAppIcon setNeedsDisplay:YES];

			[normalShadowAppIcons removeObjectAtIndex:selection];
		}

		for (NSImageView *normalShadowAppIcon in normalShadowAppIcons) {
			NSShadow *normalShadow = [[NSShadow alloc] init];
			[normalShadow setShadowBlurRadius:_recognitionWindow.frame.size.height / 38];
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

	_recognitionWindow.alphaValue = 1.0;
	[_recognitionWindow orderFrontRegardless];
	[_recognitionWindow makeKeyWindow];
}

- (void)hideRecognitionWindowWithFade:(BOOL)fade {
	if (fade) {
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.3];
		[[NSAnimationContext currentContext] setCompletionHandler: ^{
		    [self hideRecognitionWindowWithFade:NO];
		}];
		[_recognitionWindow.animator setAlphaValue:0.0];
		[NSAnimationContext endGrouping];
	}
	else {
		_recognitionWindow.alphaValue = 0.0;
		[_recognitionWindow orderOut:self];
		[_recognitionWindow setFrameOrigin:NSMakePoint(-10000, -10000)];
		[NSApp hide:self];
	}
}

- (void)windowDidResignKey:(NSNotification *)notification {
	if (_listeningToTap) {
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

	[_recognitionWindow setFrame:windowRect display:NO];

	NSSize appIconSize = NSMakeSize(windowRect.size.height / 2.96, windowRect.size.height / 2.96);

	[_appIcon1 setFrame:NSMakeRect(windowRect.size.height / 6.564, windowRect.size.height / 1.842, appIconSize.width, appIconSize.height)];
	[_appIcon2 setFrame:NSMakeRect(windowRect.size.height / 1.716, windowRect.size.height / 1.842, appIconSize.width, appIconSize.height)];
	[_appIcon3 setFrame:NSMakeRect(windowRect.size.height / 0.988, windowRect.size.height / 1.842, appIconSize.width, appIconSize.height)];
	[_appIcon4 setFrame:NSMakeRect(windowRect.size.height / 6.564, windowRect.size.height / 8.572, appIconSize.width, appIconSize.height)];
	[_appIcon5 setFrame:NSMakeRect(windowRect.size.height / 1.716, windowRect.size.height / 8.572, appIconSize.width, appIconSize.height)];
	[_appIcon6 setFrame:NSMakeRect(windowRect.size.height / 0.988, windowRect.size.height / 8.572, appIconSize.width, appIconSize.height)];

	[_recognitionWindow.contentView setNeedsDisplay:YES];
}

#pragma mark -

@end
