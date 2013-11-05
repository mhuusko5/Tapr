#import "TaprRecognitionModel.h"

@implementation TaprRecognitionModel

@synthesize openedAppDictionary, activatedAppDictionary;

- (id)init {
	self = [super init];
    
	userDefaults = [NSUserDefaults standardUserDefaults];
    
	[self generateActivatedAppDictionary];
    
	[self startAppActivationLogging];
    
	return self;
}

#pragma mark -
#pragma mark Opened App Fetching
- (NSMutableArray *)getMostOpenedAppArray {
	return [NSMutableArray arrayWithArray:[[[[openedAppDictionary allValues] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [[NSNumber numberWithInt:b.activationCount] compare:[NSNumber numberWithInt:a.activationCount]];
	}] subarrayWithRange:NSMakeRange(0, 6)] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [a.displayName compare:b.displayName];
	}]];
}

- (NSMutableDictionary *)generateOpenedAppDictionary {
	openedAppDictionary = [self fetchNormalAppDictionary];
	[openedAppDictionary addEntriesFromDictionary:[self fetchUtilitiesAppDictionary]];
	[openedAppDictionary addEntriesFromDictionary:[self fetchSystemAppDictionary]];
    
	return openedAppDictionary;
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
                
				NSString *bundleId = [bundle objectForKey:@"CFBundleIdentifier"];
				NSString *displayName = [[[NSFileManager defaultManager] displayNameAtPath:filePath] stringByDeletingPathExtension];
				NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:filePath];
                
				int useCount = 0;
				@try {
					MDItemRef item = MDItemCreate(kCFAllocatorDefault, (CFStringRef)filePath);
					CFTypeRef ref = MDItemCopyAttribute(item, (CFStringRef)@"kMDItemUseCount");
					NSObject *tempObject = (NSObject *)ref;
                    
					if (tempObject) {
						useCount = [[tempObject description] intValue];
					}
                    
					if (ref != NULL) {
						CFRelease(ref);
					}
                    
					if (item != NULL) {
						CFRelease(item);
					}
				}
				@catch (NSException *exception)
				{
				}
                
				if (bundleId && useCount > 0 && ![bundleId isEqualToString:[[NSBundle mainBundle] bundleIdentifier]] && ![bundleId isEqualToString:@"com.mhuusko5.Gestr"]) {
					[dict setObject:[[Application alloc] initWithDisplayName:displayName icon:icon bundleId:bundleId activationCount:useCount] forKey:bundleId];
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
	return [NSMutableArray arrayWithArray:[[[[activatedAppDictionary allValues] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [[NSNumber numberWithInt:b.activationCount] compare:[NSNumber numberWithInt:a.activationCount]];
	}] subarrayWithRange:NSMakeRange(0, 6)] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [a.displayName compare:b.displayName];
	}]];
}

- (NSMutableDictionary *)generateActivatedAppDictionary {
	[self fetchActiveAppSwitchDictionary];
    
    [self generateOpenedAppDictionary];
    
	NSMutableDictionary *newActivatedAppDictionary = [NSMutableDictionary dictionary];
    
	for (id switchId in activeAppSwitchDictionary) {
		NSString *nextActiveAppBundleId = [[switchId componentsSeparatedByString:@":"] objectAtIndex:1];
        
		if ([openedAppDictionary objectForKey:nextActiveAppBundleId]) {
			int nextActiveAppActivatedCount = [[activeAppSwitchDictionary objectForKey:switchId] intValue];
            
			Application *appWithNextActiveAppBundleId;
			if ((appWithNextActiveAppBundleId = [newActivatedAppDictionary objectForKey:nextActiveAppBundleId])) {
				appWithNextActiveAppBundleId.activationCount += nextActiveAppActivatedCount;
			}
			else {
				NSString *nextActiveAppPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:nextActiveAppBundleId];
                
				NSString *nextActiveAppName = [[[NSFileManager defaultManager] displayNameAtPath:nextActiveAppPath] stringByDeletingPathExtension];
				NSImage *nextActiveAppIcon = [[NSWorkspace sharedWorkspace] iconForFile:nextActiveAppPath];
                
				appWithNextActiveAppBundleId = [[Application alloc] initWithDisplayName:nextActiveAppName icon:nextActiveAppIcon bundleId:nextActiveAppBundleId activationCount:nextActiveAppActivatedCount];
                
				[newActivatedAppDictionary setObject:appWithNextActiveAppBundleId forKey:nextActiveAppBundleId];
			}
		}
	}
    
	return (activatedAppDictionary = newActivatedAppDictionary);
}

- (void)startAppActivationLogging {
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(nextAppActivated:) name:NSWorkspaceDidActivateApplicationNotification object:nil];
}

- (void)nextAppActivated:(NSNotification *)notification {
	NSRunningApplication *nextActiveApp = [[notification userInfo] objectForKey:@"NSWorkspaceApplicationKey"];
	if ([nextActiveApp.bundleIdentifier isEqualToString:[[NSBundle mainBundle] bundleIdentifier]] || [nextActiveApp.bundleIdentifier isEqualToString:@"com.mhuusko5.Gestr"]) {
		return;
	}
    
	if (lastActiveApp && ![lastActiveApp.bundleIdentifier isEqualToString:nextActiveApp.bundleIdentifier]) {
		[self logSwitchToApplication:nextActiveApp];
	}
    
	lastActiveApp = nextActiveApp;
}

- (void)logSwitchToApplication:(NSRunningApplication *)nextActiveApp {
	[self fetchActiveAppSwitchDictionary];
    
	NSString *switchId = [NSString stringWithFormat:@"%@:%@", lastActiveApp.bundleIdentifier, nextActiveApp.bundleIdentifier];
    
	int switchIdOccurrence;
	if ((switchIdOccurrence = [[activeAppSwitchDictionary objectForKey:switchId] intValue])) {
		[activeAppSwitchDictionary setObject:[NSNumber numberWithInt:(switchIdOccurrence + 1)] forKey:switchId];
	}
	else {
		[activeAppSwitchDictionary setObject:[NSNumber numberWithInt:1] forKey:switchId];
	}
    
	[self saveActiveAppSwitchDictionary];
}

- (NSMutableDictionary *)fetchActiveAppSwitchDictionary {
	NSMutableDictionary *savedActiveAppSwitchDictionary;
	@try {
		NSData *appSwitchData;
		if ((appSwitchData = [userDefaults objectForKey:@"ActiveAppSwitchDictionary"])) {
			savedActiveAppSwitchDictionary = [NSMutableDictionary dictionaryWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:appSwitchData]];
		}
		else {
			savedActiveAppSwitchDictionary = [NSMutableDictionary dictionary];
			[self saveActiveAppSwitchDictionary];
		}
	}
	@catch (NSException *exception)
	{
		savedActiveAppSwitchDictionary = [NSMutableDictionary dictionary];
		[self saveActiveAppSwitchDictionary];
	}
    
	activeAppSwitchDictionary = savedActiveAppSwitchDictionary;
}

- (void)saveActiveAppSwitchDictionary {
	[userDefaults setObject:[NSKeyedArchiver archivedDataWithRootObject:activeAppSwitchDictionary] forKey:@"ActiveAppSwitchDictionary"];
	[userDefaults synchronize];
}

#pragma mark -

@end
