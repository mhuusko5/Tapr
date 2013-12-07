#import "TaprSetupBackgroundView.h"

@interface TaprSetupBackgroundView ()

@property NSColor *backgroundColor;

@end

@implementation TaprSetupBackgroundView

- (void)drawRect:(NSRect)dirtyRect {
	if (!_backgroundColor) {
		_backgroundColor = [NSColor colorWithPatternImage:self.image];
	}

	[_backgroundColor set];
	NSRectFill(dirtyRect);
}

- (void)mouseDown:(NSEvent *)theEvent {
	if ([self.window isKindOfClass:[TaprSetupWindow class]]) {
		[((AppController *)[NSApp delegate]).gestureSetupController updateSetupControls];
	}
}

@end
