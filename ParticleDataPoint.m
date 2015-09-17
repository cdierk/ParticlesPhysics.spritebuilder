//
//  ParticleDataPoint.m
//  ParticlesPhysics
//
//  Created by Christine Dierk on 9/15/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "ParticleDataPoint.h"

@implementation ParticleDataPoint

@synthesize date = _date;
@synthesize numLargeParticles = _numLargeParticles;
@synthesize numSmallParticles = _numSmallParticles;
@synthesize longitude = _longitude;
@synthesize latitude = _latitude;


- (id) initWithDate:(NSDate *)date numLargeParticles:(int)numLargeParticles numSmallParticles:(int)numSmallParticles latitude:(float)latitude longitude:(float)longitude{
    if ((self = [super init])){
        self.date = date;
        self.numLargeParticles = numLargeParticles;
        self.numSmallParticles = numSmallParticles;
        self.latitude = latitude;
        self.longitude = longitude;
    }
    return self;
}

#pragma mark NSCoding

#define kDateKey                   @"Date"
#define kNumLargeParticlesKey      @"numLargeParticles"
#define kNumSmallParticlesKey      @"numSmallParticles"
#define kLongitude                 @"Longitude"
#define kLatitude                  @"Latitude"

- (void) encodeWithCoder:(NSCoder *)encoder {
    [encoder encodeObject:_date forKey:kDateKey];
    [encoder encodeObject:[NSNumber numberWithInt:_numLargeParticles] forKey:kNumLargeParticlesKey];
    [encoder encodeObject:[NSNumber numberWithInt:_numSmallParticles] forKey:kNumSmallParticlesKey];
    [encoder encodeFloat:_longitude forKey:kLongitude];
    [encoder encodeFloat:_latitude forKey:kLatitude];
}

- (id)initWithCoder:(NSCoder *)decoder {
    NSDate *date = [decoder decodeObjectForKey:kDateKey];
    int numLargeParticles = [[decoder decodeObjectForKey:kNumLargeParticlesKey] intValue];
    int numSmallParticles = [[decoder decodeObjectForKey:kNumSmallParticlesKey] intValue];
    float latitude = [decoder decodeFloatForKey:kLatitude];
    float longitude = [decoder decodeFloatForKey:kLongitude];
    return [self initWithDate:date numLargeParticles:numLargeParticles numSmallParticles:numSmallParticles latitude:latitude longitude:longitude];
}

@end
