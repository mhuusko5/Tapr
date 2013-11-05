#import "Application.h"

@interface TaprRecognitionModel : NSObject {
	NSUserDefaults *userDefaults;
    
	NSMutableDictionary *openedAppDictionary;
	NSMutableDictionary *activatedAppDictionary;
    
	NSMutableDictionary *activeAppSwitchDictionary;
	NSRunningApplication *lastActiveApp;
}
@property (retain) NSMutableDictionary *openedAppDictionary;
@property (retain) NSMutableDictionary *activatedAppDictionary;

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
