#import "MainScene.h"
#include <stdlib.h>
#import "CCPhysics+ObjectiveChipmunk.h"
#import "ScanViewController.h"
#import "ParticleDataPoint.h"
#import "ParticleDataPointDoc.h"
#import "ParticleDatabase.h"
#import <CoreLocation/CoreLocation.h>

@implementation MainScene{
    //CCPhysicsNode *_physicsNode;
    CCNode *_bottomBorder;
    CCEffectBrightness *_brightnessEffect;
    CCEffectStack *_effectStack;
    CCLabelTTF *_largeLabel;
    CCLabelTTF *_smallLabel;
    BEMSimpleLineGraphView *_largeGraph;
    BEMSimpleLineGraphView *_smallGraph;
    BEMSimpleLineGraphView *_totalGraph;
    CLLocationManager *locationManager;
}

@synthesize _physicsNode;
@synthesize datapoints = _datapoints;

#define ARC4RANDOM_MAX 0x100000000
#define LARGE_PARTICLE_SCALE 0.5
#define SMALL_PARTICLE_SCALE 0.2
#define PARTICLE_DELAY 3.0
#define FREEZE_DELAY 6.0
#define EXPLOSION_LENGTH 3.0
#define DAMPING 0.2f
#define PARTICLE_BASE_SIZE 24.0
#define PARTICLE_CHECKING_DELAY 2.0

BOOL isStacked = false;
BOOL chartsShowing = false;
BOOL inUpdate = false;
int currentLargeParticles;
int currentSmallParticles;

// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    
    currentLargeParticles = 0;
    currentSmallParticles = 0;
    
    _datapoints = [ParticleDatabase loadParticleDataPointDocs];
    
    //to update screen with auto-running particles from most current reading
    if (_datapoints){
        NSLog(@"There's data!");
        ParticleDataPointDoc *most_current_reading = [_datapoints lastObject];
        int oldLargeParticles = most_current_reading.data.numLargeParticles;
        int oldSmallParticles = most_current_reading.data.numSmallParticles;
        [self initial_update_withLarge:oldLargeParticles andSmall:oldSmallParticles];
    }
    
    //[rfduino setDelegate:self];
    
    _physicsNode.gravity = ccp(0,0);            //set gravity to 0 initially
    
    // listen for swipes down
    UISwipeGestureRecognizer * swipeDown= [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeDown];
    
    // COMMENT ME OUT
    // listen for swipes left -- only for testing purposes
    UISwipeGestureRecognizer * swipeLeft= [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeLeft];
    
    //COMMENT ME OUT
    // listen for swipes right -- only for testing purposes
    UISwipeGestureRecognizer * swipeRight= [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeRight];
    
    //listen for swipes up
    UISwipeGestureRecognizer * swipeUp= [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeUp)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeUp];
    
    _brightnessEffect = [CCEffectBrightness effectWithBrightness:sin(0)];
    _effectStack = [[CCEffectStack alloc] initWithEffects:_brightnessEffect, nil];
    
    _largeGraph = [[BEMSimpleLineGraphView alloc] initWithFrame:CGRectMake(0, 0, 320, 200)];
    _largeGraph.delegate = self;
    _largeGraph.dataSource = self;
    _largeGraph.alpha = 1.0f;
    _largeGraph.colorTop = [UIColor colorWithHue:183.0/360.0 saturation:1.0 brightness:0.66 alpha:1.0f];
    _largeGraph.colorBottom = [UIColor colorWithHue:183.0/360.0 saturation:1.0 brightness:0.66 alpha:1.0f];
    [[[CCDirector sharedDirector] view] addSubview:_largeGraph];
    _largeGraph.hidden = true;
    
    _smallGraph = [[BEMSimpleLineGraphView alloc] initWithFrame:CGRectMake(0, 200, 320, 200)];
    _smallGraph.delegate = self;
    _smallGraph.dataSource = self;
    _smallGraph.alpha = 0.99f;
    _smallGraph.colorTop = [UIColor colorWithHue:300.0/360.0 saturation:1.0 brightness:0.76 alpha:0.99f];
    _smallGraph.colorBottom = [UIColor colorWithHue:300.0/360.0 saturation:1.0 brightness:0.76 alpha:0.99f];
    [[[CCDirector sharedDirector] view] addSubview:_smallGraph];
    _smallGraph.hidden = true;
    
    _totalGraph = [[BEMSimpleLineGraphView alloc] initWithFrame:CGRectMake(0, 400, 320, 200)];
    _totalGraph.delegate = self;
    _totalGraph.dataSource = self;
    _totalGraph.alpha = 0.98f;
    _totalGraph.colorTop = [UIColor colorWithHue:195.0/360.0 saturation:0.0 brightness:0.69 alpha:0.98f];
    _totalGraph.colorBottom = [UIColor colorWithHue:195.0/360.0 saturation:0.0 brightness:0.69 alpha:0.98f];
    [[[CCDirector sharedDirector] view] addSubview:_totalGraph];
    _totalGraph.hidden = true;
    
    inputLarge = 0;
    inputSmall = 0;
    
    locationManager = [[CLLocationManager alloc] init];
    locationManager.distanceFilter = kCLDistanceFilterNone;
    locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters;
    [locationManager startUpdatingLocation];
    
    [locationManager requestAlwaysAuthorization]; //Note this one
    
    //UNCOMMENT ME
    //[self checkDevice];
    
    //[self generateCSVfile];
}

