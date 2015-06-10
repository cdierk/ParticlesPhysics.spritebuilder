#import "MainScene.h"
#include <stdlib.h>

@implementation MainScene{
    CCPhysicsNode *_physicsNode;
    CCNode *_bottomBorder;
}

#define ARC4RANDOM_MAX 0x100000000
#define LARGE_PARTICLE_SCALE 0.5
#define SMALL_PARTICLE_SCALE 0.2
#define PARTICLE_DELAY 3.0

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
}

// called on every touch in this scene
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    

}

// swipe right recognizer -- adds a random number of particles to the scene
- (void) swipeRight {
    
    int numLargeParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:20];
    int numSmallParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:50];
    
    while (numLargeParticles > 0){
        [self launchLargeParticle];
        numLargeParticles--;
    }
    
    while (numSmallParticles > 0){
        [self launchSmallParticle];
        numSmallParticles--;
    }
    
}

- (void) launchSmallParticle {
    // loads the particle.cbb files we have set up in Spritebuilder
    CCNode* staticSmallParticle = [CCBReader load:@"staticSmallParticle"];
    staticSmallParticle.scale = SMALL_PARTICLE_SCALE;
    
    UIView *current_view = [[CCDirector sharedDirector] view];
    
    // random location for small particle
    int xmin_small = (staticSmallParticle.boundingBox.size.width)/2;
    int ymin_small = (staticSmallParticle.boundingBox.size.height)/2;
    int x_small = xmin_small + (arc4random() % (int)(current_view.frame.size.width - staticSmallParticle.boundingBox.size.width));
    int y_small = ymin_small + (arc4random() % (int)(current_view.frame.size.height - staticSmallParticle.boundingBox.size.height));
    
    // position the particles at previously specified random locations
    staticSmallParticle.position = ccp(x_small, y_small);
    
    // add the particles to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:staticSmallParticle];
    
    [self performSelector:@selector(pushSmallParticle:) withObject:staticSmallParticle afterDelay:PARTICLE_DELAY];
}

- (void)launchLargeParticle {
    // loads the particle.cbb files we have set up in Spritebuilder
    CCNode* staticLargeParticle = [CCBReader load:@"staticLargeParticle"];
    staticLargeParticle.scale = LARGE_PARTICLE_SCALE;

    UIView *current_view = [[CCDirector sharedDirector] view];
    
    // random location for large particle
    int xmin_large = (staticLargeParticle.boundingBox.size.width)/2;
    int ymin_large = (staticLargeParticle.boundingBox.size.height)/2;
    int x_large = xmin_large + (arc4random() % (int)(current_view.frame.size.width - staticLargeParticle.boundingBox.size.width));
    int y_large = ymin_large + (arc4random() % (int)(current_view.frame.size.height - staticLargeParticle.boundingBox.size.height));
    
    // position the particles at previously specified random locations
    staticLargeParticle.position = ccp(x_large, y_large);
    
    // add the particles to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:staticLargeParticle];
    
    [self performSelector:@selector(pushLargeParticle:) withObject:staticLargeParticle afterDelay:PARTICLE_DELAY];
}

- (void)pushLargeParticle: (CCNode *) largeParticle {
    
    // loads the dynamic particle.cbb files we have set up in Spritebuilder
    CCNode* dynamicLargeParticle = [CCBReader load:@"largeParticle"];
    dynamicLargeParticle.scale = LARGE_PARTICLE_SCALE;
    
    // position the particles at same location as previous particle
    dynamicLargeParticle.position = largeParticle.position;
    
    //set name so that we can distinguish between large/small and remove it later
    dynamicLargeParticle.name = @"largeParticle";
    
    // remove static particle and add dynamic particle
    [_physicsNode removeChild:largeParticle];
    [_physicsNode addChild:dynamicLargeParticle];
    
    // only apply force if less than 75 particles
    //if ([_physicsNode.children count] < 75){
        // manually create & apply a force to launch the particle
        CGPoint launchDirection = ccp([self randomFloatBetween:-1.0 andLargerFloat:1.0], [self randomFloatBetween:-1.0 andLargerFloat:1.0]);
        CGPoint force = ccpMult(launchDirection, 10000);
        [dynamicLargeParticle.physicsBody applyForce:force];
    //}
}

