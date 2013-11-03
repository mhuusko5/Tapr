#import "TaprSetupBackgroundView.h"

@implementation TaprSetupBackgroundView

- (void)drawRect:(NSRect)dirtyRect {
	if (!backgroundColor) {
		backgroundColor = [NSColor colorWithPatternImage:self.image];
	}
    
	[backgroundColor set];
	NSRectFill(dirtyRect);
}

- (void)mouseDown:(NSEvent *)theEvent {
	if ([self.window isKindOfClass:[TaprSetupWindow class]]) {
		[((AppController *)[NSApp delegate]).gestureSetupController updateSetupControls];
	}
}

@end