-(NSString *)dataFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:@"myPartData.csv"];
}

- (void) generateCSVfile {
    
    /*if (![[NSFileManager defaultManager] fileExistsAtPath:[self dataFilePath]]) {
        [[NSFileManager defaultManager] createFileAtPath: [self dataFilePath] contents:nil attributes:nil];
        NSLog(@"Route creato");
    }*/
    
    NSMutableString *writeString = [NSMutableString stringWithCapacity:0];
    
    //NSMutableString *csv = [NSMutableString stringWithString:@"Date,numLarge,numSmall, lat, lon"];
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateStyle:NSDateFormatterShortStyle];
    [dateFormatter setTimeStyle:NSDateFormatterShortStyle];
    
    for (ParticleDataPointDoc *datapoint in _datapoints){
        NSDate *date = datapoint.data.date;
        
        [writeString appendString:[NSString stringWithFormat:@"%@, %d, %d, %f, %f, \n",
                                                 [dateFormatter stringFromDate:date],
                                                 datapoint.data.numLargeParticles,
                                                 datapoint.data.numSmallParticles,
                                                 datapoint.data.latitude,
                                                 datapoint.data.longitude]];
    }
    
    NSLog(@"writeString :%@",writeString);
    
    /*NSString *yourFileName = @"myPartData";
    NSError *error;
    BOOL res = [csv writeToFile:yourFileName atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (!res) {
        NSLog(@"Error %@ while writing to file %@", [error localizedDescription], yourFileName );
    }*/
    
   /* NSFileHandle *handle;
    handle = [NSFileHandle fileHandleForWritingAtPath: [self dataFilePath] ];
    //say to handle where's the file fo write
    [handle truncateFileAtOffset:[handle seekToEndOfFile]];
    //position handle cursor to the end of file
    [handle writeData:[writeString dataUsingEncoding:NSUTF8StringEncoding]];*/
}

//needed so that we don't restore initial values--a lot smaller than other update method because we don't need delays and there are initially no particles, so none need to be deleted
- (void) initial_update_withLarge: (int) numLargeParticles andSmall: (int) numSmallParticles {
    NSLog(@"updateLargeParticles: %d, updateSmallParticles: %d", numLargeParticles, numSmallParticles);
    
    while (numLargeParticles > currentLargeParticles) {                 //need to add more
        [self launchLargeParticle];
        currentLargeParticles++;
    }
    
    while (numSmallParticles > currentSmallParticles){                  //need to add more
        [self launchSmallParticle];
        currentSmallParticles++;
    }
    
    [self onShake];
}

