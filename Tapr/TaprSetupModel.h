#import "MultitouchManager.h"
#import "Application.h"

@interface TaprSetupModel : NSObject

@property BOOL loginStartOption, applicationPreviewOption;

#pragma mark -
#pragma mark Setup
- (void)setup;
#pragma mark -

#pragma mark -
#pragma mark Tapr Options
- (BOOL)fetchLoginStartOption;
- (void)saveLoginStartOption:(BOOL)newChoice;
- (BOOL)fetchApplicationPreviewOption;
- (void)saveApplicationPreviewOption:(BOOL)newChoice;
#pragma mark -

@end
