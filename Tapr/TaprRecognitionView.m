#import "TaprRecognitionView.h"

@implementation TaprRecognitionView

- (void)drawRect:(NSRect)dirtyRect {
	[[NSColor colorWithCalibratedWhite:0.05 alpha:0.87] setFill];

	NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:dirtyRect xRadius:NSWidth(dirtyRect) / 2 yRadius:NSHeight(dirtyRect) / 2];
	[path fill];
}

- (void)keyDown:(NSEvent *)theEvent {
	[((AppController *)[NSApp delegate]).taprRecognitionController stopDetectingTapWithForce : YES];
}

- (BOOL)acceptsFirstResponder {
	return YES;
}

@end
