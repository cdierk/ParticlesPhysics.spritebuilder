#import "BEMSimpleLineGraphView.h"

extern int inputLarge;
extern int inputSmall;

@interface MainScene : CCNode <BEMSimpleLineGraphDelegate, BEMSimpleLineGraphDataSource>

@property CCPhysicsNode *_physicsNode;
@property (strong) NSMutableArray *datapoints;

- (void) onShake;

@end
