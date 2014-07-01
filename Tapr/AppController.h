#import "TaprSetupController.h"
#import "TaprRecognitionController.h"
#import "MultitouchManager.h"
#import "PFMoveApplication.h"
@class TaprSetupController, TaprRecognitionController;

@interface AppController : NSObject <NSApplicationDelegate>

@property IBOutlet TaprSetupController *taprSetupController;
@property IBOutlet TaprRecognitionController *taprRecognitionController;

- (void)awakeFromNib;
- (IBAction)closeAndQuit:(id)sender;
- (void)applicationWillFinishLaunching:(NSNotification *)notification;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag;

@end
