#import "TaprRecognitionModel.h"

@implementation TaprRecognitionModel

- (id)init {
	self = [super init];
    
	userDefaults = [NSUserDefaults standardUserDefaults];
    
	return self;
}

@end
