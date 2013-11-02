#import <Foundation/Foundation.h>
#import "MultitouchSupport.h"
@class MultitouchEvent;

static int MultitouchTouchStateActive = 4;

@interface MultitouchTouch : NSObject {
	MultitouchEvent *event;
	NSNumber *identifier;
	int state;
	float x, y, minorAxis, majorAxis, angle, size, velX, velY;
}
@property MultitouchEvent *event;
@property NSNumber *identifier;
@property int state;
@property float x;
@property float y;
@property float minorAxis;
@property float majorAxis;
@property float angle;
@property float size;
@property float velX;
@property float velY;

- (id)initWithMTTouch:(MTTouch *)touch andMultitouchEvent:(MultitouchEvent *)_event;

@end