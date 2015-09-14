#import "RFduino.h"

@interface MainScene : CCNode

@property(strong, nonatomic) RFduino *rfduino;
@property CCPhysicsNode *_physicsNode;

- (void) onShake;
- (void) log:(RFduino *)rfduino_instance;

@end
