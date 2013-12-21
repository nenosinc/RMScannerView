//
//  UIScannerView.m
//  UIScannerView
//
//  Created by iRare Media on 12/3/13.
//  Copyright (c) 2013 iRare Media. All rights reserved.
//

#import "UIScannerView.h"

@interface UIScannerView () {
    AVCaptureDeviceInput *videoInput;
    AVCaptureMetadataOutput *metadataOutput;
    AVCaptureVideoPreviewLayer *previewLayer;
}

- (void)initialize;

- (void)setupMetadataOutput;
- (void)breakdownMetadataOutput;
- (void)setupPreviewLayer;

- (void)setupCameraFocus;
- (void)stopCameraFlash;

@end

@implementation UIScannerView
@synthesize delegate, verboseLogging;

#pragma mark - Initialize

- (void)initialize {
    self.captureSession = [[AVCaptureSession alloc] init];
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self initialize];
    }
    
    return self;
}

- (void)dealloc {
    // Stop Running the Capture Session
    [self.captureSession stopRunning];
    
    // Remove all Inputs
    for (AVCaptureInput *input in self.captureSession.inputs) {
        [self.captureSession removeInput:input];
    }
    
    // Remove all Outputs
    for (AVCaptureOutput *output in self.captureSession.outputs) {
        [self.captureSession removeOutput:output];
    }
    
    // Remove preview layer
    [previewLayer removeFromSuperlayer];
    
    // Set objects to nil
    self.captureSession = nil;
    metadataOutput = nil;
    videoInput = nil;
    previewLayer = nil;
}

#pragma mark - Scanner Checks

- (BOOL)isScanSessionInProgress {
    if ([self.captureSession isRunning] == YES) {
        if ([self.captureSession.outputs containsObject:metadataOutput] == YES) return YES;
        else return NO;
    } else {
        return NO;
    }
}

- (BOOL)isCaptureSessionInProgress {
    if ([self.captureSession isRunning] == YES) return YES;
    else return NO;
}

#pragma mark - Setup and Breakdown

- (void)startCaptureSession {
    // Log capture session start
    if (verboseLogging) NSLog(@"[UIScannerView] Starting Capture Session...");
    
    NSError *error = nil;
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
    
    // Log video check
    if (verboseLogging) NSLog(@"[UIScannerView] Checking for video input...");
    
    if (videoInput) {
        // Log video input
        if (verboseLogging) NSLog(@"[UIScannerView] Valid video input");
        
        // Get the video feed from the camera and add it as an input - as long as we're not already getting a feed
        if ([self.captureSession.inputs containsObject:videoInput] == NO) [self.captureSession addInput:videoInput];
        
        // Log metadata setup
        if (verboseLogging) NSLog(@"[UIScannerView] Setting up metadata output...");
        
        // Start the metadata output
        [self setupMetadataOutput];
        
        // Log preview layer creation
        if (verboseLogging) NSLog(@"[UIScannerView] Creating the preview layer...");
        
        // Create the preview layer
        [self setupPreviewLayer];
        
        // Setup Camera Focus
        [self setupCameraFocus];
        
        // Check if the capture session is already running, if it is don't start it again
        if ([self.captureSession isRunning] == NO) [self.captureSession startRunning];
        
        // Log capture session
        if (verboseLogging) NSLog(@"[UIScannerView] Started Capture Session");
        
        // Begin the capture session animations
        // [UIView animateWithDuration:0.4 delay:0.0 options:UIViewAnimationOptionRepeat animations:^{
        // TODO: Scanner animations here
        // } completion:nil];
    } else {
        NSLog(@"[UIScannerView] %@", error);
        if ([self.delegate respondsToSelector:@selector(errorGeneratingCaptureSession:)])
            [self.delegate errorGeneratingCaptureSession:error];
    }
}

- (void)stopCaptureSession {
    // Stop the capture session
    [self.captureSession stopRunning];
    
    // Log the stop
    if (verboseLogging) NSLog(@"[UIScannerView] Stopped capture session");
}

