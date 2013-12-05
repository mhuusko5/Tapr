#import "AppController.h"
#import "TaprSetupWindow.h"

@interface TaprSetupBackgroundView : NSImageView

- (void)drawRect:(NSRect)dirtyRect;
- (void)mouseDown:(NSEvent *)theEvent;

@end