// swipe Up recognizer -- displays charts
- (void) swipeUp {
    
    for (CCNode *particle in _physicsNode.children) {
        if ([particle.name isEqual:(@"largeParticle")]){
            UIColor *teal = [UIColor colorWithHue:183.0/360.0 saturation:1.0 brightness:0.66 alpha:0.0f];
            particle.colorRGBA = [CCColor colorWithUIColor:teal];
        } else if ([particle.name isEqual:(@"smallParticle")]){
            UIColor *pink = [UIColor colorWithHue:300.0/360.0 saturation:1.0 brightness:0.76 alpha:0.0f];
            particle.colorRGBA = [CCColor colorWithUIColor:pink];
        }
    }
    
    _largeGraph.hidden = false;
    _smallGraph.hidden = false;
    _totalGraph.hidden = false;
    chartsShowing = true;
    [_largeGraph reloadGraph];
    [_smallGraph reloadGraph];
    [_totalGraph reloadGraph];
}

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph {
    return [_datapoints count]; // Number of points in the graph.
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index {
    
    ParticleDataPointDoc *datapointdoc = [_datapoints objectAtIndex:index];
    
    if (graph.alpha == 1.0f){
        return datapointdoc.data.numLargeParticles; // The value of the point on the Y-Axis for the index.       only large particles
    }
    if (graph.alpha == 0.99f){
        return datapointdoc.data.numSmallParticles; // The value of the point on the Y-Axis for the index.       only small particles
    }
    if (graph.alpha == 0.98f){
        int total_particles = datapointdoc.data.numLargeParticles + datapointdoc.data.numSmallParticles;
        return total_particles;             //all particles
    }
    
    return 0;
}

- (void) checkDevice {
    
    if ((inputLarge != currentLargeParticles) || (inputSmall != currentSmallParticles)){
        [self updateLargeParticles:inputLarge andSmallParticles:inputSmall];
    }
    
    //recursive so always checking
    [self performSelector:@selector(checkDevice) withObject:nil afterDelay:PARTICLE_CHECKING_DELAY];
}

// called on every touch in this scene
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    

}

// swipe right recognizer -- adds a random number of particles to the scene
- (void) swipeRight {
    if (inUpdate) { return;}
    
    int numLargeParticles = (int)[self randomFloatBetween:currentLargeParticles andLargerFloat:currentLargeParticles + 50];            //number larger than current
    int numSmallParticles = (int)[self randomFloatBetween:currentSmallParticles andLargerFloat:currentSmallParticles + 100];            //number larger than current
   
    [self updateLargeParticles:numLargeParticles andSmallParticles:numSmallParticles];
}

- (void) kickStart {
    if (isStacked) { return;}       //to prevent crash when stacked immediately after new particles but before kickstart
    [self onShake];
}

