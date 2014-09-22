#import "TaprSetupModel.h"

@implementation TaprSetupModel

#pragma mark -
#pragma mark Setup
- (void)setup {
	[self saveLoginStartOption:[self fetchLoginStartOption]];
    [self fetchAppCyclingOption];
	[self fetchApplicationPreviewOption];
}

#pragma mark -

#pragma mark -
#pragma mark Tapr Options
- (BOOL)fetchLoginStartOption {
	NSURL *itemURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	Boolean foundIt = false;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		UInt32 seed = 0U;
		NSArray *currentLoginItems = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(loginItems, &seed);
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				foundIt = CFEqual(URL, (__bridge CFTypeRef)(itemURL));
				CFRelease(URL);
				if (foundIt) {
					break;
				}
			}
		}
		CFRelease(loginItems);
	}

	return (_loginStartOption = foundIt);
}

- (void)saveLoginStartOption:(BOOL)newChoice {
	_loginStartOption = newChoice;

	NSURL *itemURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	LSSharedFileListItemRef existingItem = NULL;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		UInt32 seed = 0U;
		NSArray *currentLoginItems = (__bridge_transfer NSArray *)LSSharedFileListCopySnapshot(loginItems, &seed);
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (__bridge LSSharedFileListItemRef)itemObject;
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				Boolean foundIt = CFEqual(URL, (__bridge CFTypeRef)(itemURL));
				CFRelease(URL);
				if (foundIt) {
					existingItem = item;
					break;
				}
			}
		}
		if (_loginStartOption && (existingItem == NULL)) {
			LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, NULL, NULL, (__bridge CFURLRef)itemURL, NULL, NULL);
		}
		else if (!_loginStartOption && (existingItem != NULL)) {
			LSSharedFileListItemRemove(loginItems, existingItem);
		}
		CFRelease(loginItems);
	}
}

- (BOOL)fetchAppCyclingOption {
    id storedAppCyclingOption;
    if ((storedAppCyclingOption = [[NSUserDefaults standardUserDefaults] objectForKey:@"appCyclingOption"])) {
        _appCyclingOption = [storedAppCyclingOption boolValue];
    }
    else {
        [self saveAppCyclingOption:NO];
    }
    
    return _appCyclingOption;
}

- (void)saveAppCyclingOption:(BOOL)newChoice {
    [[NSUserDefaults standardUserDefaults] setBool:(_appCyclingOption = newChoice) forKey:@"appCyclingOption"];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (BOOL)fetchApplicationPreviewOption {
	id storedApplicationPreviewOption;
	if ((storedApplicationPreviewOption = [[NSUserDefaults standardUserDefaults] objectForKey:@"applicationPreviewOption"])) {
		_applicationPreviewOption = [storedApplicationPreviewOption boolValue];
	}
	else {
		[self saveApplicationPreviewOption:YES];
	}

	return _applicationPreviewOption;
}

- (void)saveApplicationPreviewOption:(BOOL)newChoice {
	[[NSUserDefaults standardUserDefaults] setBool:(_applicationPreviewOption = newChoice) forKey:@"applicationPreviewOption"];
	[[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark -

@end