- (void)startScanSession {
    if (verboseLogging) NSLog(@"[UIScannerView] Starting Scan Session...");
    
    if (([self isCaptureSessionInProgress] == YES) && ([self isScanSessionInProgress] == NO)) {
        if (verboseLogging) NSLog(@"[UIScannerView] Capture session is in progress, but not a scan session. Begginning scan session...");
        
        // Add the metadata output to the session - there is a running capture session, but no scan session
        [self setupMetadataOutput];
        
        if (verboseLogging) NSLog(@"[UIScannerView] Scan session started");
    } else {
        // The capture session may not be running, start it
        if ([self isCaptureSessionInProgress] == NO) {
            [self startCaptureSession];
            
            if (verboseLogging) NSLog(@"[UIScannerView] Capture session not in progress, starting new session");
        }
    }
}

- (void)stopScanSession {
    // Log the stop
    if (verboseLogging) NSLog(@"[UIScannerView] Stopped scan session");
    
    // Breakdown the metadata output
    [self breakdownMetadataOutput];
    
    // Stop the camera flash
    [self stopCameraFlash];
}

- (void)setupMetadataOutput {
    // Log the metadata object
    if (verboseLogging) NSLog(@"[UIScannerView] Creating metadata object");
    
    if (metadataOutput == nil) metadataOutput = [[AVCaptureMetadataOutput alloc] init]; // Setup the metadata object if it doesn't already exist
    if ([self.captureSession.outputs containsObject:metadataOutput] == NO) [self.captureSession addOutput:metadataOutput]; // Add the metadata object if it hasn't been added
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeAztecCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeUPCECode]];
}

- (void)breakdownMetadataOutput {
    // Log the breakdown
    if (verboseLogging) NSLog(@"[UIScannerView] Breaking down metadata output");
    
    if ([self.captureSession.outputs containsObject:metadataOutput] == YES) [self.captureSession removeOutput:metadataOutput];
}

- (void)setupPreviewLayer {
    // Log the creation of the preview layer
    if (verboseLogging) NSLog(@"[UIScannerView] Creating the preview layer");
    
    if (previewLayer == nil) previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    previewLayer.frame = self.layer.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.position = CGPointMake(CGRectGetMidX(self.layer.bounds), CGRectGetMidY(self.layer.bounds));
    if ([self.layer.sublayers containsObject:previewLayer] == NO) [self.layer addSublayer:previewLayer];
}

#pragma mark - Camera Focus

