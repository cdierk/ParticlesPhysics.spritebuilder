//
//  ParticleDatabase.h
//  ParticlesPhysics
//
//  Created by Christine Dierk on 9/15/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ParticleDatabase : NSObject

+ (NSMutableArray *)loadParticleDataPointDocs;
+ (NSString *)nextParticleDataPointDocPath;

@end
