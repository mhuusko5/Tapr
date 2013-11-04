#import "Application.h"

@implementation Application

@synthesize bundleId, activationCount;

- (id)initWithDisplayName:(NSString *)_displayName icon:(NSImage *)_icon bundleId:(NSString *)_bundleId activationCount:(int)_activationCount {
	NSString *_launchId = _bundleId;
    
	self = [super initWithDisplayName:_displayName launchId:_launchId icon:_icon];
    
	bundleId = _bundleId;
    activationCount = _activationCount;
    
	return self;
}

- (void)launch {
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:bundleId options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:nil];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"%@ - %i", displayName, activationCount];
}

@end
