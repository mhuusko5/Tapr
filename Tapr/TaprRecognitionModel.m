#import "TaprRecognitionModel.h"

@interface TaprRecognitionModel ()

@property NSUserDefaults *storage;

@property NSMutableDictionary *activeAppSwitchDictionary;
@property NSRunningApplication *lastActiveApp;

@end

@implementation TaprRecognitionModel

- (id)init {
	self = [super init];

	_storage = [NSUserDefaults standardUserDefaults];

	return self;
}

#pragma mark -
#pragma mark Setup
- (void)setup {
	[self generateOpenedAppDictionary];

	[self generateActivatedAppDictionary];

	[self startAppActivationLogging];
}

#pragma mark -

#pragma mark -
#pragma mark Opened App Fetching
- (NSMutableArray *)getMostOpenedAppArray {
	return [NSMutableArray arrayWithArray:[[[[self.openedAppDictionary allValues] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [@(b.activationCount)compare : @(a.activationCount)];
	}] subarrayWithRange:NSMakeRange(0, 6)] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [a.displayName compare:b.displayName];
	}]];
}

- (NSMutableDictionary *)generateOpenedAppDictionary {
	self.openedAppDictionary = [self fetchNormalAppDictionary];
	[self.openedAppDictionary addEntriesFromDictionary:[self fetchUtilitiesAppDictionary]];
	[self.openedAppDictionary addEntriesFromDictionary:[self fetchSystemAppDictionary]];

	return self.openedAppDictionary;
}

- (NSMutableDictionary *)fetchNormalAppDictionary {
	return [self addApplicationsAtPath:@"/Applications" toDictonary:[NSMutableDictionary dictionary] depth:2];
}

- (NSMutableDictionary *)fetchUtilitiesAppDictionary {
	return [self addApplicationsAtPath:@"/Applications/Utilities" toDictonary:[NSMutableDictionary dictionary] depth:1];
}

- (NSMutableDictionary *)fetchSystemAppDictionary {
	return [self addApplicationsAtPath:@"/System/Library/CoreServices" toDictonary:[NSMutableDictionary dictionary] depth:0];
}

- (NSMutableDictionary *)addApplicationsAtPath:(NSString *)path toDictonary:(NSMutableDictionary *)dict depth:(int)depth {
	NSURL *url;
	if (!(url = [NSURL URLWithString:[path stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]])) {
		return nil;
	}
	NSDirectoryEnumerator *directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtURL:url includingPropertiesForKeys:nil options:(NSDirectoryEnumerationSkipsSubdirectoryDescendants | NSDirectoryEnumerationSkipsPackageDescendants | NSDirectoryEnumerationSkipsHiddenFiles) errorHandler:nil];
	NSURL *fileUrl;
	while (fileUrl = [directoryEnumerator nextObject]) {
		NSString *filePath = [fileUrl path];
		BOOL isDir;
		if ([[NSFileManager defaultManager] fileExistsAtPath:filePath isDirectory:&isDir]) {
			if ([[fileUrl pathExtension] isEqualToString:@"app"]) {
				NSDictionary *bundle = [[NSBundle bundleWithPath:[fileUrl path]] infoDictionary];

				NSString *bundleId = bundle[@"CFBundleIdentifier"];
				NSString *displayName = [[[NSFileManager defaultManager] displayNameAtPath:filePath] stringByDeletingPathExtension];
				NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:filePath];

				int useCount = 0;
				@try {
					MDItemRef item = MDItemCreate(kCFAllocatorDefault, (__bridge CFStringRef)filePath);

					NSObject *tempObject = (__bridge_transfer NSObject *)MDItemCopyAttribute(item, (CFStringRef)@"kMDItemUseCount");
					if (tempObject) {
						useCount = [[tempObject description] intValue];
					}

					CFRelease(item);
				}
				@catch (NSException *exception)
				{
				}

				if (bundleId && useCount > 0 && ![bundleId isEqualToString:[[NSBundle mainBundle] bundleIdentifier]] && ![bundleId isEqualToString:@"com.mhuusko5.Gestr"]) {
					dict[bundleId] = [[Application alloc] initWithDisplayName:displayName icon:icon bundleId:bundleId activationCount:useCount];
				}
			}
			else if (isDir && depth > 0 && ![filePath isEqualToString:@"/Applications/Utilities"]) {
				[self addApplicationsAtPath:filePath toDictonary:dict depth:depth - 1];
			}
		}
	}

	return dict;
}

#pragma mark -

