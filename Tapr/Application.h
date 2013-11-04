#import "Launchable.h"

@interface Application : Launchable {
	NSString *bundleId;
    int activationCount;
}
@property NSString *bundleId;
@property int activationCount;

- (id)initWithDisplayName:(NSString *)_displayName icon:(NSImage *)_icon bundleId:(NSString *)_bundleId activationCount:(int)_activationCount;
- (void)launch;

@end
