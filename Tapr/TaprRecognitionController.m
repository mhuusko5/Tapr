#import "TaprRecognitionController.h"

@interface TaprRecognitionController ()

@property BOOL awakedFromNib;

@property IBOutlet NSImageView *appIcon1, *appIcon2, *appIcon3, *appIcon4, *appIcon5, *appIcon6, *appIcon7, *appIcon8, *appIcon9;

@property IBOutlet NSWindow *appPreviewWindow;
@property IBOutlet NSImageView *appPreview;

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

		[self hideHoveredApp];

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
	NSArray *points = @[[NSValue valueWithPoint:NSMakePoint(0.5, 0.5)],
	                    [NSValue valueWithPoint:NSMakePoint(0.5, 0.12)],
	                    [NSValue valueWithPoint:NSMakePoint(0.5, 0.88)],
	                    [NSValue valueWithPoint:NSMakePoint(0.12, 0.5)],
	                    [NSValue valueWithPoint:NSMakePoint(0.88, 0.5)],
	                    [NSValue valueWithPoint:NSMakePoint(0.25, 0.25)],
	                    [NSValue valueWithPoint:NSMakePoint(0.25, 0.75)],
	                    [NSValue valueWithPoint:NSMakePoint(0.75, 0.25)],
	                    [NSValue valueWithPoint:NSMakePoint(0.75, 0.75)]];

	NSMutableDictionary *distances = [NSMutableDictionary dictionary];

	for (int i = 0; i < points.count; i++) {
		NSPoint p = [points[i] pointValue];
		float distance = sqrtf((p.x - x) * (p.x - x) + (p.y - y) * (p.y - y));
		distances[@(distance)] = @(i);
	}

	NSArray *sortedDistances = [distances.allKeys sortedArrayUsingComparator: ^NSComparisonResult (NSNumber *a, NSNumber *b) {
	    return [a compare:b];
	}];

	return [distances[sortedDistances[0]] intValue];
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

			BOOL shouldShowApp = (_lastAppSelection != newAppSelection && _appController.taprSetupController.setupModel.applicationPreviewOption);

			_lastAppSelection = newAppSelection;

			if (shouldShowApp) {
				[self hideHoveredApp];
				[self performSelector:@selector(showHoveredApp) withObject:nil afterDelay:0.25];
			}
		}
		else if (event.touches.count == 0 && _lastAppSelection > -1) {
			[self activateTappedApp];
		}
		else if (event.touches.count > 1) {
			[self stopDetectingTapWithForce:YES];

			[self ignoreActivation:@[@YES, @0.25]];
		}
	}
}

- (void)activateTappedApp {
	[_appArrayToUse[_lastAppSelection] launchWithNewThread:YES];

	[self stopDetectingTapWithForce:NO];

	[self ignoreActivation:@[@YES, @0.1]];
}

- (void)showHoveredApp {
	Application *hoveredApp = _appArrayToUse[_lastAppSelection];
    
	NSArray *hoveredRunningApps = [NSRunningApplication runningApplicationsWithBundleIdentifier:hoveredApp.bundleId];
	NSRunningApplication *runningApp;
	if (hoveredRunningApps && hoveredRunningApps.count > 0 && (runningApp = hoveredRunningApps[0])) {
		NSArray *allWindows = (__bridge_transfer NSArray *)(CGWindowListCopyWindowInfo(kCGWindowListExcludeDesktopElements, kCGNullWindowID));
		NSDictionary *appWindow;
		for (NSDictionary *windowDict in allWindows) {
			if (windowDict && [[windowDict objectForKey:(id)kCGWindowOwnerPID] integerValue] == runningApp.processIdentifier && [[windowDict objectForKey:(id)kCGWindowLayer] intValue] == 0 && [[windowDict objectForKey:(id)kCGWindowAlpha] floatValue] > 0.2 && ([[[windowDict objectForKey:(id)kCGWindowBounds] objectForKey:@"X"] intValue] + [[[windowDict objectForKey:(id)kCGWindowBounds] objectForKey:@"Y"] intValue]) != 0 && [windowDict objectForKey:(id)kCGWindowName] && [[windowDict objectForKey:(id)kCGWindowName] length] > 0) {
				appWindow = windowDict;
				break;
			}
		}

		if (appWindow) {
			CGImageRef windowImageRef = CGWindowListCreateImage(CGRectNull, kCGWindowListOptionIncludingWindow, [[appWindow objectForKey:(id)kCGWindowNumber] integerValue], kCGWindowImageBoundsIgnoreFraming);
			float aspectRatio = (float)CGImageGetWidth(windowImageRef) / (float)CGImageGetHeight(windowImageRef);

            if (CGImageGetWidth(windowImageRef) > 100 && CGImageGetHeight(windowImageRef) > 100) {
                NSRect windowRect = _recognitionWindow.frame;
                float heightIncrease = (windowRect.size.height * 1.6 - windowRect.size.height);
                windowRect.size.height += heightIncrease;
                windowRect.origin.y -= heightIncrease / 2;
                float widthIncrease = (windowRect.size.height * aspectRatio - windowRect.size.width);
                windowRect.size.width += widthIncrease;
                windowRect.origin.x -= widthIncrease / 2;

                [_appPreviewWindow setFrame:windowRect display:YES];

                float borderRadius = windowRect.size.height / 45;

                windowRect.size.height -= borderRadius;
                windowRect.size.width -= borderRadius;
                windowRect.origin = NSMakePoint(borderRadius / 2, borderRadius / 2);
                [_appPreview setFrame:windowRect];
                [_appPreview setImage:[[NSImage alloc] initWithCGImage:windowImageRef size:NSZeroSize]];

                [_appPreviewWindow.contentView layer].cornerRadius = borderRadius / 2;
                [_appPreviewWindow.contentView layer].backgroundColor = [NSColor colorWithCalibratedWhite:0.05 alpha:0.87].CGColor;
                [_appPreviewWindow setLevel:_recognitionWindow.level - 1];
                [_appPreviewWindow orderFrontRegardless];
                [_appPreviewWindow setAlphaValue:1.0];
            }

            CGImageRelease(windowImageRef);
		}
	}
}

