#import "TaprSetupController.h"

@interface TaprSetupController ()

@property BOOL awakedFromNib;

@property NSStatusItem *statusBarItem;
@property IBOutlet NSView *statusBarView;

@property IBOutlet TaprSetupBackgroundView *setupWindowBackground;

@property IBOutlet NSButton *loginStartOptionField;

@end

@implementation TaprSetupController

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib {
	if (!self.awakedFromNib) {
		self.awakedFromNib = YES;

		[self hideSetupWindow];

		self.setupModel = [[TaprSetupModel alloc] init];
		[self.setupModel setup];

		self.statusBarItem = [NSStatusItemPrioritizer prioritizedStatusItem];
		self.statusBarItem.title = @"";
		self.statusBarView.alphaValue = 0.0;
		self.statusBarItem.view = self.statusBarView;
	}
}

- (void)applicationDidFinishLaunching {
	[[self.statusBarView animator] setAlphaValue:1.0];

	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositionSetupWindow:) name:NSWindowDidMoveNotification object:self.statusBarView.window];

	[self updateSetupControls];

	[self hideSetupWindow];
}

#pragma mark -

#pragma mark -
#pragma mark Interface Control
- (void)updateSetupControls {
	self.loginStartOptionField.state = self.setupModel.loginStartOption;

	[self.setupWindow.contentView setNeedsDisplay:YES];
}

#pragma mark -

#pragma mark -
#pragma mark Window Methods
- (void)positionSetupWindow {
	NSRect menuBarFrame = [[[self.statusBarItem view] window] frame];
	NSPoint pt = NSMakePoint(NSMidX(menuBarFrame), NSMidY(menuBarFrame));

	pt.y -= menuBarFrame.size.height / 2;
	pt.y -= self.setupWindow.frame.size.height;
	pt.x -= self.setupWindow.frame.size.width / 2;

	[self.setupWindow setFrameOrigin:pt];
}

- (IBAction)toggleSetupWindow:(id)sender {
	[self positionSetupWindow];

	if ([self.setupWindow alphaValue] <= 0) {
		[self.setupWindow orderFrontRegardless];

		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.16];
		[[NSAnimationContext currentContext] setCompletionHandler: ^{
		    [self.setupWindow makeKeyWindow];
		}];
		[self.setupWindow.animator setAlphaValue:1.0];
		[NSAnimationContext endGrouping];
	}
	else {
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.16];
		[[NSAnimationContext currentContext] setCompletionHandler: ^{
		    [self hideSetupWindow];
		}];
		[self.setupWindow.animator setAlphaValue:0.0];
		[NSAnimationContext endGrouping];
	}

	[self updateSetupControls];
}

- (void)hideSetupWindow {
	self.setupWindow.alphaValue = 0.0;
	[self.setupWindow orderOut:self];
	[self.setupWindow setFrameOrigin:NSMakePoint(-10000, -10000)];
}

- (void)windowDidResignKey:(NSNotification *)notification {
	if (self.setupWindow.alphaValue > 0) {
		[self toggleSetupWindow:nil];
	}
}

- (void)repositionSetupWindow:(NSNotification *)notification {
	if (self.setupWindow.alphaValue > 0) {
		[self positionSetupWindow];
	}
}

#pragma mark -

#pragma mark -
#pragma mark Tapr Options
- (IBAction)loginStartOptionChanged:(id)sender {
	[self.setupModel saveLoginStartOption:self.loginStartOptionField.state];

	self.loginStartOptionField.state = [self.setupModel fetchLoginStartOption];

	[self updateSetupControls];
}

#pragma mark -

@end