#pragma mark -
#pragma mark App Activation Logging
- (NSMutableArray *)getMostActivatedAppArray {
	return [NSMutableArray arrayWithArray:[[[[self.activatedAppDictionary allValues] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [@(b.activationCount)compare : @(a.activationCount)];
	}] subarrayWithRange:NSMakeRange(0, 6)] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [a.displayName compare:b.displayName];
	}]];
}

- (NSMutableDictionary *)generateActivatedAppDictionary {
	[self fetchActiveAppSwitchDictionary];

	NSMutableDictionary *newActivatedAppDictionary = [NSMutableDictionary dictionary];

	NSMutableArray *keysToCleanAppSwitchDictionary = [NSMutableArray array];

	for (id switchId in self.activeAppSwitchDictionary) {
		NSString *nextActiveAppBundleId = [switchId componentsSeparatedByString:@":"][1];

		int nextActiveAppActivatedCount = [self.activeAppSwitchDictionary[switchId] intValue];

		Application *appWithNextActiveAppBundleId;
		if ((appWithNextActiveAppBundleId = newActivatedAppDictionary[nextActiveAppBundleId])) {
			appWithNextActiveAppBundleId.activationCount += nextActiveAppActivatedCount;
		}
		else {
			NSString *nextActiveAppPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:nextActiveAppBundleId];

			if (nextActiveAppPath) {
				NSString *nextActiveAppName = [[[NSFileManager defaultManager] displayNameAtPath:nextActiveAppPath] stringByDeletingPathExtension];
				NSImage *nextActiveAppIcon = [[NSWorkspace sharedWorkspace] iconForFile:nextActiveAppPath];

				appWithNextActiveAppBundleId = [[Application alloc] initWithDisplayName:nextActiveAppName icon:nextActiveAppIcon bundleId:nextActiveAppBundleId activationCount:nextActiveAppActivatedCount];

				newActivatedAppDictionary[nextActiveAppBundleId] = appWithNextActiveAppBundleId;
			}
			else {
				[keysToCleanAppSwitchDictionary addObject:switchId];
			}
		}
	}

	[self.activeAppSwitchDictionary removeObjectsForKeys:keysToCleanAppSwitchDictionary];
	[self saveActiveAppSwitchDictionary];

	return (self.activatedAppDictionary = newActivatedAppDictionary);
}

- (void)startAppActivationLogging {
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(nextAppActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
}

- (void)nextAppActivated:(NSNotification *)notification {
	NSRunningApplication *nextActiveApp = [notification userInfo][@"NSWorkspaceApplicationKey"];
	if ([nextActiveApp.bundleIdentifier isEqualToString:[[NSBundle mainBundle] bundleIdentifier]] || [nextActiveApp.bundleIdentifier isEqualToString:@"com.mhuusko5.Gestr"]) {
		return;
	}

	if (self.lastActiveApp && ![self.lastActiveApp.bundleIdentifier isEqualToString:nextActiveApp.bundleIdentifier]) {
		[self logSwitchToApplication:nextActiveApp];
	}

	self.lastActiveApp = nextActiveApp;
}

- (void)logSwitchToApplication:(NSRunningApplication *)nextActiveApp {
	[self fetchActiveAppSwitchDictionary];

	NSString *switchId = [NSString stringWithFormat:@"%@:%@", self.lastActiveApp.bundleIdentifier, nextActiveApp.bundleIdentifier];

	int switchIdOccurrence;
	if ((switchIdOccurrence = [self.activeAppSwitchDictionary[switchId] intValue])) {
		self.activeAppSwitchDictionary[switchId] = @(switchIdOccurrence + 1);
	}
	else {
		self.activeAppSwitchDictionary[switchId] = @1;
	}

	[self saveActiveAppSwitchDictionary];
}

- (NSMutableDictionary *)fetchActiveAppSwitchDictionary {
	NSMutableDictionary *savedActiveAppSwitchDictionary;
	@try {
		NSData *appSwitchData;
		if ((appSwitchData = [self.storage objectForKey:@"ActiveAppSwitchDictionary"])) {
			savedActiveAppSwitchDictionary = [NSMutableDictionary dictionaryWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:appSwitchData]];
		}
		else {
			savedActiveAppSwitchDictionary = [NSMutableDictionary dictionary];
		}
	}
	@catch (NSException *exception)
	{
		savedActiveAppSwitchDictionary = [NSMutableDictionary dictionary];
	}

	self.activeAppSwitchDictionary = savedActiveAppSwitchDictionary;
}

- (void)saveActiveAppSwitchDictionary {
	[self.storage setObject:[NSKeyedArchiver archivedDataWithRootObject:self.activeAppSwitchDictionary] forKey:@"ActiveAppSwitchDictionary"];
	[self.storage synchronize];
}

#pragma mark -

@end
