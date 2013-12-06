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

@end
