//
//  BEDevice.h
//
//  Copyright (c) 2015 Bracing Effect, LLC. See LICENSE for details.
//

#import <CoreMotion/CoreMotion.h>


@interface BEDevice : NSObject

+ (CMMotionManager *)motionManager;

@end