- (void)pushSmallParticle: (CCNode *) smallParticle {
    
    // loads the dynamic particle.cbb files we have set up in Spritebuilder
    CCNode* dynamicSmallParticle = [CCBReader load:@"smallParticle"];
    dynamicSmallParticle.scale = SMALL_PARTICLE_SCALE;
    
    // position the particles at same location as previous particle
    dynamicSmallParticle.position = smallParticle.position;
    
    //set name so that we can distinguish between large/small and remove it later
    dynamicSmallParticle.name = @"smallParticle";
    
    // remove static particle and add dynamic particle
    [_physicsNode removeChild:smallParticle];
    [_physicsNode addChild:dynamicSmallParticle];
    
    // only apply force if less than 75 particles
    //if ([_physicsNode.children count] < 75){
        
        // manually create & apply a force to launch the particle
        CGPoint launchDirection = ccp([self randomFloatBetween:-1.0 andLargerFloat:1.0], [self randomFloatBetween:-1.0 andLargerFloat:1.0]);
        CGPoint force = ccpMult(launchDirection, 10000);
        [dynamicSmallParticle.physicsBody applyForce:force];
    //}
}

// if device is shaken, apply a random force to all particles --doesn't work yet
- (void)onShake {
    //NSLog(@"shake from mainScene.m");
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

//removes a random number of particles from the scene
-(void) swipeLeft {
    int numLargeParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:20];
    int numSmallParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:50];
    
    for (int i = 0; i < numLargeParticles; i++){
        CCNode *oneLargeParticle = [_physicsNode getChildByName:@"largeParticle" recursively:false];
        
        /*
        //add a static particle in it's place
        // loads the dynamic particle.cbb files we have set up in Spritebuilder
        CCNode* staticLargeParticle2 = [CCBReader load:@"staticLargeParticle2"];
        staticLargeParticle2.scale = LARGE_PARTICLE_SCALE;
        
        // position the particles at same location as previous particle
        staticLargeParticle2.position = oneLargeParticle.position;
        
        // remove dynamic particle and add static particle
        [_physicsNode removeChild:oneLargeParticle];
        [_physicsNode addChild:staticLargeParticle2];
        
        // remove static particle after 3 seconds
        [_physicsNode performSelector:@selector(removeChild:) withObject:staticLargeParticle2 afterDelay:PARTICLE_DELAY];
        */
         
        // load particle effect
        CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"ParticleExplosion"];
        // make the particle effect clean itself up, once it is completed
        explosion.autoRemoveOnFinish = TRUE;
        
        explosion.scale = LARGE_PARTICLE_SCALE;
        
        // place the particle effect on the particles position
        //explosion.position = staticLargeParticle2.position;
        // add the particle effect to the same node the particle is on
        //[staticLargeParticle2.parent performSelector:@selector(addChild:) withObject:explosion afterDelay:PARTICLE_DELAY];
        
        explosion.position = oneLargeParticle.position;
        [oneLargeParticle.parent addChild:explosion];
        [_physicsNode removeChild:oneLargeParticle];
    }
    
    for (int i = 0; i < numSmallParticles; i++){
        CCNode *oneSmallParticle = [_physicsNode getChildByName:@"smallParticle" recursively:false];
        
        /*
        //add a static particle in it's place
        // loads the dynamic particle.cbb files we have set up in Spritebuilder
        CCNode* staticSmallParticle2 = [CCBReader load:@"staticSmallParticle2"];
        staticSmallParticle2.scale = SMALL_PARTICLE_SCALE;
        
        // position the particles at same location as previous particle
        staticSmallParticle2.position = oneSmallParticle.position;
        
        // remove dynamic particle and add static particle
        [_physicsNode removeChild:oneSmallParticle];
        [_physicsNode addChild:staticSmallParticle2];
        
        // remove static particle after 3 seconds
        [_physicsNode performSelector:@selector(removeChild:) withObject:staticSmallParticle2 afterDelay:PARTICLE_DELAY];
         */
        
        // load particle effect
        CCParticleSystem *explosion = (CCParticleSystem *)[CCBReader load:@"smallParticleExplosion"];
        // make the particle effect clean itself up, once it is completed
        explosion.autoRemoveOnFinish = TRUE;
        
        explosion.scale = SMALL_PARTICLE_SCALE;
        
        // place the particle effect on the particles position
        //explosion.position = staticLargeParticle2.position;
        // add the particle effect to the same node the particle is on
        //[staticLargeParticle2.parent performSelector:@selector(addChild:) withObject:explosion afterDelay:PARTICLE_DELAY];
        
        explosion.position = oneSmallParticle.position;
        [oneSmallParticle.parent addChild:explosion];
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
