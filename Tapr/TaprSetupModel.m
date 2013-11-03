#import "TaprSetupModel.h"

@implementation TaprSetupModel

@synthesize loginStartOption;

- (id)init {
	self = [super init];
    
	userDefaults = [NSUserDefaults standardUserDefaults];
    
	[self saveLoginStartOption:[self fetchLoginStartOption]];
    
	return self;
}

#pragma mark -
#pragma mark Tapr Options
- (BOOL)fetchLoginStartOption {
	NSURL *itemURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	Boolean foundIt = false;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		UInt32 seed = 0U;
		NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				foundIt = CFEqual(URL, itemURL);
				CFRelease(URL);
				if (foundIt) {
					break;
				}
			}
		}
		CFRelease(loginItems);
	}
    
	return (loginStartOption = foundIt);
}

- (void)saveLoginStartOption:(BOOL)newChoice {
	loginStartOption = newChoice;
    
	NSURL *itemURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] bundlePath]];
	LSSharedFileListItemRef existingItem = NULL;
	LSSharedFileListRef loginItems = LSSharedFileListCreate(NULL, kLSSharedFileListSessionLoginItems, NULL);
	if (loginItems) {
		UInt32 seed = 0U;
		NSArray *currentLoginItems = [NSMakeCollectable(LSSharedFileListCopySnapshot(loginItems, &seed)) autorelease];
		for (id itemObject in currentLoginItems) {
			LSSharedFileListItemRef item = (LSSharedFileListItemRef)itemObject;
			UInt32 resolutionFlags = kLSSharedFileListNoUserInteraction | kLSSharedFileListDoNotMountVolumes;
			CFURLRef URL = NULL;
			OSStatus err = LSSharedFileListItemResolve(item, resolutionFlags, &URL, /*outRef*/ NULL);
			if (err == noErr) {
				Boolean foundIt = CFEqual(URL, itemURL);
				CFRelease(URL);
				if (foundIt) {
					existingItem = item;
					break;
				}
			}
		}
		if (loginStartOption && (existingItem == NULL)) {
			LSSharedFileListInsertItemURL(loginItems, kLSSharedFileListItemBeforeFirst, NULL, NULL, (CFURLRef)itemURL, NULL, NULL);
		}
		else if (!loginStartOption && (existingItem != NULL)) {
			LSSharedFileListItemRemove(loginItems, existingItem);
		}
		CFRelease(loginItems);
	}
}

#pragma mark -

@end
