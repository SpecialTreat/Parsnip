#import "PreenDevice.h"


@implementation PreenDevice

static CMMotionManager *_motionManager;

+ (void)initialize
{
    _motionManager = [[CMMotionManager alloc] init];
    _motionManager.deviceMotionUpdateInterval = 1.0f / 15.0f;
}

+ (CMMotionManager *)motionManager
{
    return _motionManager;
}

@end
