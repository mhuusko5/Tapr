#import "Application.h"

@interface TaprRecognitionModel : NSObject {
	NSUserDefaults *userDefaults;
    
    NSMutableArray *mostOpenedAppArray;
    NSMutableArray *mostActivatedAppArray;
    
    NSMutableDictionary *activeAppSwitchDictionary;
    
    NSRunningApplication *lastActiveApp;
}
@property (retain) NSMutableArray *mostOpenedAppArray;
@property (retain) NSMutableArray *mostActivatedAppArray;

#pragma mark -
#pragma mark Opened App Fetching
- (NSMutableArray *)fetchMostOpenedAppArray;
- (NSMutableArray *)fetchNormalAppArray;
- (NSMutableArray *)fetchUtilitiesAppArray;
- (NSMutableArray *)fetchSystemAppArray;
- (NSMutableArray *)addApplicationsAtPath:(NSString *)path toArray:(NSMutableArray *)arr depth:(int)depth;
#pragma mark -

#pragma mark -
#pragma mark App Activation Logging
- (NSMutableArray *)generateMostActivatedAppArray;
- (void)startAppActivationLogging;
- (void)nextAppActivated:(NSNotification *)notification;
- (void)logSwitchToApplication:(NSRunningApplication *)nextActiveApp;
- (NSMutableDictionary *)fetchActiveAppSwitchDictionary;
- (void)saveActiveAppSwitchDictionary;
#pragma mark -

@end
