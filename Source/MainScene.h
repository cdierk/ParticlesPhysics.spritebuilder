#import "RFduino.h"
#import "BEMSimpleLineGraphView.h"

extern int inputLarge;
extern int inputSmall;

@interface MainScene : CCNode <BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource>

@property(strong, nonatomic) RFduino *rfduino;
@property CCPhysicsNode *_physicsNode;

- (void) onShake;
- (void) log:(RFduino *)rfduino_instance;

@end