- (void) updateLargeParticles:(int)numLargeParticles andSmallParticles:(int)numSmallParticles{
    NSLog(@"updateLargeParticles: %d, updateSmallParticles: %d", numLargeParticles, numSmallParticles);
    
    [_physicsNode.space setDamping:DAMPING];
    
    inUpdate = true;
    
    //so that we don't fade in new particles
    CCNode *currentChildren = [_physicsNode.children copy];
    
    //remove damping after freeze delay and apply random force to all particles to get moving, also adds color back
    [self performSelector:@selector(removeDamping) withObject:nil afterDelay:FREEZE_DELAY];
    
    if (!isStacked) [self performSelector:@selector(kickStart) withObject:nil afterDelay:FREEZE_DELAY];   //only kick start new particles if not stacked
    [self performSelector:@selector(fadeInParticles:) withObject:currentChildren afterDelay:FREEZE_DELAY];
    
    //NSLog(@"currents: %d, %d", currentLargeParticles, currentSmallParticles);
    
    [self fadeOutParticles];
    
    while (numLargeParticles > currentLargeParticles) {                 //need to add more
        [self performSelector:@selector(launchLargeParticle) withObject:nil afterDelay:PARTICLE_DELAY];
        currentLargeParticles++;
    }
    
    while (numSmallParticles > currentSmallParticles){                  //need to add more
        [self performSelector:@selector(launchSmallParticle) withObject:nil afterDelay:PARTICLE_DELAY];
        currentSmallParticles++;
    }
    
    while (numLargeParticles < currentLargeParticles){                 //remove particles
        [self performSelector:@selector(removeLargeParticle) withObject:nil afterDelay:PARTICLE_DELAY];
        currentLargeParticles--;
    }
    
    while (numSmallParticles < currentSmallParticles){
        [self performSelector:@selector(removeSmallParticle) withObject:nil afterDelay:PARTICLE_DELAY];
        currentSmallParticles--;
    }
    
    if (isStacked) [self stackParticles];
    if (isStacked) [self performSelector:@selector(stackParticles) withObject:nil afterDelay:PARTICLE_DELAY]; //restack new particles if stacked
    
    //add datapoints to array
    NSDate *now = [NSDate date];
    
    float latitude = locationManager.location.coordinate.latitude;
    float longitude = locationManager.location.coordinate.longitude;
    
    ParticleDataPointDoc *datapointdoc = [[ParticleDataPointDoc alloc] initWithDate:now numLargeParticles:currentLargeParticles numSmallParticles:currentSmallParticles latitude:latitude longitude:longitude];
    [datapointdoc saveData];
    [_datapoints addObject:datapointdoc];
    
    NSString *largeString = [NSString stringWithFormat:@"%d", numLargeParticles];
    NSString *smallString = [NSString stringWithFormat:@"%d", numSmallParticles];
    NSString *latString = [NSString stringWithFormat:@"%f", latitude];
    NSString *longString = [NSString stringWithFormat:@"%f", longitude];
    
    NSArray *data = [[NSArray alloc] initWithObjects: largeString, smallString, latString, longString, nil];
    
    //UNCOMMENT ME
    //[self performSelector:@selector(textMeLarge:) withObject:data afterDelay:PARTICLE_DELAY];
}

- (void) removeLargeParticle {
    CCNode *oneLargeParticle = [_physicsNode getChildByName:@"largeParticle" recursively:false];
    [_physicsNode removeChild:oneLargeParticle];
    inUpdate = false;
}

- (void) removeSmallParticle {
    CCNode *oneSmallParticle = [_physicsNode getChildByName:@"smallParticle" recursively:false];
    [_physicsNode removeChild:oneSmallParticle];
    inUpdate = false;
}

- (void) fadeOutParticles {
    for (CCNode *particle in _physicsNode.children) {
        [self reduceSaturation:1.0 withParticle:particle];
    }
}

- (void) fadeInParticles: (NSArray *) children{
    for (CCNode *particle in children) {
        if ([particle.name isEqual:(@"largeParticle")] || [particle.name isEqual:(@"smallParticle")]){
            [self increaseSaturation:0.05 withParticle:particle];
        }
    }
}

-(void) reduceSaturation: (float)currentSaturation withParticle:(CCNode *)particle {
    float newSaturation = currentSaturation - 0.05;
    
    if ([particle.name  isEqual: (@"largeParticle")]){
        UIColor *teal = [UIColor colorWithHue:183.0/360.0 saturation:newSaturation brightness:0.66 alpha:1.0f];
        particle.colorRGBA = [CCColor colorWithUIColor:teal];
    } else if ([particle.name  isEqual: @"smallParticle"]){
        UIColor *pink = [UIColor colorWithHue:300.0/360.0 saturation:newSaturation brightness:0.76 alpha:1.0f];
        particle.colorRGBA = [CCColor colorWithUIColor:pink];
    }
    
    //recurse
    if (newSaturation > 0.05){
        double delayInSeconds = 0.05;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self reduceSaturation:newSaturation withParticle:particle];
        });
    }
}