- (void)hideHoveredApp {
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(showHoveredApp) object:nil];
	_appPreviewWindow.alphaValue = 0.0;
	_appPreview.image = nil;
	[_appPreviewWindow orderOut:self];
	[_appPreviewWindow setFrameOrigin:NSMakePoint(-10000, -10000)];
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
		return NULL;
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
	NSArray *mostActivatedArray = [_recognitionModel getMostActivatedAppArray];
	NSArray *mostOpenedArray = [_recognitionModel getMostOpenedAppArray];
	if (mostActivatedArray.count > 8) {
		_appArrayToUse = mostActivatedArray;
	}
	else {
		_appArrayToUse = mostOpenedArray;
	}

	_appArrayToUse = [[[_appArrayToUse subarrayWithRange:NSMakeRange(0, 9)] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [a.displayName compare:b.displayName];
	}] mutableCopy];

	_appIcon1.image = ((Application *)_appArrayToUse[0]).icon;
	_appIcon2.image = ((Application *)_appArrayToUse[1]).icon;
	_appIcon3.image = ((Application *)_appArrayToUse[2]).icon;
	_appIcon4.image = ((Application *)_appArrayToUse[3]).icon;
	_appIcon5.image = ((Application *)_appArrayToUse[4]).icon;
	_appIcon6.image = ((Application *)_appArrayToUse[5]).icon;
	_appIcon7.image = ((Application *)_appArrayToUse[6]).icon;
	_appIcon8.image = ((Application *)_appArrayToUse[7]).icon;
	_appIcon9.image = ((Application *)_appArrayToUse[8]).icon;

	[self setAppIconShadowsWithSelection:-2];
}

- (void)setAppIconShadowsWithSelection:(int)selection {
	if (selection != _lastAppSelection) {
		NSMutableArray *normalShadowAppIcons = [NSMutableArray arrayWithObjects:_appIcon1, _appIcon2, _appIcon3, _appIcon4, _appIcon5, _appIcon6, _appIcon7, _appIcon8, _appIcon9, nil];

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

		[self hideHoveredApp];

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
	windowRect.size.width = windowRect.size.height;
	windowRect.origin.x += (screenRect.size.width - windowRect.size.width) / 2;
	windowRect.origin.y += (screenRect.size.height - windowRect.size.height) / 2;

	[_recognitionWindow setFrame:windowRect display:NO];

	float windowSize = windowRect.size.height;
	float appSize = windowSize / 4.9;
	float horizontalInset = appSize / 5;
	float diagonalInset = windowSize / 9;
	float centerAppSize = appSize * 1.3;

	[_appIcon1 setFrame:NSMakeRect((windowSize - centerAppSize) / 2, (windowSize - centerAppSize) / 2, centerAppSize, centerAppSize)];
	[_appIcon2 setFrame:NSMakeRect((windowSize - appSize) / 2, horizontalInset, appSize, appSize)];
	[_appIcon3 setFrame:NSMakeRect((windowSize - appSize) / 2, (windowSize - appSize) - horizontalInset, appSize, appSize)];
	[_appIcon4 setFrame:NSMakeRect(horizontalInset, (windowSize - appSize) / 2, appSize, appSize)];
	[_appIcon5 setFrame:NSMakeRect((windowSize - appSize) - horizontalInset, (windowSize - appSize) / 2, appSize, appSize)];
	[_appIcon6 setFrame:NSMakeRect(diagonalInset + horizontalInset, diagonalInset + horizontalInset, appSize, appSize)];
	[_appIcon7 setFrame:NSMakeRect(diagonalInset + horizontalInset, (windowSize - appSize) - (diagonalInset + horizontalInset), appSize, appSize)];
	[_appIcon8 setFrame:NSMakeRect((windowSize - appSize) - (diagonalInset + horizontalInset), diagonalInset + horizontalInset, appSize, appSize)];
	[_appIcon9 setFrame:NSMakeRect((windowSize - appSize) - (diagonalInset + horizontalInset), (windowSize - appSize) - (diagonalInset + horizontalInset), appSize, appSize)];

	[_recognitionWindow.contentView setNeedsDisplay:YES];
}

#pragma mark -

@end
