#import "MainScene.h"
#include <stdlib.h>
#import "CCPhysics+ObjectiveChipmunk.h"
#import "ScanViewController.h"

@implementation MainScene{
    //CCPhysicsNode *_physicsNode;
    CCNode *_bottomBorder;
    CCEffectBrightness *_brightnessEffect;
    CCEffectStack *_effectStack;
    CCLabelTTF *_largeLabel;
    CCLabelTTF *_smallLabel;
    NSMutableArray *_datapoints;
    BEMSimpleLineGraphView *_largeGraph;
    BEMSimpleLineGraphView *_smallGraph;
    BEMSimpleLineGraphView *_totalGraph;
}

@synthesize rfduino;
@synthesize _physicsNode;

#define ARC4RANDOM_MAX 0x100000000
#define LARGE_PARTICLE_SCALE 0.5
#define SMALL_PARTICLE_SCALE 0.2
#define PARTICLE_DELAY 3.0
#define FREEZE_DELAY 6.0
#define EXPLOSION_LENGTH 3.0
#define DAMPING 0.2f
#define PARTICLE_BASE_SIZE 24.0
#define PARTICLE_CHECKING_DELAY 10.0

BOOL isStacked = false;
BOOL chartsShowing = false;
int currentLargeParticles;
int currentSmallParticles;

// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    
    _datapoints = [NSMutableArray array];
    
    //[rfduino setDelegate:self];
    
    _physicsNode.gravity = ccp(0,0);            //set gravity to 0 initially
    
    // listen for swipes down
    UISwipeGestureRecognizer * swipeDown= [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeDown)];
    swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeDown];
    
    // listen for swipes left -- only for testing purposes
    UISwipeGestureRecognizer * swipeLeft= [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeLeft)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeLeft];
    
    // listen for swipes right -- only for testing purposes
    UISwipeGestureRecognizer * swipeRight= [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeRight];
    
    /*/set up listener for orientation changes
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter]
     addObserver:self selector:@selector(orientationChanged:)
     name:UIDeviceOrientationDidChangeNotification
     object:[UIDevice currentDevice]];*/
    
    //listen for swipes up
    UISwipeGestureRecognizer * swipeUp= [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeUp)];
    swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
    [[[CCDirector sharedDirector] view] addGestureRecognizer:swipeUp];
    
    _brightnessEffect = [CCEffectBrightness effectWithBrightness:sin(0)];
    _effectStack = [[CCEffectStack alloc] initWithEffects:_brightnessEffect, nil];
    
    currentLargeParticles = 0;
    currentSmallParticles = 0;
    
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
    
    [self checkDevice];
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

//handler for orientation changes
- (void) orientationChanged:(NSNotification *)note
{
    UIDevice * device = note.object;
    switch(device.orientation)
    {
        case UIDeviceOrientationPortrait:
            NSLog(@"portrait activated");
            
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
            
            break;
            
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"Landscape activated");
            
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
            [_largeGraph reloadGraph];
            
            _smallGraph.hidden = false;
            [_smallGraph reloadGraph];
            
            _totalGraph.hidden = false;
            [_totalGraph reloadGraph];
            
            break;
            
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"Landscape activated");
            
            for (CCNode *particle in _physicsNode.children) {
                if ([particle.name isEqual:(@"largeParticle")]){
                    UIColor *teal = [UIColor colorWithHue:183.0/360.0 saturation:1.0 brightness:0.66 alpha:0.0f];
                    particle.colorRGBA = [CCColor colorWithUIColor:teal];
                } else if ([particle.name isEqual:(@"smallParticle")]){
                    UIColor *pink = [UIColor colorWithHue:300.0/360.0 saturation:1.0 brightness:0.76 alpha:0.0f];
                    particle.colorRGBA = [CCColor colorWithUIColor:pink];
                }
            }
            
            break;
            
        default:
            break;
    };
}

- (NSInteger)numberOfPointsInLineGraph:(BEMSimpleLineGraphView *)graph {
    return [_datapoints count]; // Number of points in the graph.
}