-(void) increaseSaturation: (float)currentSaturation withParticle:(CCNode *)particle {
    float newSaturation = currentSaturation + 0.05;
    if ([particle.name  isEqual: (@"largeParticle")]){
        UIColor *teal = [UIColor colorWithHue:183.0/360.0 saturation:newSaturation brightness:0.66 alpha:1.0f];
        particle.colorRGBA = [CCColor colorWithUIColor:teal];;
    } else if ([particle.name  isEqual: @"smallParticle"]){
        UIColor *pink = [UIColor colorWithHue:300.0/360.0 saturation:newSaturation brightness:0.76 alpha:1.0f];
        particle.colorRGBA = [CCColor colorWithUIColor:pink];;
    }
    
    //recurse
    if (newSaturation < 1.0){
        double delayInSeconds = 0.05;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self increaseSaturation:newSaturation withParticle:particle];
        });
    }
}

- (void) launchSmallParticle {
    // loads the particle.cbb files we have set up in Spritebuilder
    CCNode* smallParticle = [CCBReader load:@"smallParticle"];
    smallParticle.scale = SMALL_PARTICLE_SCALE;
    
    UIView *current_view = [[CCDirector sharedDirector] view];
    
    // random location for small particle
    int xmin_small = (smallParticle.boundingBox.size.width)/2;
    int ymin_small = (smallParticle.boundingBox.size.height)/2;
    int x_small = xmin_small + (arc4random() % (int)(current_view.frame.size.width - smallParticle.boundingBox.size.width));
    int y_small = ymin_small + (arc4random() % (int)(current_view.frame.size.height - smallParticle.boundingBox.size.height));
    
    // position the particles at previously specified random locations
    smallParticle.position = ccp(x_small, y_small);
    
    //set name so that we can distinguish between large/small and remove it later
    smallParticle.name = @"smallParticle";
    
    //set color
    UIColor *pink = [UIColor colorWithHue: 300.0/360.0 saturation:1.0 brightness:0.76 alpha:1];
    CCColor *ccpink = [CCColor colorWithUIColor:pink];
    smallParticle.colorRGBA = ccpink;
    
    // add the particles to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:smallParticle];
    inUpdate = false;
}

- (void)launchLargeParticle {
    //NSLog(@"large launched");
    
    // loads the particle.cbb files we have set up in Spritebuilder
    CCNode* largeParticle = [CCBReader load:@"largeParticle"];
    largeParticle.scale = LARGE_PARTICLE_SCALE;
    
    //NSLog(@"Large particle: %@", largeParticle);

    UIView *current_view = [[CCDirector sharedDirector] view];
    
    //NSLog(@"Current view: %@", current_view);
    
    // random location for large particle
    int xmin_large = (largeParticle.boundingBox.size.width)/2;
    int ymin_large = (largeParticle.boundingBox.size.height)/2;
    int x_large = xmin_large + (arc4random() % (int)(current_view.frame.size.width - largeParticle.boundingBox.size.width));
    int y_large = ymin_large + (arc4random() % (int)(current_view.frame.size.height - largeParticle.boundingBox.size.height));
    
    // position the particles at previously specified random locations
    largeParticle.position = ccp(x_large, y_large);
    
    //set name so that we can distinguish between large/small and remove it later
    largeParticle.name = @"largeParticle";
    
    //set color
    UIColor *teal = [UIColor colorWithHue: 183.0/360.0 saturation:1.0 brightness:0.66 alpha:1];
    CCColor *ccteal = [CCColor colorWithUIColor:teal];
    largeParticle.colorRGBA = ccteal;
    
    // add the particles to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:largeParticle];
    
    //NSLog(@"Physics node: %@", _physicsNode);
    inUpdate = false;
}

