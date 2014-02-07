//
//  ViewController.m
//  Scanner App
//
//  Created by iRare Media on 12/4/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@end

@implementation ViewController
@synthesize scannerView, statusText;

- (void)viewDidLoad {
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // Set verbose logging to YES so we can see exactly what's going on
    [scannerView setVerboseLogging:YES];
    
    // Set animations to YES for some nice effects
    [scannerView setAnimateScanner:YES];
    
    // Set code outline to YES for a box around the scanned code
    [scannerView setDisplayCodeOutline:YES];
    
    // Start the capture session when the view loads - this will also start a scan session
    [scannerView startCaptureSession];
    
    // Set the title of the toggle button
    self.sessionToggleButton.title = @"Stop";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)startNewScannerSession:(id)sender {
    if ([scannerView isScanSessionInProgress]) {
        [scannerView stopScanSession];
        self.sessionToggleButton.title = @"Start";
    } else {
        [scannerView startScanSession];
        self.sessionToggleButton.title = @"Stop";
    }
}

- (void)didScanCode:(NSString *)scannedCode onCodeType:(NSString *)codeType {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[NSString stringWithFormat:@"Scanned %@", [scannerView humanReadableCodeTypeForCode:codeType]] message:scannedCode delegate:self cancelButtonTitle:@"Okay" otherButtonTitles:@"New Session", nil];
    [alert show];
}

- (void)errorGeneratingCaptureSession:(NSError *)error {
    [scannerView stopCaptureSession];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Unsupported Device" message:@"This device does not have a camera. Run this app on an iOS device that has a camera." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
    [alert show];
    
    statusText.text = @"Unsupported Device";
    self.sessionToggleButton.title = @"Error";
}

- (void)errorAcquiringDeviceHardwareLock:(NSError *)error {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Focus Unavailable" message:@"Tap to focus is currently unavailable. Try again in a little while." delegate:nil cancelButtonTitle:@"Okay" otherButtonTitles:nil];
    [alert show];
}

- (BOOL)shouldEndSessionAfterFirstSuccessfulScan {
    // Return YES to only scan one barcode, and then finish - return NO to continually scan.
    // If you plan to test the return NO functionality, it is recommended that you remove the alert view from the "didScanCode:" delegate method implementation
    // The Display Code Outline only works if this method returns NO
    return YES;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"New Session"]) {
        [scannerView startScanSession];
        self.sessionToggleButton.title = @"Stop";
    } else if ([[alertView buttonTitleAtIndex:buttonIndex] isEqualToString:@"Okay"]) {
        self.sessionToggleButton.title = @"Start";
    }
}

- (UIBarPosition)positionForBar:(id <UIBarPositioning>)bar {
    return UIBarPositionTopAttached;
}

-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    [scannerView setScannerViewOrientation:toInterfaceOrientation];
}
@end
