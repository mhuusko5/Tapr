#import "TaprSetupController.h"

@interface TaprSetupController ()

@property BOOL awakedFromNib;

@property NSStatusItem *statusBarItem;
@property IBOutlet NSView *statusBarView;

@property IBOutlet TaprSetupBackgroundView *setupWindowBackground;

@property IBOutlet NSButton *loginStartOptionField, *appCyclingOptionField, *applicationPreviewOptionField;

@end

@implementation TaprSetupController

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib {
	if (!_awakedFromNib) {
		_awakedFromNib = YES;

		[self hideSetupWindow];

		_setupModel = [[TaprSetupModel alloc] init];
		[_setupModel setup];

		_statusBarItem = [NSStatusItemPrioritizer prioritizedStatusItem];
		_statusBarItem.title = @"";
		_statusBarView.alphaValue = 0.0;
        [[_statusBarView viewWithTag:3] image].M5_darkable = YES;
		_statusBarItem.view = _statusBarView;
	}
}

- (void)applicationDidFinishLaunching {
	[[_statusBarView animator] setAlphaValue:1.0];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositionSetupWindow:) name:NSWindowDidMoveNotification object:_statusBarView.window];

	[self updateSetupControls];

	[self hideSetupWindow];
}

#pragma mark -

#pragma mark -
#pragma mark Interface Control
- (void)updateSetupControls {
	_loginStartOptionField.state = _setupModel.loginStartOption;
    _appCyclingOptionField.state = _setupModel.appCyclingOption;
	_applicationPreviewOptionField.state = _setupModel.applicationPreviewOption;

	[_setupWindow.contentView setNeedsDisplay:YES];
}

#pragma mark -

#pragma mark -
#pragma mark Window Methods
- (void)positionSetupWindow {
	NSRect menuBarFrame = [[[_statusBarItem view] window] frame];
	NSPoint pt = NSMakePoint(NSMidX(menuBarFrame), NSMidY(menuBarFrame));

	pt.y -= menuBarFrame.size.height / 2;
	pt.y -= _setupWindow.frame.size.height;
	pt.x -= _setupWindow.frame.size.width / 2;

	[_setupWindow setFrameOrigin:pt];
}

- (IBAction)toggleSetupWindow:(id)sender {
	[self positionSetupWindow];

	if ([_setupWindow alphaValue] <= 0) {
		[_setupWindow orderFrontRegardless];

		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.16];
		[[NSAnimationContext currentContext] setCompletionHandler: ^{
		    [_setupWindow makeKeyWindow];
		}];
		[_setupWindow.animator setAlphaValue:1.0];
		[NSAnimationContext endGrouping];
	}
	else {
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.16];
		[[NSAnimationContext currentContext] setCompletionHandler: ^{
		    [self hideSetupWindow];
		}];
		[_setupWindow.animator setAlphaValue:0.0];
		[NSAnimationContext endGrouping];
	}

	[self updateSetupControls];
}

- (void)hideSetupWindow {
	_setupWindow.alphaValue = 0.0;
	[_setupWindow orderOut:self];
	[_setupWindow setFrameOrigin:NSMakePoint(-10000, -10000)];
}

- (void)windowDidResignKey:(NSNotification *)notification {
	if (_setupWindow.alphaValue > 0) {
		[self toggleSetupWindow:nil];
	}
}

- (void)repositionSetupWindow:(NSNotification *)notification {
	if (_setupWindow.alphaValue > 0) {
		[self positionSetupWindow];
	}
}

#pragma mark -

#pragma mark -
#pragma mark Tapr Options
- (IBAction)loginStartOptionChanged:(id)sender {
	[_setupModel saveLoginStartOption:_loginStartOptionField.state];

	_loginStartOptionField.state = [_setupModel fetchLoginStartOption];

	[self updateSetupControls];
}

- (IBAction)appCyclingOptionChanged:(id)sender {
    [_setupModel saveAppCyclingOption:_appCyclingOptionField.state];
    
    [self updateSetupControls];
}

- (IBAction)applicationPreviewOptionChanged:(id)sender {
	[_setupModel saveApplicationPreviewOption:_applicationPreviewOptionField.state];

	[self updateSetupControls];
}

- (IBAction)cleanAppSwitchHistory:(id)sender {
    [self.appController.taprRecognitionController.recognitionModel cleanActiveAppSwitchDictionary];
}

#pragma mark -

@end
