#import "Launchable.h"

@interface Application : Launchable

@property NSString *bundleId;
@property int activationCount;

- (id)initWithDisplayName:(NSString *)displayName icon:(NSImage *)icon bundleId:(NSString *)bundleId activationCount:(int)activationCount;
- (void)launch;

@end