- (void)setupCameraFocus {
    // Grab the current device from the current capture session
    AVCaptureDevice *device = videoInput.device;
    
    // Check if auto focus is supported
    if (![device isFocusPointOfInterestSupported] && ![device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) return;
    
    // Create the error object
    NSError *error;
    
    // Lock the hardware configuration to prevent other apps from changing the configuration
    if ([device lockForConfiguration:&error]) {
        // Auto-focus the camera
        [device setFocusMode:AVCaptureFocusModeAutoFocus];
        
        // Unlock the hardware configuration
        [device unlockForConfiguration];
    } else {
        NSLog(@"[UIScannerView] %@", error);
        if ([[self delegate] respondsToSelector:@selector(errorAcquiringDeviceHardwareLock:)])
            [[self delegate] errorAcquiringDeviceHardwareLock:error];
    }
}

#pragma mark - Camera Flash

- (void)setDeviceFlash:(AVCaptureFlashMode)flashMode {
    // Grab the current device from the current capture session
    AVCaptureDevice *device = videoInput.device;
    
    // Check if flash is supported
    if (![device isFlashAvailable] && ![device isFlashModeSupported:flashMode]) return;
    
    // Create the error object
    NSError *error;
    
    // Lock the hardware configuration to prevent other apps from changing the configuration
    if ([device lockForConfiguration:&error]) {
        // Set the camera flash
        [device setFlashMode:flashMode];
        
        // Unlock the hardware configuration
        [device unlockForConfiguration];
    } else {
        NSLog(@"[UIScannerView] %@", error);
        if ([[self delegate] respondsToSelector:@selector(errorAcquiringDeviceHardwareLock:)])
            [[self delegate] errorAcquiringDeviceHardwareLock:error];
    }
}

- (void)stopCameraFlash {
    // Grab the current device from the current capture session
    AVCaptureDevice *device = videoInput.device;
    
    // Check if flash is supported
    if (![device isFlashAvailable] && ![device isFlashActive]) return;
    
    // Create the error object
    NSError *error;
    
    // Lock the hardware configuration to prevent other apps from changing the configuration
    if ([device lockForConfiguration:&error]) {
        // Set the camera flash
        [device setFlashMode:AVCaptureFlashModeOff];
        
        // Unlock the hardware configuration
        [device unlockForConfiguration];
    } else {
        NSLog(@"[UIScannerView] %@", error);
        if ([[self delegate] respondsToSelector:@selector(errorAcquiringDeviceHardwareLock:)])
            [[self delegate] errorAcquiringDeviceHardwareLock:error];
    }
}

#pragma mark - Touch Gestures

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    // Get the point that the user touched at
    UITouch *touch = [touches anyObject];
    CGPoint touchPoint = [touch locationInView:self];
    
    // Grab the current device from the current capture session
    AVCaptureDevice *device = videoInput.device;
    
    // Check if auto focus is supported
    if (![device isFocusPointOfInterestSupported] && ![device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) return;
    
    // Create the error object
    NSError *error;
    
    // Lock the hardware configuration to prevent other apps from changing the configuration
    if ([device lockForConfiguration:&error]) {
        // Auto-focus the camera to the point the user touched
        [device setFocusPointOfInterest:touchPoint];
        [device setFocusMode:AVCaptureFocusModeAutoFocus];
        
        // Unlock the hardware configuration
        [device unlockForConfiguration];
    } else {
        NSLog(@"[UIScannerView] %@", error);
        if ([[self delegate] respondsToSelector:@selector(errorAcquiringDeviceHardwareLock:)])
            [[self delegate] errorAcquiringDeviceHardwareLock:error];
    }
}

#pragma mark - Output handling

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    // A barcode was scanned, report the scan
	for (AVMetadataObject *metadataObject in metadataObjects) {
        
        // Log the object
        if (verboseLogging) NSLog(@"[UIScannerView] Scanned metadata object: %@", metadataObject);
        
        // Get the AVMetadataMachineReadableCodeObject
		AVMetadataMachineReadableCodeObject *readableObject = (AVMetadataMachineReadableCodeObject *)metadataObject;
        
        // Call the delegate to report the scan
        if ([self.delegate respondsToSelector:@selector(didScanCode:onCodeType:)])
            [self.delegate didScanCode:readableObject.stringValue onCodeType:readableObject.type];
        
        // Call the delegate to check if scanning is continuous or if it should be stopped after the first scan
        if ([self.delegate respondsToSelector:@selector(shouldEndSessionAfterFirstSuccessfulScan)]) {
            BOOL shouldEndSession = [self.delegate shouldEndSessionAfterFirstSuccessfulScan];
            if (shouldEndSession == YES) {
                [self stopScanSession];
            } else {
                continue;
            }
        } else {
            [self stopScanSession];
        }
	}
}

- (NSString *)humanReadableCodeTypeForCode:(NSString *)codeType {
    if (codeType == AVMetadataObjectTypeAztecCode) return @"Aztec";
    if (codeType == AVMetadataObjectTypeCode128Code) return @"Code 128";
    if (codeType == AVMetadataObjectTypeCode39Code) return @"Code 39";
    if (codeType == AVMetadataObjectTypeCode39Mod43Code) return @"Code 39 Mod 43";
    if (codeType == AVMetadataObjectTypeCode93Code) return @"Code 93";
    if (codeType == AVMetadataObjectTypeEAN13Code) return @"EAN13";
    if (codeType == AVMetadataObjectTypeEAN8Code) return @"EAN8";
    if (codeType == AVMetadataObjectTypePDF417Code) return @"PDF417";
    if (codeType == AVMetadataObjectTypeQRCode) return @"QR";
    if (codeType == AVMetadataObjectTypeUPCECode) return @"UPCE";
    
    return nil;
}

@end
