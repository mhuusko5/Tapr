#import "MultitouchManager.h"

@implementation MultitouchManager

@synthesize forwardingMultitouchEventsToListeners;

- (void)handleMultitouchEvent:(MultitouchEvent *)event {
	if (forwardingMultitouchEventsToListeners) {
		for (MultitouchListener *multitouchListenerToForwardEvent in multitouchListeners) {
			[multitouchListenerToForwardEvent sendMultitouchEvent:event];
		}
	}
}

- (void)startForwardingMultitouchEventsToListeners {
	if ([[NSThread currentThread] isMainThread]) {
		if (!forwardingMultitouchEventsToListeners && [MultitouchManager systemIsMultitouchCapable]) {
			NSArray *mtDevices = (NSArray *)CFBridgingRelease(MTDeviceCreateList());
            
			for (id device in mtDevices) {
				MTDeviceRef mtDevice = (__bridge MTDeviceRef)device;
				MTRegisterContactFrameCallback(mtDevice, mtEventHandler);
				MTDeviceStart(mtDevice, 0);
                
				[multitouchDevices addObject:device];
			}
            
			forwardingMultitouchEventsToListeners = YES;
		}
	}
	else {
		[self performSelectorOnMainThread:@selector(startForwardingMultitouchEventsToListeners) withObject:nil waitUntilDone:NO];
	}
}

- (void)stopForwardingMultitouchEventsToListeners {
	if ([[NSThread currentThread] isMainThread]) {
		if (forwardingMultitouchEventsToListeners) {
			for (int i = (int)multitouchDevices.count - 1; i > 0; i--) {
				id device = [multitouchDevices objectAtIndex:i];
				[multitouchDevices removeObject:device];
                
				@try {
					MTDeviceRef mtDevice = (__bridge MTDeviceRef)device;
					MTUnregisterContactFrameCallback(mtDevice, mtEventHandler);
					MTDeviceStop(mtDevice);
					MTDeviceRelease(mtDevice);
				}
				@catch (NSException *exception)
				{
				}
			}
            
			forwardingMultitouchEventsToListeners = NO;
		}
	}
	else {
		[self performSelectorOnMainThread:@selector(stopForwardingMultitouchEventsToListeners) withObject:nil waitUntilDone:NO];
	}
}

- (void)removeMultitouchListersWithTarget:(id)target andCallback:(SEL)callback {
	int multitouchListenerCount = (int)multitouchListeners.count;
	while (multitouchListenerCount-- > 0) {
		MultitouchListener *multitouchListenerToRemove = [multitouchListeners objectAtIndex:multitouchListenerCount];
		if ([multitouchListenerToRemove.target isEqual:target] && (!callback || multitouchListenerToRemove.callback == callback)) {
			[multitouchListeners removeObject:multitouchListenerToRemove];
		}
	}
}

- (void)addMultitouchListenerWithTarget:(id)target callback:(SEL)callback andThread:(NSThread *)thread {
	[multitouchListeners addObject:[[MultitouchListener alloc] initWithTarget:target callback:callback andThread:thread]];
    
	[self startForwardingMultitouchEventsToListeners];
}

static int mtEventHandler(int mtEventDeviceId, MTTouch *mtEventTouches, int mtEventTouchesNum, double mtEventTimestamp, int mtEventFrameId) {
	MultitouchEvent *multitouchEvent = [[MultitouchEvent alloc] initWithDeviceIdentifier:mtEventDeviceId frameIdentifier:mtEventDeviceId andTimestamp:mtEventTimestamp];
    
	NSMutableArray *multitouchTouches = [[NSMutableArray alloc] initWithCapacity:mtEventTouchesNum];
	for (int i = 0; i < mtEventTouchesNum; i++) {
		MultitouchTouch *multitouchTouch = [[MultitouchTouch alloc] initWithMTTouch:&mtEventTouches[i] andMultitouchEvent:multitouchEvent];
		[multitouchTouches addObject:multitouchTouch];
	}
    
	multitouchEvent.touches = [NSArray arrayWithArray:multitouchTouches];
    
	[[MultitouchManager sharedMultitouchManager] handleMultitouchEvent:multitouchEvent];
    
	return 0;
}

- (void)restartMultitouchEventForwardingAfterWake:(NSNotification *)wakeNotification {
	if ([[NSThread currentThread] isMainThread]) {
		[self stopForwardingMultitouchEventsToListeners];
		[self startForwardingMultitouchEventsToListeners];
	}
	else {
		[self performSelectorOnMainThread:@selector(restartMultitouchEventForwardingAfterWake:) withObject:wakeNotification waitUntilDone:NO];
	}
}

- (id)init {
	self = [super init];
    
	multitouchListeners = [NSMutableArray array];
	multitouchDevices = [NSMutableArray array];
    
	[[[NSWorkspace sharedWorkspace] notificationCenter] addObserver:self selector:@selector(restartMultitouchEventForwardingAfterWake:) name:NSWorkspaceDidWakeNotification object:nil];
    
	return self;
}

+ (BOOL)systemIsMultitouchCapable {
	return (((NSArray *)CFBridgingRelease(MTDeviceCreateList())).count > 0);
}

static MultitouchManager *sharedMultitouchManager = nil;

+ (void)initialize {
	if (!sharedMultitouchManager && self == [MultitouchManager class]) {
		sharedMultitouchManager = [[self alloc] init];
	}
}

+ (MultitouchManager *)sharedMultitouchManager {
	return sharedMultitouchManager;
}

@end