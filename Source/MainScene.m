#import "MainScene.h"
#include <stdlib.h>
#import "CCPhysics+ObjectiveChipmunk.h"

@implementation MainScene{
    CCPhysicsNode *_physicsNode;
    CCNode *_bottomBorder;
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
}

// called on every touch in this scene
- (void)touchBegan:(UITouch *)touch withEvent:(UIEvent *)event {
    

}

// swipe right recognizer -- adds a random number of particles to the scene
- (void) swipeRight {
    
    [_physicsNode.space setDamping:DAMPING];
    
    //remove damping after freeze delay and apply random force to all particles to get moving
    [self performSelector:@selector(removeDamping) withObject:nil afterDelay:FREEZE_DELAY];
    [self performSelector:@selector(onShake) withObject:nil afterDelay:FREEZE_DELAY];
    
    /*NSArray *currentChildren = [_physicsNode.children copy];
    
    //freezes all particles (ie by replacing with static particles)
    for (CCNode *particle in currentChildren) {
        if ([particle.name  isEqual: (@"largeParticle")]){
            // loads the particle.cbb files we have set up in Spritebuilder
            CCNode* staticLargeParticle = [CCBReader load:@"staticLargeParticle2"];
            staticLargeParticle.scale = LARGE_PARTICLE_SCALE;
            
            // position the particles at previously specified particle locations
            staticLargeParticle.position = ccp(particle.position.x, particle.position.y);
            staticLargeParticle.name = @"largeParticle";
            
            [_physicsNode addChild:staticLargeParticle];
            [_physicsNode removeChild:particle];
            
            [self performSelector:@selector(pushLargeParticle:) withObject:staticLargeParticle afterDelay:PARTICLE_DELAY];
        } else if ([particle.name  isEqual: @"smallParticle"]){
            // loads the particle.cbb files we have set up in Spritebuilder
            CCNode* staticSmallParticle = [CCBReader load:@"staticSmallParticle2"];
            staticSmallParticle.scale = SMALL_PARTICLE_SCALE;
            staticSmallParticle.name = @"smallParticle";
            
            // position the particles at previously specified particle locations
            staticSmallParticle.position = ccp(particle.position.x, particle.position.y);
            
            [_physicsNode addChild:staticSmallParticle];
            [_physicsNode removeChild:particle];
            
            [self performSelector:@selector(pushSmallParticle:) withObject:staticSmallParticle afterDelay:PARTICLE_DELAY];
        }
    }*/
    
    int numLargeParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:20];
    int numSmallParticles = (int)[self randomFloatBetween:1.0 andLargerFloat:50];
    
    while (numLargeParticles > 0){
        [self performSelector:@selector(launchLargeParticle) withObject:nil afterDelay:PARTICLE_DELAY];
        //[self launchLargeParticle];
        numLargeParticles--;
    }
    
    while (numSmallParticles > 0){
        [self performSelector:@selector(launchSmallParticle) withObject:nil afterDelay:PARTICLE_DELAY];
        //[self launchSmallParticle];
        numSmallParticles--;
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
    CCColor *pink = [CCColor colorWithRed: 251.0/255.0 green:90.0/255.0 blue:251.0/255.0 alpha:1];
    smallParticle.colorRGBA = pink;
    
    // add the particles to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:smallParticle];
    
    //we don't need this anymore because all particles receive push
    //[self performSelector:@selector(pushSmallParticle:) withObject:smallParticle afterDelay:PARTICLE_DELAY];
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
    CCColor *teal = [CCColor colorWithRed: 35.0/255.0 green:244.0/255.0 blue:255.0/255.0 alpha:1];
    largeParticle.colorRGBA = teal;
    
    // add the particles to the physicsNode of this scene (because it has physics enabled)
    [_physicsNode addChild:largeParticle];
    
    //we don't need this anymore because all particles receive push
    //[self performSelector:@selector(pushLargeParticle:) withObject:largeParticle afterDelay:PARTICLE_DELAY];
}