- (CGFloat)lineGraph:(BEMSimpleLineGraphView *)graph valueForPointAtIndex:(NSInteger)index {
    
    NSMutableArray *datapoint = [_datapoints objectAtIndex:index];
    
    if (graph.alpha == 1.0f){
        return [[datapoint objectAtIndex:1] integerValue]; // The value of the point on the Y-Axis for the index.       only large particles
    }
    if (graph.alpha == 0.99f){
        return [[datapoint objectAtIndex:2] integerValue]; // The value of the point on the Y-Axis for the index.       only small particles
    }
    if (graph.alpha == 0.98f){
        int total_particles = [[datapoint objectAtIndex:1] integerValue] + [[datapoint objectAtIndex:2] integerValue];
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

- (void) log:(RFduino *)rfduino_instance {
    rfduino = rfduino_instance;
    NSLog(@"log: rfduino is %@", rfduino);
    
    //[self checkDevice];
}

// called on every touch in this scene
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    

}

// swipe right recognizer -- adds a random number of particles to the scene
- (void) swipeRight {
    int numLargeParticles = (int)[self randomFloatBetween:currentLargeParticles andLargerFloat:currentLargeParticles + 50];            //number larger than current
    int numSmallParticles = (int)[self randomFloatBetween:currentSmallParticles andLargerFloat:currentSmallParticles + 100];            //number larger than current
   
    [self updateLargeParticles:numLargeParticles andSmallParticles:numSmallParticles];
}

- (void) updateLargeParticles:(int)numLargeParticles andSmallParticles:(int)numSmallParticles{
    NSLog(@"updateLargeParticles: %d, updateSmallParticles: %d", numLargeParticles, numSmallParticles);
    
    [_physicsNode.space setDamping:DAMPING];
    
    //so that we don't fade in new particles
    CCNode *currentChildren = [_physicsNode.children copy];
    
    //remove damping after freeze delay and apply random force to all particles to get moving, also adds color back
    [self performSelector:@selector(removeDamping) withObject:nil afterDelay:FREEZE_DELAY];
    
    if (!isStacked) [self performSelector:@selector(onShake) withObject:nil afterDelay:FREEZE_DELAY];   //only kick start new particles if not stacked
    [self performSelector:@selector(fadeInParticles:) withObject:currentChildren afterDelay:FREEZE_DELAY];
    
    NSLog(@"currents: %d, %d", currentLargeParticles, currentSmallParticles);
    
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
    NSNumber *largeParticlesNumber = [NSNumber numberWithInt:currentLargeParticles];
    NSNumber *smallParticlesNumber = [NSNumber numberWithInt:currentSmallParticles];
    NSDate *now = [NSDate date];
    NSMutableArray *datapoint = [[NSMutableArray alloc] initWithObjects:now, largeParticlesNumber, smallParticlesNumber, nil];
    [_datapoints addObject:datapoint];
}

- (void) removeLargeParticle {
    CCNode *oneLargeParticle = [_physicsNode getChildByName:@"largeParticle" recursively:false];
    [_physicsNode removeChild:oneLargeParticle];
}

- (void) removeSmallParticle {
    CCNode *oneSmallParticle = [_physicsNode getChildByName:@"smallParticle" recursively:false];
    [_physicsNode removeChild:oneSmallParticle];
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
}

- (void)launchLargeParticle {
    NSLog(@"large launched");
    
    // loads the particle.cbb files we have set up in Spritebuilder
    CCNode* largeParticle = [CCBReader load:@"largeParticle"];
    largeParticle.scale = LARGE_PARTICLE_SCALE;
    
    NSLog(@"Large particle: %@", largeParticle);

    UIView *current_view = [[CCDirector sharedDirector] view];
    
    NSLog(@"Current view: %@", current_view);
    
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
    
    NSLog(@"Physics node: %@", _physicsNode);
}

// if device is shaken, apply a random force to all particles --doesn't work yet
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
    [_physicsNode removeChild:_largeLabel];
    [_physicsNode removeChild:_smallLabel];
    
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
    
    _smallLabel = [CCLabelTTF labelWithString:[NSString stringWithFormat:@"%d", currentSmallParticles] fontName:@"Arial" fontSize:16.0f];
    _smallLabel.position = ccp(division/2 + division, currentSmallPositionY + PARTICLE_BASE_SIZE);
    _smallLabel.physicsBody = [CCPhysicsBody bodyWithRect:(CGRect){CGPointZero, _smallLabel.contentSize} cornerRadius:0];
    _smallLabel.color = [CCColor colorWithUIColor:[UIColor colorWithHue:300.0/360.0 saturation:1.0f brightness:0.76 alpha:1.0f]];
    
    [_physicsNode addChild:_largeLabel];      //going to cause problems when we remove children
    [_physicsNode addChild:_smallLabel];      //going to cause problems when we remove children
    
    isStacked = true;
}

- (void)swipeDown {
    CCLOG(@"swipeDown");
    
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
    
    int numLargeParticles = (int)[self randomFloatBetween:MAX(0,currentLargeParticles - 50) andLargerFloat:currentLargeParticles];
    int numSmallParticles = (int)[self randomFloatBetween:MAX(0, currentSmallParticles - 100) andLargerFloat:currentSmallParticles];
    
    [self updateLargeParticles:numLargeParticles andSmallParticles:numSmallParticles];
}

- (void)affectNewParticles{
    _physicsNode.gravity = ccp(0,-10000);                //add gravity
    _bottomBorder.physicsBody.elasticity = 0.0;         //remove elasticity of bottom border
    
    for (CCNode *particle in _physicsNode.children) {
        particle.physicsBody.elasticity = 0.0;          //remove elasticity of each particle
    }
}

@end
