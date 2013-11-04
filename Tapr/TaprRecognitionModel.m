#import "TaprRecognitionModel.h"

@implementation TaprRecognitionModel

@synthesize mostOpenedAppArray, mostActivatedAppArray;

- (id)init {
	self = [super init];
    
	userDefaults = [NSUserDefaults standardUserDefaults];
    
    [self fetchMostOpenedAppArray];
    
    [self generateMostActivatedAppArray];
    
    [self startAppActivationLogging];
    
	return self;
}

#pragma mark -
#pragma mark Opened App Fetching
- (NSMutableArray *)fetchMostOpenedAppArray {
    mostOpenedAppArray = [self fetchNormalAppArray];
    [mostOpenedAppArray addObjectsFromArray:[self fetchUtilitiesAppArray]];
    [mostOpenedAppArray addObjectsFromArray:[self fetchSystemAppArray]];
    mostOpenedAppArray = [NSMutableArray arrayWithArray: [mostOpenedAppArray sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [[NSNumber numberWithInt:b.activationCount] compare:[NSNumber numberWithInt:a.activationCount]];;
	}]];
    
    return mostOpenedAppArray;
}

- (NSMutableArray *)fetchNormalAppArray {
    return [self addApplicationsAtPath:@"/Applications" toArray:[NSMutableArray array] depth:1];
}

- (NSMutableArray *)fetchUtilitiesAppArray {
    return [self addApplicationsAtPath:@"/Applications/Utilities" toArray:[NSMutableArray array] depth:1];
}

- (NSMutableArray *)fetchSystemAppArray {
    return [self addApplicationsAtPath:@"/System/Library/CoreServices" toArray:[NSMutableArray array] depth:0];
}

- (NSMutableArray *)addApplicationsAtPath:(NSString *)path toArray:(NSMutableArray *)arr depth:(int)depth {
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
				NSDictionary *dict = [[NSBundle bundleWithPath:[fileUrl path]] infoDictionary];
                
				NSString *bundleId = [dict objectForKey:@"CFBundleIdentifier"];
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
					[arr addObject:[[Application alloc] initWithDisplayName:displayName icon:icon bundleId:bundleId activationCount:useCount]];
				}
			}
			else if (isDir && depth > 0 && ![filePath isEqualToString:@"/Applications/Utilities"]) {
				[self addApplicationsAtPath:filePath toArray:arr depth:depth - 1];
			}
		}
	}
    
	return arr;
}

#pragma mark -

#pragma mark -
#pragma mark App Activation Logging
- (NSMutableArray *)generateMostActivatedAppArray {
    [self fetchActiveAppSwitchDictionary];
    
    NSMutableArray *newMostActivatedAppArray = [NSMutableArray array];
    
    NSMutableDictionary *newMostActivatedAppDictionary = [NSMutableDictionary dictionary];
    
    for (id switchId in activeAppSwitchDictionary) {
        NSString *nextActiveAppBundleId = [[switchId componentsSeparatedByString:@":"] objectAtIndex:1];
        int nextActiveAppActivatedCount = [[activeAppSwitchDictionary objectForKey:switchId] intValue];
        
        Application *appWithNextActiveAppBundleId;
        if ((appWithNextActiveAppBundleId = [newMostActivatedAppDictionary objectForKey:nextActiveAppBundleId])) {
            appWithNextActiveAppBundleId.activationCount += nextActiveAppActivatedCount;
        } else {
            NSString *nextActiveAppPath = [[NSWorkspace sharedWorkspace] absolutePathForAppBundleWithIdentifier:nextActiveAppBundleId];
            
            NSString *nextActiveAppName = [[[NSFileManager defaultManager] displayNameAtPath:nextActiveAppPath] stringByDeletingPathExtension];
            NSImage *nextActiveAppIcon =[[NSWorkspace sharedWorkspace] iconForFile:nextActiveAppPath];
            
            appWithNextActiveAppBundleId = [[Application alloc] initWithDisplayName:nextActiveAppName icon:nextActiveAppIcon bundleId:nextActiveAppBundleId activationCount:nextActiveAppActivatedCount];
            
            [newMostActivatedAppDictionary setObject:appWithNextActiveAppBundleId forKey:nextActiveAppBundleId];
        }
    }
    
    [newMostActivatedAppArray addObjectsFromArray:[[newMostActivatedAppDictionary allValues] sortedArrayUsingComparator: ^NSComparisonResult (Application *a, Application *b) {
	    return [[NSNumber numberWithInt:b.activationCount] compare:[NSNumber numberWithInt:a.activationCount]];;
	}]];
    
    return (mostActivatedAppArray = newMostActivatedAppArray);
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
    } else {
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
