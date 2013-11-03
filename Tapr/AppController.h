#import <Cocoa/Cocoa.h>
#import "TaprSetupController.h"
#import "TaprRecognitionController.h"
#import "MultitouchManager.h"

@class TaprSetupController, TaprRecognitionController;

@interface AppController : NSObject <NSApplicationDelegate> {
	BOOL awakedFromNib;
    
	IBOutlet TaprSetupController *gestureSetupController;
	IBOutlet TaprRecognitionController *gestureRecognitionController;
}
@property (retain) TaprSetupController *gestureSetupController;
@property (retain) TaprRecognitionController *gestureRecognitionController;

- (void)awakeFromNib;
- (IBAction)closeAndQuit:(id)sender;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag;

@end
