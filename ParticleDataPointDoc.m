//
//  ParticleDataPointDoc.m
//  ParticlesPhysics
//
//  Created by Christine Dierk on 9/15/15.
//  Copyright (c) 2015 Apportable. All rights reserved.
//

#import "ParticleDataPointDoc.h"
#import "ParticleDatabase.h"
#import "ParticleDataPoint.h"

#define kDataKey        @"Data"
#define kDataFile       @"data.plist"

@implementation ParticleDataPointDoc

@synthesize data = _data;
@synthesize docPath = _docPath;

- (id)init {
    if ((self = [super init])) {
    }
    return self;
}

- (id)initWithDocPath:(NSString *)docPath {
    if ((self = [super init])) {
        _docPath = [docPath copy];
    }
    return self;
}

- (BOOL)createDataPath {
    
    if (_docPath == nil) {
        self.docPath = [ParticleDatabase nextParticleDataPointDocPath];
    }
    
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:_docPath withIntermediateDirectories:YES attributes:nil error:&error];
    if (!success) {
        NSLog(@"Error creating data path: %@", [error localizedDescription]);
    }
    return success;
    
}

- (ParticleDataPoint *)data {
    
    if (_data != nil) return _data;
    
    NSString *dataPath = [_docPath stringByAppendingPathComponent:kDataFile];
    NSData *codedData = [[NSData alloc] initWithContentsOfFile:dataPath];
    if (codedData == nil){
        return nil;
    }
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:codedData];
    _data = [unarchiver decodeObjectForKey:kDataKey];
    [unarchiver finishDecoding];
    
    return _data;
    
}

- (void)saveData {
    
    if (_data == nil) return;
    
    [self createDataPath];
    
    NSString *dataPath = [_docPath stringByAppendingPathComponent:kDataFile];
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:_data forKey:kDataKey];
    [archiver finishEncoding];
    [data writeToFile:dataPath atomically:YES];
    
}

- (void)deleteDoc {
    
    NSError *error;
    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:_docPath error:&error];
    if (!success) {
        NSLog(@"Error removing document path: %@", error.localizedDescription);
    }
    
}

- (id) initWithDate:(NSDate *)date numLargeParticles:(int)numLargeParticles numSmallParticles:(int)numSmallParticles latitude:(float)latitude longitude:(float)longitude{
    if ((self = [super init])){
        self.data = [[ParticleDataPoint alloc] initWithDate:date numLargeParticles:numLargeParticles numSmallParticles:numSmallParticles latitude:latitude longitude:longitude];
    }
    return self;
}

@end
