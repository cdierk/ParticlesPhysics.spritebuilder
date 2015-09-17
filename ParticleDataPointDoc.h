//
//  ParticleDataPointDoc.h
//  ParticlesPhysics
//
//  Created by Christine Dierk on 9/15/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ParticleDataPoint.h"

@interface ParticleDataPointDoc : NSObject {
    NSString *_docPath;
}

@property (strong, nonatomic) ParticleDataPoint *data;
@property (copy) NSString *docPath;

- (id)init;
- (id)initWithDocPath:(NSString *)docPath;
- (void)saveData;
- (void)deleteDoc;
- (id)initWithDate:(NSDate*)date numLargeParticles:(int)numLargeParticles numSmallParticles:(int)numSmallParticles latitude:(float)latitude longitude:(float)longitude;

@end
