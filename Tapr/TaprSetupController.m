#import "TaprSetupController.h"

@implementation TaprSetupController

@synthesize appController, setupModel, setupWindow;

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib {
	if (!awakedFromNib) {
		awakedFromNib = YES;
        
		[self hideSetupWindow];
        
		setupModel = [[TaprSetupModel alloc] init];
        
		statusBarItem = [NSStatusItemPrioritizer prioritizedStatusItem];
		statusBarItem.title = @"";
		statusBarView.alphaValue = 0.0;
		statusBarItem.view = statusBarView;
	}
}

- (void)applicationDidFinishLaunching {
	[[statusBarView animator] setAlphaValue:1.0];
    
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(repositionSetupWindow:) name:NSWindowDidMoveNotification object:statusBarView.window];
    
	[self updateSetupControls];
    
	[self hideSetupWindow];
}

#pragma mark -

#pragma mark -
#pragma mark Interface Control
- (void)updateSetupControls {
	loginStartOptionField.state = setupModel.loginStartOption;
    
    [setupWindow.contentView setNeedsDisplay:YES];
}

#pragma mark -

#pragma mark -
#pragma mark Window Methods
- (void)positionSetupWindow {
	NSRect menuBarFrame = [[[statusBarItem view] window] frame];
	NSPoint pt = NSMakePoint(NSMidX(menuBarFrame), NSMidY(menuBarFrame));
    
	pt.y -= menuBarFrame.size.height / 2;
	pt.y -= setupWindow.frame.size.height;
	pt.x -= setupWindow.frame.size.width / 2;
    
	[setupWindow setFrameOrigin:pt];
}

- (IBAction)toggleSetupWindow:(id)sender {
	[self positionSetupWindow];
    
	if ([setupWindow alphaValue] <= 0) {
		[setupWindow orderFrontRegardless];
        
        [NSAnimationContext beginGrouping];
        [[NSAnimationContext currentContext] setDuration:0.16];
        [[NSAnimationContext currentContext] setCompletionHandler: ^{
            [setupWindow makeKeyWindow];
        }];
        [setupWindow.animator setAlphaValue:1.0];
        [NSAnimationContext endGrouping];
	}
	else {
		[NSAnimationContext beginGrouping];
		[[NSAnimationContext currentContext] setDuration:0.16];
		[[NSAnimationContext currentContext] setCompletionHandler: ^{
		    [self hideSetupWindow];
		}];
		[setupWindow.animator setAlphaValue:0.0];
		[NSAnimationContext endGrouping];
	}
    
	[self updateSetupControls];
}

- (void)hideSetupWindow {
	setupWindow.alphaValue = 0.0;
	[setupWindow orderOut:self];
	[setupWindow setFrameOrigin:NSMakePoint(-10000, -10000)];
}

- (void)windowDidResignKey:(NSNotification *)notification {
	if (setupWindow.alphaValue > 0) {
		[self toggleSetupWindow:nil];
	}
}

- (void)repositionSetupWindow:(NSNotification *)notification {
	if (setupWindow.alphaValue > 0) {
		[self positionSetupWindow];
	}
}

#pragma mark -

#pragma mark -
#pragma mark Tapr Options
- (IBAction)loginStartOptionChanged:(id)sender {
	[setupModel saveLoginStartOption:loginStartOptionField.state];
    
	loginStartOptionField.state = [setupModel fetchLoginStartOption];
    
	[self updateSetupControls];
}

#pragma mark -

@end
