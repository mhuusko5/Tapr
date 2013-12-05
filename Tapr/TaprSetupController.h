#import "TaprSetupModel.h"
#import "AppController.h"
#import "TaprSetupWindow.h"
#import "TaprSetupBackgroundView.h"
#import "Launchable.h"
#import "MultitouchManager.h"
#import "NSStatusItemPrioritizer.h"
@class AppController, TaprSetupBackgroundView;

@interface TaprSetupController : NSObject

@property TaprSetupModel *setupModel;
@property AppController *appController;
@property TaprSetupWindow *setupWindow;

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib;
- (void)applicationDidFinishLaunching;
#pragma mark -

#pragma mark -
#pragma mark Interface Control
- (void)updateSetupControls;
#pragma mark -

#pragma mark -
#pragma mark Window Methods
- (void)positionSetupWindow;
- (IBAction)toggleSetupWindow:(id)sender;
- (void)hideSetupWindow;
- (void)windowDidResignKey:(NSNotification *)notification;
- (void)repositionSetupWindow:(NSNotification *)notification;
#pragma mark -

#pragma mark -
#pragma mark Tapr Options
- (IBAction)loginStartOptionChanged:(id)sender;
#pragma mark -

@end
