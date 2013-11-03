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
    
	NSMutableArray *recentThreeFingerTouches;
    
    BOOL detectingTap;
    
    NSTimer *noTapTimer;
}
@property (retain) TaprRecognitionModel *recognitionModel;
@property (retain) AppController *appController;
@property (retain) TaprRecognitionWindow *recognitionWindow;
@property BOOL detectingTap;

#pragma mark -
#pragma mark Initialization
- (void)awakeFromNib;
- (void)applicationDidFinishLaunching;
#pragma mark -

#pragma mark -
#pragma mark Recognition Utilities
- (void)shouldStartDetectingTap;
- (void)stopDetectingTap:(BOOL)force;
- (void)noTapInput;
#pragma mark -

#pragma mark -
#pragma mark Tap Event Handling
- (void)startListeningForTapEvent;
- (void)tapMultitouchEvent:(MultitouchEvent *)event;
#pragma mark -

#pragma mark -
#pragma mark Activation Event Handling
- (void)activationMultitouchEvent:(MultitouchEvent *)event;
- (CGEventRef)handleEvent:(CGEventRef)event withType:(int)type;
CGEventRef handleEvent(CGEventTapProxy proxy, CGEventType type, CGEventRef eventRef, void *refcon);

#pragma mark -

#pragma mark -
#pragma mark Window Methods
- (void)showRecognitionWindow;
- (void)hideRecognitionWindow;
- (void)windowDidResignKey:(NSNotification *)notification;
- (void)layoutRecognitionWindow;
#pragma mark -

@end