- (void)pushLargeParticle: (CCNode *) largeParticle {
    
    /*// loads the dynamic particle.cbb files we have set up in Spritebuilder
    CCNode* dynamicLargeParticle = [CCBReader load:@"largeParticle"];
    dynamicLargeParticle.scale = LARGE_PARTICLE_SCALE;
    
    // position the particles at same location as previous particle
    dynamicLargeParticle.position = largeParticle.position;
    
    //set color
    CCColor *teal = [CCColor colorWithRed: 35.0/255.0 green:244.0/255.0 blue:255.0/255.0 alpha:1];
    dynamicLargeParticle.colorRGBA = teal;
    
    // remove static particle and add dynamic particle
    [_physicsNode removeChild:largeParticle];
    [_physicsNode addChild:dynamicLargeParticle];*/
    
    // only apply force if less than 75 particles
    //if ([_physicsNode.children count] < 75){
        // manually create & apply a force to launch the particle
        CGPoint launchDirection = ccp([self randomFloatBetween:-1.0 andLargerFloat:1.0], [self randomFloatBetween:-1.0 andLargerFloat:1.0]);
        CGPoint force = ccpMult(launchDirection, 10000);
        [largeParticle.physicsBody applyForce:force];
    //}
}

- (void)pushSmallParticle: (CCNode *) smallParticle {
    
    // loads the dynamic particle.cbb files we have set up in Spritebuilder
    CCNode* dynamicSmallParticle = [CCBReader load:@"smallParticle"];
    dynamicSmallParticle.scale = SMALL_PARTICLE_SCALE;
    
    // position the particles at same location as previous particle
    dynamicSmallParticle.position = smallParticle.position;
    
    //set color
    CCColor *pink = [CCColor colorWithRed: 251.0/255.0 green:90.0/255.0 blue:251.0/255.0 alpha:1];
    dynamicSmallParticle.colorRGBA = pink;
    
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

- (void) removeDamping {
    [_physicsNode.space setDamping:1.0f];
}

//removes a random number of particles from the scene
-(void) swipeLeft {
    
    NSArray *currentChildren = [_physicsNode.children copy];
    
    [_physicsNode.space setDamping:DAMPING];
    
    //remove damping after particle delay
    [self performSelector:@selector(removeDamping) withObject:nil afterDelay:FREEZE_DELAY];
    
    //freezes all particles (ie by replacing with static particles)
    /*for (CCNode *particle in currentChildren) {
        if ([particle.name  isEqual: (@"largeParticle")]){
            // loads the particle.cbb files we have set up in Spritebuilder
            CCNode* staticLargeParticle = [CCBReader load:@"staticLargeParticle2"];
            staticLargeParticle.scale = LARGE_PARTICLE_SCALE;
            staticLargeParticle.name = @"largeParticle";
            
            
            // position the particles at previously specified particle locations
            staticLargeParticle.position = ccp(particle.position.x, particle.position.y);
            
            [_physicsNode addChild:staticLargeParticle];
            [_physicsNode removeChild:particle];
        } else if ([particle.name  isEqual: @"smallParticle"]){
            // loads the particle.cbb files we have set up in Spritebuilder
            CCNode* staticSmallParticle = [CCBReader load:@"staticSmallParticle2"];
            staticSmallParticle.scale = SMALL_PARTICLE_SCALE;
            staticSmallParticle.name = @"smallParticle";
            
            // position the particles at previously specified particle locations
            staticSmallParticle.position = ccp(particle.position.x, particle.position.y);
            
            [_physicsNode addChild:staticSmallParticle];
            [_physicsNode removeChild:particle];
        }
    }*/
    
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
        explosion.duration = EXPLOSION_LENGTH;
        
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
        explosion.duration = EXPLOSION_LENGTH;
        
        explosion.scale = SMALL_PARTICLE_SCALE;
        
        // place the particle effect on the particles position
        //explosion.position = staticLargeParticle2.position;
        // add the particle effect to the same node the particle is on
        //[staticLargeParticle2.parent performSelector:@selector(addChild:) withObject:explosion afterDelay:PARTICLE_DELAY];
        
        explosion.position = oneSmallParticle.position;
        [oneSmallParticle.parent addChild:explosion];
        [_physicsNode removeChild:oneSmallParticle];
    }
    
    currentChildren = [_physicsNode.children copy];
    
    //get particles moving again
    for (CCNode *particle in currentChildren) {
        if ([particle.name  isEqual: (@"largeParticle")]){
            [self performSelector:@selector(pushLargeParticle:) withObject:particle afterDelay:PARTICLE_DELAY];
        } else if ([particle.name  isEqual: @"smallParticle"]){
            [self performSelector:@selector(pushSmallParticle:) withObject:particle afterDelay:PARTICLE_DELAY];
        }
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