// if device is shaken, apply a random force to all particles
- (void)onShake {
    
    [self removeDamping];

    for (CCNode *particle in _physicsNode.children) {
        particle.physicsBody.elasticity = 1.0;          //readd elasticity of each particle
        
        if ([particle.name isEqual:(@"smallParticle")]){        //decrease size of small particle
            particle.scale = SMALL_PARTICLE_SCALE;
        }
        
        // manually create & apply a force to launch the particle
        CGPoint launchDirection = ccp([self randomFloatBetween:-1.0 andLargerFloat:1.0], [self randomFloatBetween:-1.0 andLargerFloat:1.0]);
        CGPoint force = ccpMult(launchDirection, 10000);
        [particle.physicsBody applyForce:force];
    }
    
    _physicsNode.gravity = ccp(0,0);                //remove gravity
    _bottomBorder.physicsBody.elasticity = 1.0;         //add elasticity of bottom border
    
    isStacked = false;
    
    if ([_physicsNode.children containsObject:_largeLabel]){
        [_physicsNode removeChild:_largeLabel];
        [_physicsNode removeChild:_smallLabel];
    }
}

- (float)randomFloatBetween:(float)num1 andLargerFloat:(float)num2 {
    return ((float)arc4random() / ARC4RANDOM_MAX) * (num2-num1) + num1;
}

- (void) stackParticles {
    if (inUpdate) return;       //to avoid bug of trying to stack particles that have been recently deleted
    
    if ([_physicsNode getChildByName:@"largeLabel" recursively:false] != NULL) [_physicsNode removeChild:_largeLabel];
    if ([_physicsNode getChildByName:@"smallLabel" recursively:false] != NULL)[_physicsNode removeChild:_smallLabel];
    
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    CGFloat screenWidth = screenRect.size.width;
    //CGFloat screenHeight = screenRect.size.height;
    CGFloat division = screenWidth/2;
    
    CGFloat currentLargePositionX = PARTICLE_BASE_SIZE / 2;
    CGFloat currentLargePositionY = PARTICLE_BASE_SIZE / 2;
    
    CGFloat currentSmallPositionX = division + PARTICLE_BASE_SIZE / 2;
    CGFloat currentSmallPositionY = PARTICLE_BASE_SIZE/ 2;
    
    for (CCNode *particle in _physicsNode.children) {
        if ([particle.name isEqual:(@"smallParticle")]){
            CGPoint currentLocation = ccp(currentSmallPositionX, currentSmallPositionY);
            particle.position = currentLocation;
            
            currentSmallPositionX = currentSmallPositionX + PARTICLE_BASE_SIZE;
            if (currentSmallPositionX > screenWidth - (PARTICLE_BASE_SIZE / 2)){        //extends off side of screen
                currentSmallPositionX = division + PARTICLE_BASE_SIZE / 2;
                currentSmallPositionY = currentSmallPositionY + PARTICLE_BASE_SIZE; //move up a row
            }
        }
        if ([particle.name isEqual:(@"largeParticle")]){
            CGPoint currentLocation = ccp(currentLargePositionX, currentLargePositionY);
            particle.position = currentLocation;
            
            currentLargePositionX = currentLargePositionX + PARTICLE_BASE_SIZE;
            if (currentLargePositionX > division - (PARTICLE_BASE_SIZE / 2)){        //extends off side of screen
                currentLargePositionX = PARTICLE_BASE_SIZE / 2;
                currentLargePositionY = currentLargePositionY + PARTICLE_BASE_SIZE; //move up a row
            }
        }
    }
    
    _largeLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", currentLargeParticles] fontName:@"Arial" fontSize:16.0f];
    _largeLabel.position = ccp(division/2, currentLargePositionY + PARTICLE_BASE_SIZE);
    _largeLabel.physicsBody = [CCPhysicsBody bodyWithRect:(CGRect){CGPointZero, _largeLabel.contentSize} cornerRadius:0];
    _largeLabel.color = [CCColor colorWithUIColor:[UIColor colorWithHue:183.0/360.0 saturation:1.0f brightness:0.66 alpha:1.0f]];
    _largeLabel.name = @"largeLabel";
    
    _smallLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", currentSmallParticles] fontName:@"Arial" fontSize:16.0f];
    _smallLabel.position = ccp(division/2 + division, currentSmallPositionY + PARTICLE_BASE_SIZE);
    _smallLabel.physicsBody = [CCPhysicsBody bodyWithRect:(CGRect){CGPointZero, _smallLabel.contentSize} cornerRadius:0];
    _smallLabel.color = [CCColor colorWithUIColor:[UIColor colorWithHue:300.0/360.0 saturation:1.0f brightness:0.76 alpha:1.0f]];
    _smallLabel.name = @"smallLabel";
    
    [_physicsNode addChild:_largeLabel];
    [_physicsNode addChild:_smallLabel];
    
    isStacked = true;
}

