/*
 Copyright (c) 2013 OpenSourceRF.com.  All right reserved.
 
 This library is free software; you can redistribute it and/or
 modify it under the terms of the GNU Lesser General Public
 License as published by the Free Software Foundation; either
 version 2.1 of the License, or (at your option) any later version.
 
 This library is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 See the GNU Lesser General Public License for more details.
 
 You should have received a copy of the GNU Lesser General Public
 License along with this library; if not, write to the Free Software
 Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA  02110-1301  USA
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
 CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
 SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

#import <QuartzCore/QuartzCore.h>

#import "ScanViewController.h"

#import "RFduinoManager.h"
#import "RFduino.h"

//#import "AppViewController.h"         replaced with
#import "MainScene.h"

#import "CustomCellBackground.h"

@interface ScanViewController()
{
    bool editingRow;
    bool loadService;
}
@end

int inputLarge;
int inputSmall;

@implementation ScanViewController

- (id)init
{
    self = [super init];
    if (self) {
        rfduinoManager = [RFduinoManager sharedRFduinoManager];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    rfduinoManager.delegate = self;
    
    int numberOfLines = 3;
    self.tableView.rowHeight = (44.0 + (numberOfLines - 1) * 19.0);
    
    UIColor *start = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.15];
    UIColor *stop = [UIColor colorWithRed:58/255.0 green:108/255.0 blue:183/255.0 alpha:0.45];
    
    CAGradientLayer *gradient = [CAGradientLayer layer];
    // gradient.frame = [self.view bounds];
    gradient.frame = CGRectMake(0.0, 0.0, 1024.0, 1024.0);
    gradient.colors = [NSArray arrayWithObjects:(id)start.CGColor, (id)stop.CGColor, nil];
    [self.tableView.layer insertSublayer:gradient atIndex:0];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)shouldDisplayAlertTitled:(NSString *)title messageBody:(NSString *)body
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:body
                                                    delegate:nil
                                           cancelButtonTitle:@"OK"
                                           otherButtonTitles:nil];
    [alert show];
}

- (void)didDiscoverRFduino:(RFduino *)rfduino_instance
{
    NSLog(@"didDiscoverRFduino");
    
    rfduinoManager = [RFduinoManager sharedRFduinoManager];
    
    //shortcut past clicking on rfduino, assumes only one in range--autoconnects
    [rfduinoManager connectRFduino:rfduino_instance];
}

- (void)didUpdateDiscoveredRFduino:(RFduino *)rfduino
{

}

- (void)didConnectRFduino:(RFduino *)rfduino
{
    NSLog(@"didConnectRFduino");
    
    [rfduinoManager stopScan];
    loadService = false;
    
    //MainScene *mainScene = [MainScene alloc];
    //[mainScene performSelector:@selector(log:) withObject:rfduino afterDelay:1.0];      //initial delay to give time for setup
    
    if (rfduino.advertisementData){
        NSString *advertising = @"";
        if (rfduino.advertisementData) {
            advertising = [[NSString alloc] initWithData:rfduino.advertisementData encoding:NSUTF8StringEncoding];
            NSLog(@"advertisement: %@", advertising);
        }
        
        NSArray *items = [advertising componentsSeparatedByString:@","];
        
        int numSmallParticles = [[items objectAtIndex:0] intValue];
        int numLargeParticles = [[items objectAtIndex:1] intValue];
        NSLog(@"%d, %d", numLargeParticles, numSmallParticles);
        
        inputLarge = numLargeParticles;
        inputSmall = numSmallParticles;
        
    }
    
    //_connectedRFduino = rfduino;
}

- (void)didLoadServiceRFduino:(RFduino *)rfduino
{
    //AppViewController *viewController = [[AppViewController alloc] init];
    //viewController.rfduino = rfduino;                                         replaced with

    loadService = true;
    //[[self navigationController] pushViewController:mainScene animated:YES];
    
    //[self.view removeFromSuperview];
    //[super.view removeFromSuperview];
    //[[CCDirector sharedDirector] pushScene: (CCScene*) mainScene];
    //[[CCDirector sharedDirector] pushScene:mainScene];
    
}

- (void)didDisconnectRFduino:(RFduino *)rfduino
{
    NSLog(@"didDisconnectRFduino");
    
    if (loadService) {
        [[self navigationController] popViewControllerAnimated:YES];
    }

    [rfduinoManager startScan];
    [self.tableView reloadData];
}

@end
