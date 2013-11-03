#import "MultitouchManager.h"
#import "Application.h"

@interface TaprSetupModel : NSObject {
	NSUserDefaults *userDefaults;
    
	BOOL loginStartOption;
}
@property BOOL loginStartOption;

#pragma mark -
#pragma mark Tapr Options
- (BOOL)fetchLoginStartOption;
- (void)saveLoginStartOption:(BOOL)newChoice;
#pragma mark -

@end
