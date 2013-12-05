#import "Application.h"

@implementation Application

- (id)initWithDisplayName:(NSString *)displayName icon:(NSImage *)icon bundleId:(NSString *)bundleId activationCount:(int)activationCount {
	NSString *launchId = bundleId;

	self = [super initWithDisplayName:displayName launchId:launchId icon:icon];

	_bundleId = bundleId;
	_activationCount = activationCount;

	return self;
}

- (void)launch {
	[[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier:self.bundleId options:NSWorkspaceLaunchDefault additionalEventParamDescriptor:nil launchIdentifier:nil];
}

- (NSString *)description {
	return [NSString stringWithFormat:@"%@ - %i", self.displayName, self.activationCount];
}

@end
