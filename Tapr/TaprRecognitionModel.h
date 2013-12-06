#import "Application.h"

@interface NSMetadataItem (Private)
- (id)_init:(struct __MDItem *)fp8;
@end

@interface TaprRecognitionModel : NSObject

@property NSMutableDictionary *openedAppDictionary;
@property NSMutableDictionary *activatedAppDictionary;

#pragma mark -
#pragma mark Setup
- (void)setup;
#pragma mark -

#pragma mark -
#pragma mark Opened App Fetching
- (NSMutableArray *)getMostOpenedAppArray;
- (NSMutableDictionary *)generateOpenedAppDictionary;
- (NSMutableDictionary *)fetchNormalAppDictionary;
- (NSMutableDictionary *)fetchUtilitiesAppDictionary;
- (NSMutableDictionary *)fetchSystemAppDictionary;
- (NSMutableDictionary *)addApplicationsAtPath:(NSString *)path toDictonary:(NSMutableDictionary *)dict depth:(int)depth;
#pragma mark -

#pragma mark -
#pragma mark App Activation Logging
- (NSMutableArray *)getMostActivatedAppArray;
- (NSMutableDictionary *)generateActivatedAppDictionary;
- (void)startAppActivationLogging;
- (void)nextAppActivated:(NSNotification *)notification;
- (void)logSwitchToApplication:(NSRunningApplication *)nextActiveApp;
- (NSMutableDictionary *)fetchActiveAppSwitchDictionary;
- (void)saveActiveAppSwitchDictionary;
#pragma mark -

@end
