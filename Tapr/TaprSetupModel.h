#import "MultitouchManager.h"
#import "Application.h"

@interface TaprSetupModel : NSObject

@property BOOL loginStartOption;

#pragma mark -
#pragma mark Setup
- (void)setup;
#pragma mark -

#pragma mark -
#pragma mark Tapr Options
- (BOOL)fetchLoginStartOption;
- (void)saveLoginStartOption:(BOOL)newChoice;
#pragma mark -

@end
