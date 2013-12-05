#import <Cocoa/Cocoa.h>
#import "TaprSetupController.h"
#import "TaprRecognitionController.h"
#import "MultitouchManager.h"
@class TaprSetupController, TaprRecognitionController;

@interface AppController : NSObject <NSApplicationDelegate>

@property IBOutlet TaprSetupController *gestureSetupController;
@property IBOutlet TaprRecognitionController *gestureRecognitionController;

- (void)awakeFromNib;
- (IBAction)closeAndQuit:(id)sender;
- (void)applicationDidFinishLaunching:(NSNotification *)notification;
- (BOOL)applicationShouldHandleReopen:(NSApplication *)sender hasVisibleWindows:(BOOL)flag;

@end
