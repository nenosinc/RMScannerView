//
//  ViewController.h
//  Scanner App
//
//  Created by iRare Media on 12/4/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

@import UIKit;
#import "RMScannerView.h"

@interface ViewController : UIViewController <RMScannerViewDelegate, UIAlertViewDelegate, UIBarPositioningDelegate>

@property (strong, nonatomic) IBOutlet RMScannerView *scannerView;
@property (weak, nonatomic) IBOutlet UILabel *statusText;

@property (weak, nonatomic) IBOutlet UIBarButtonItem *sessionToggleButton;
- (IBAction)startNewScannerSession:(id)sender;

@end