- (void)swipeDown {
    
    if (chartsShowing){
        for (CCNode *particle in _physicsNode.children) {
            if ([particle.name isEqual:(@"largeParticle")]){
                UIColor *teal = [UIColor colorWithHue:183.0/360.0 saturation:1.0 brightness:0.66 alpha:1.0f];
                particle.colorRGBA = [CCColor colorWithUIColor:teal];
            } else if ([particle.name isEqual:(@"smallParticle")]){
                UIColor *pink = [UIColor colorWithHue:300.0/360.0 saturation:1.0 brightness:0.76 alpha:1.0f];
                particle.colorRGBA = [CCColor colorWithUIColor:pink];
            }
        }
        
        _largeGraph.hidden = true;
        _smallGraph.hidden = true;
        _totalGraph.hidden = true;
        chartsShowing = false;
        return;
    }
    
    if (inUpdate){ return; }                           //prevents crash when attempted stack during update

    
    if (isStacked){ return; }                    //prevents crash when attemped stack while stacked
    
    [_physicsNode.space setDamping:0.0f];        //reduce movement
    
    [self performSelector:@selector(stackParticles) withObject:nil afterDelay:0.1];
}

- (void) removeDamping {
    [_physicsNode.space setDamping:1.0f];
}

-(void) removeParticle: (CCNode *) particle {
    [_physicsNode removeChild:particle];
}

//removes a random number of particles from the scene
//right now removes them right away--after a delay would be better
-(void) swipeLeft {
    
    if (inUpdate){ return;}                 //only one update allowed at a time
    
    int numLargeParticles = (int)[self randomFloatBetween:MAX(0,currentLargeParticles - 50) andLargerFloat:currentLargeParticles];
    int numSmallParticles = (int)[self randomFloatBetween:MAX(0, currentSmallParticles - 100) andLargerFloat:currentSmallParticles];
    
    [self updateLargeParticles:numLargeParticles andSmallParticles:numSmallParticles];
}

//for text messaging
- (void)textMeLarge: (NSArray*) info {
    NSLog(@"Sending request.");
    
    int large = [[info objectAtIndex:0] intValue];
    int small = [[info objectAtIndex:1] intValue];
    float lat = [[info objectAtIndex:2] floatValue];
    float lon = [[info objectAtIndex:3] floatValue];
    
    // Common constants
    NSString *kTwilioSID = @"AC3d3fbeb7b9936974870fa9e449c7b66a";
    NSString *kTwilioSecret = @"1f2ec3e1a3fa41997fe49117c22e44b0";
    NSString *kFromNumber = @"+19192952547";
    NSString *kToNumber = @"+15303888667";
    NSString *kMessage = [NSString stringWithFormat:@"large: %d, small: %d, lat: %f, long: %f, \n", large, small, lat, lon];
    
    // Build request
    NSString *urlString = [NSString stringWithFormat:@"https://%@:%@@api.twilio.com/2010-04-01/Accounts/%@/SMS/Messages", kTwilioSID, kTwilioSecret, kTwilioSID];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:url];
    [request setHTTPMethod:@"POST"];
    
    // Set up the body
    NSString *bodyString = [NSString stringWithFormat:@"From=%@&To=%@&Body=%@", kFromNumber, kToNumber, kMessage];
    NSData *data = [bodyString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    NSError *error;
    NSURLResponse *response;
    NSData *receivedData = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&error];
    
    // Handle the received data
    if (error) {
        NSLog(@"Error: %@", error);
    } else {
        NSString *receivedString = [[NSString alloc]initWithData:receivedData encoding:NSUTF8StringEncoding];
        NSLog(@"Request sent. %@", receivedString);
    }
}

@end
