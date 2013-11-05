#import "TaprRecognitionModel.h"
#import "AppController.h"
#import "TaprRecognitionWindow.h"
#import "Launchable.h"
#import "MultitouchManager.h"
#import "TaprSetupBackgroundView.h"

@class AppController, TaprSetupBackgroundView;

@interface TaprRecognitionController : NSObject {
	BOOL awakedFromNib;
    
	TaprRecognitionModel *recognitionModel;
    
	AppController *appController;
    
	IBOutlet TaprRecognitionWindow *recognitionWindow;
    
	IBOutlet NSImageView *appIcon1, *appIcon2, *appIcon3, *appIcon4, *appIcon5, *appIcon6;
    
	NSArray *appArrayToUse;
    
	NSMutableArray *recentThreeFingerTouches;
    
	BOOL listeningToTap;
    
    BOOL ignoringActivation;
    
    int lastAppSelection;
    
	NSTimer *noTapTimer;
}
@property (retain) TaprRecognitionModel *recognitionModel;
@property (retain) AppController *appController;
@property (retain) TaprRecognitionWindow *recognitionWindow;
@property BOOL listeningToTap;

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib;
- (void)applicationDidFinishLaunching;
#pragma mark -

#pragma mark -
#pragma mark Recognition Utilities
- (void)shouldStartDetectingTap;
- (void)stopDetectingTapWithForce:(BOOL)force;
- (void)noTapDetected;
#pragma mark -

#pragma mark -
#pragma mark Tap Event Handling
- (void)tapMultitouchEvent:(MultitouchEvent *)event;
- (void)activateTappedApp:(Application *)tappedApp;
#pragma mark -

#pragma mark -
#pragma mark Activation Event Handling
- (void)activationMultitouchEvent:(MultitouchEvent *)event;
- (void)ignoreActivation:(NSArray *)ignoreAndSeconds;
- (CGEventRef)handleEvent:(CGEventRef)event withType:(int)type;
CGEventRef handleEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef eventRef, void *refcon);

#pragma mark -

#pragma mark -
#pragma Activation Controls
- (void)configureAppIcons;
- (void)setAppIconShadowsWithSelection:(int)selection;
#pragma mark -

#pragma mark -
#pragma mark Window Methods
- (void)showRecognitionWindow;
- (void)hideRecognitionWindowWithFade:(BOOL)fade;
- (void)windowDidResignKey:(NSNotification *)notification;
- (void)layoutRecognitionWindow;
#pragma mark -

@end
