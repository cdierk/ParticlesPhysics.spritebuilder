//
//  ParticleDataPoint.h
//  ParticlesPhysics
//
//  Created by Christine Dierk on 9/15/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParticleDataPoint : NSObject <NSCoding> 

@property (strong) NSDate *date;
@property (assign) int numLargeParticles;
@property (assign) int numSmallParticles;
@property (assign) float latitude;
@property (assign) float longitude;

- (id)initWithDate:(NSDate*)date numLargeParticles:(int)numLargeParticles numSmallParticles:(int)numSmallParticles latitude:(float)latitude longitude:(float)longitude;

@end
