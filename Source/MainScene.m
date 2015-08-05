#import "MainScene.h"
#include <stdlib.h>
#import "CCPhysics+ObjectiveChipmunk.h"

@implementation MainScene{
    CCPhysicsNode *_physicsNode;
    CCNode *_bottomBorder;
    CCEffectBrightness *_brightnessEffect;
    CCEffectStack *_effectStack;
}

#define ARC4RANDOM_MAX 0x100000000
#define LARGE_PARTICLE_SCALE 0.5
#define SMALL_PARTICLE_SCALE 0.2
#define PARTICLE_DELAY 3.0
#define FREEZE_DELAY 6.0
#define EXPLOSION_LENGTH 3.0
#define DAMPING 0.3f

// is called when CCB file has completed loading
- (void)didLoadFromCCB {
    // tell this scene to accept touches
    self.userInteractionEnabled = TRUE;
    
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
    
    _brightnessEffect = [CCEffectBrightness effectWithBrightness:sin(0)];
    _effectStack = [[CCEffectStack alloc] initWithEffects:_brightnessEffect, nil];
}

// called on every touch in this scene
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    

}

// swipe right recognizer -- adds a random number of particles to the scene
- (void) swipeRight {
    
    [_physicsNode.space setDamping:DAMPING];
    
    //so that we don't fade in new particles
    NSArray *currentChildren = [_physicsNode.children copy];
    
    //remove damping after freeze delay and apply random force to all particles to get moving, also adds color back
    [self performSelector:@selector(removeDamping) withObject:nil afterDelay:FREEZE_DELAY];
    [self performSelector:@selector(onShake) withObject:nil afterDelay:FREEZE_DELAY];
    [self performSelector:@selector(fadeInParticles:) withObject:currentChildren afterDelay:FREEZE_DELAY];
    
    int numLargeParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:20];
    int numSmallParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:50];
    
    [self fadeOutParticles];
    
    while (numLargeParticles > 0){
        [self performSelector:@selector(launchLargeParticle) withObject:nil afterDelay:PARTICLE_DELAY];
        numLargeParticles--;
    }
    
    while (numSmallParticles > 0){
        [self performSelector:@selector(launchSmallParticle) withObject:nil afterDelay:PARTICLE_DELAY];
        numSmallParticles--;
    }
    
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
        particle.colorRGBA = [CCColor colorWithUIColor:teal];;
    } else if ([particle.name  isEqual: @"smallParticle"]){
        UIColor *pink = [UIColor colorWithHue:300.0/360.0 saturation:newSaturation brightness:0.76 alpha:1.0f];
        particle.colorRGBA = [CCColor colorWithUIColor:pink];;
    }
    
    //recurse
    if (newSaturation > 0.05){
        double delayInSeconds = 0.1;
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
        double delayInSeconds = 0.1;
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
    // loads the particle.cbb files we have set up in Spritebuilder
    CCNode* largeParticle = [CCBReader load:@"largeParticle"];
    largeParticle.scale = LARGE_PARTICLE_SCALE;

    UIView *current_view = [[CCDirector sharedDirector] view];
    
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
}

// if device is shaken, apply a random force to all particles --doesn't work yet
- (void)onShake {

    for (CCNode *particle in _physicsNode.children) {
        particle.physicsBody.elasticity = 1.0;          //readd elasticity of each particle
        
        // manually create & apply a force to launch the particle
        CGPoint launchDirection = ccp([self randomFloatBetween:-1.0 andLargerFloat:1.0], [self randomFloatBetween:-1.0 andLargerFloat:1.0]);
        CGPoint force = ccpMult(launchDirection, 10000);
        [particle.physicsBody applyForce:force];
    }
    
    _physicsNode.gravity = ccp(0,0);                //remove gravity
    _bottomBorder.physicsBody.elasticity = 1.0;         //add elasticity of bottom border
}

- (float)randomFloatBetween:(float)num1 andLargerFloat:(float)num2 {
    return ((float)arc4random() / ARC4RANDOM_MAX) * (num2-num1) + num1;
}

- (void)swipeDown {
    CCLOG(@"swipeDown");
    
    _physicsNode.gravity = ccp(0,-10000);                //add gravity
    _bottomBorder.physicsBody.elasticity = 0.0;         //remove elasticity of bottom border
    
    for (CCNode *particle in _physicsNode.children) {
        particle.physicsBody.elasticity = 0.0;          //remove elasticity of each particle
    }
    
    // to affect recently added particles
    [self performSelector:@selector(affectNewParticles) withObject:nil afterDelay:PARTICLE_DELAY];
}

- (void) removeDamping {
    [_physicsNode.space setDamping:1.0f];
}

-(void) removeParticle: (CCNode *) particle {
    [_physicsNode removeChild:particle];
}

//removes a random number of particles from the scene
-(void) swipeLeft {
    
    NSMutableArray *currentChildren = [_physicsNode.children copy];
    
    [_physicsNode.space setDamping:DAMPING];
    
    //remove damping after freeze delay and apply random force to all particles to get moving, also adds color back
    [self performSelector:@selector(removeDamping) withObject:nil afterDelay:FREEZE_DELAY];
    [self performSelector:@selector(onShake) withObject:nil afterDelay:FREEZE_DELAY];
    [self performSelector:@selector(fadeInParticles:) withObject:currentChildren afterDelay:FREEZE_DELAY];
    
    int numLargeParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:20];
    int numSmallParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:50];
    
    [self fadeOutParticles];
    
    for (int i = 0; i < numLargeParticles; i++){
        CCNode *oneLargeParticle = [_physicsNode getChildByName:@"largeParticle" recursively:false];
        
        //[self performSelector:@selector(removeParticle:) withObject:oneLargeParticle afterDelay:PARTICLE_DELAY];
        //[currentChildren removeObject:oneLargeParticle];
        [_physicsNode removeChild:oneLargeParticle];
    }
    
    for (int i = 0; i < numSmallParticles; i++){
        CCNode *oneSmallParticle = [_physicsNode getChildByName:@"smallParticle" recursively:false];

        //[self performSelector:@selector(removeParticle:) withObject:oneSmallParticle afterDelay:PARTICLE_DELAY];
        //[currentChildren removeObject:oneSmallParticle];
        [_physicsNode removeChild:oneSmallParticle];
    }
}

- (void)affectNewParticles{
    _physicsNode.gravity = ccp(0,-10000);                //add gravity
    _bottomBorder.physicsBody.elasticity = 0.0;         //remove elasticity of bottom border
    
    for (CCNode *particle in _physicsNode.children) {
        particle.physicsBody.elasticity = 0.0;          //remove elasticity of each particle
    }
}

@end
