#import "AppController.h"
#import "TaprSetupWindow.h"

@interface TaprSetupBackgroundView : NSImageView {
	NSColor *backgroundColor;
}
- (void)drawRect:(NSRect)dirtyRect;
- (void)mouseDown:(NSEvent *)theEvent;

@end
