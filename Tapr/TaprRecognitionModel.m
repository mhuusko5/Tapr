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
	return [[[[[_openedAppDictionary allValues] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [@(b.activationCount)compare : @(a.activationCount)];
	}] subarrayWithRange:NSMakeRange(0, 6)] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [a.displayName compare:b.displayName];
	}] mutableCopy];
}

- (NSMutableDictionary *)generateOpenedAppDictionary {
	_openedAppDictionary = [self fetchNormalAppDictionary];
	[_openedAppDictionary addEntriesFromDictionary:[self fetchUtilitiesAppDictionary]];
	[_openedAppDictionary addEntriesFromDictionary:[self fetchSystemAppDictionary]];

	return _openedAppDictionary;
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
					NSMetadataItem *metadata = [[NSMetadataItem alloc] _init:MDItemCreate(NULL, (__bridge CFStringRef)(filePath))];
					useCount = [[metadata valueForAttribute:@"kMDItemUseCount"] intValue];
				}
				@catch (NSException *exception)
				{
				}

				if (bundleId && useCount > 0 && ![bundleId isEqualToString:[[NSBundle mainBundle] bundleIdentifier]] && ![bundleId isEqualToString:@"com.mhuusko5.Gestr"] && displayName && icon) {
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
	return [[[[[_activatedAppDictionary allValues] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [@(b.activationCount)compare : @(a.activationCount)];
	}] subarrayWithRange:NSMakeRange(0, 6)] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [a.displayName compare:b.displayName];
	}] mutableCopy];
}

- (NSMutableDictionary *)generateActivatedAppDictionary {
	[self fetchActiveAppSwitchDictionary];

	NSMutableDictionary *newActivatedAppDictionary = [NSMutableDictionary dictionary];

	NSMutableArray *keysToCleanAppSwitchDictionary = [NSMutableArray array];

	for (id switchId in _activeAppSwitchDictionary) {
		NSString *nextActiveAppBundleId = [switchId componentsSeparatedByString:@":"][1];

		int nextActiveAppActivatedCount = [_activeAppSwitchDictionary[switchId] intValue];

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

	[_activeAppSwitchDictionary removeObjectsForKeys:keysToCleanAppSwitchDictionary];
	[self saveActiveAppSwitchDictionary];

	return (_activatedAppDictionary = newActivatedAppDictionary);
}

- (void)startAppActivationLogging {
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(nextAppActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
}

- (void)nextAppActivated:(NSNotification *)notification {
	NSRunningApplication *nextActiveApp = [notification userInfo][@"NSWorkspaceApplicationKey"];
	if ([nextActiveApp.bundleIdentifier isEqualToString:[[NSBundle mainBundle] bundleIdentifier]] || [nextActiveApp.bundleIdentifier isEqualToString:@"com.mhuusko5.Gestr"]) {
		return;
	}

	if (_lastActiveApp && ![_lastActiveApp.bundleIdentifier isEqualToString:nextActiveApp.bundleIdentifier]) {
		[self logSwitchToApplication:nextActiveApp];
	}

	_lastActiveApp = nextActiveApp;
}

- (void)logSwitchToApplication:(NSRunningApplication *)nextActiveApp {
	[self fetchActiveAppSwitchDictionary];

	NSString *switchId = [NSString stringWithFormat:@"%@:%@", _lastActiveApp.bundleIdentifier, nextActiveApp.bundleIdentifier];

	int switchIdOccurrence;
	if ((switchIdOccurrence = [_activeAppSwitchDictionary[switchId] intValue])) {
		_activeAppSwitchDictionary[switchId] = @(switchIdOccurrence + 1);
	}
	else {
		_activeAppSwitchDictionary[switchId] = @1;
	}

	[self saveActiveAppSwitchDictionary];
}

- (NSMutableDictionary *)fetchActiveAppSwitchDictionary {
	@try {
		NSData *appSwitchData;
		if ((appSwitchData = [_storage objectForKey:@"ActiveAppSwitchDictionary"])) {
			_activeAppSwitchDictionary = [[NSKeyedUnarchiver unarchiveObjectWithData:appSwitchData] mutableCopy];
		}
		else {
			_activeAppSwitchDictionary = [NSMutableDictionary dictionary];
		}
	}
	@catch (NSException *exception)
	{
		_activeAppSwitchDictionary = [NSMutableDictionary dictionary];
	}
}

- (void)saveActiveAppSwitchDictionary {
	[_storage setObject:[NSKeyedArchiver archivedDataWithRootObject:_activeAppSwitchDictionary] forKey:@"ActiveAppSwitchDictionary"];
	[_storage synchronize];
}

#pragma mark -

@end
