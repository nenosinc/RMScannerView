//
//  RMScannerView.m
//  RMScannerView
//
//  Created by iRare Media on 12/3/13.
//  Copyright (c) 2014 iRare Media. All rights reserved.
//

#import "RMScannerView.h"

@interface RMScannerView () {
    AVCaptureDeviceInput *videoInput;
    AVCaptureMetadataOutput *metadataOutput;
    AVCaptureVideoPreviewLayer *previewLayer;
    UIView *laserView;
    RMOutlineBox *boundingBox;
}

- (void)initialize;

- (void)setupMetadataOutput;
- (void)breakdownMetadataOutput;
- (void)setupPreviewLayer;

- (void)setupCameraFocus;
- (void)stopCameraFlash;

@end

@implementation RMScannerView
@synthesize delegate, verboseLogging, animateScanner, displayCodeOutline;

#pragma mark - Initialize

- (void)initialize {
    self.captureSession = [[AVCaptureSession alloc] init];
    [[NSNotificationCenter defaultCenter]
     addObserver:self
     selector:@selector(setScannerViewOrientation:)
     name:UIDeviceOrientationDidChangeNotification
     object:nil];
	self->_scannerLineColor = [UIColor redColor];
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
    
    // Remove orient observer
    [[NSNotificationCenter defaultCenter]
     removeObserver:self
     name:UIDeviceOrientationDidChangeNotification
     object:nil];
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
    if (verboseLogging) NSLog(@"[RMScannerView] Starting Capture Session...");
    
    NSError *error = nil;
    AVCaptureDevice *videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    videoInput = [AVCaptureDeviceInput deviceInputWithDevice:videoCaptureDevice error:&error];
    
    // Log video check
    if (verboseLogging) NSLog(@"[RMScannerView] Checking for video input...");
    
    if (videoInput) {
        // Log video input
        if (verboseLogging) NSLog(@"[RMScannerView] Valid video input");
        
        // Get the video feed from the camera and add it as an input - as long as we're not already getting a feed
        if ([self.captureSession.inputs containsObject:videoInput] == NO) [self.captureSession addInput:videoInput];
        
        // Log metadata setup
        if (verboseLogging) NSLog(@"[RMScannerView] Setting up metadata output...");
        
        // Start the metadata output
        [self setupMetadataOutput];
        
        // Log preview layer creation
        if (verboseLogging) NSLog(@"[RMScannerView] Creating the preview layer...");
        
        // Create the preview layer
        [self setupPreviewLayer];
        
        // Setup Camera Focus
        [self setupCameraFocus];
        
        // Check if the capture session is already running, if it is don't start it again
        if ([self.captureSession isRunning] == NO) [self.captureSession startRunning];
        
        // Log capture session
        if (verboseLogging) NSLog(@"[RMScannerView] Started Capture Session");
        
        // Start Scan
        [self startScanSession];
        
    } else {
        NSLog(@"[RMScannerView] Invalid video input. There is no video input, or the scanner was not able to obtain input.");
        NSLog(@"[RMScannerView] %@", error);
        if ([self.delegate respondsToSelector:@selector(errorGeneratingCaptureSession:)])
            [self.delegate errorGeneratingCaptureSession:error];
    }
}

- (void)stopCaptureSession {
    // Stop the scan session
    [self stopScanSession];
    
    // Remove the box
    [UIView animateWithDuration:0.2 animations:^{
        boundingBox.alpha = 0.0;
    }];
    
    // Stop the capture session
    [self.captureSession stopRunning];
    
    // Log the stop
    if (verboseLogging) NSLog(@"[RMScannerView] Stopped capture session");
}

- (void)startScanSession {
    if (verboseLogging) NSLog(@"[RMScannerView] Starting Scan Session...");
    
    if (([self isCaptureSessionInProgress] == YES) && ([self isScanSessionInProgress] == NO)) {
        if (verboseLogging) NSLog(@"[RMScannerView] Capture session is in progress, but not a scan session. Begginning scan session...");
        
        // Add the metadata output to the session - there is a running capture session, but no scan session
        [self setupMetadataOutput];
        
        if (verboseLogging) NSLog(@"[RMScannerView] Scan session started");
    } else if ([self isCaptureSessionInProgress] == NO) {
        if (verboseLogging) NSLog(@"[RMScannerView] Capture session not in progress, starting new session");
        
        // The capture session may not be running, start it
        [self startCaptureSession];
    }
    
    // Begin the capture session animations
    if (animateScanner) {
        // Add the view to draw the bounding box for the UIView
        boundingBox = [[RMOutlineBox alloc] initWithFrame:self.bounds];
        boundingBox.alpha = 0.0;
        [self addSubview:boundingBox];
        
        if (!laserView) laserView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 2)];
        laserView.backgroundColor = self.scannerLineColor;
        laserView.layer.shadowColor = self.scannerLineColor.CGColor;
        laserView.layer.shadowOffset = CGSizeMake(0.5, 0.5);
        laserView.layer.shadowOpacity = 0.6;
        laserView.layer.shadowRadius = 1.5;
        laserView.alpha = 0.0;
        if (![[self subviews] containsObject:laserView]) [self addSubview:laserView];
        
        // Add the line
        [UIView animateWithDuration:0.2 animations:^{
            laserView.alpha = 1.0;
        }];
        
        [UIView animateWithDuration:4.0 delay:0.0 options:UIViewAnimationOptionAutoreverse | UIViewAnimationOptionRepeat | UIViewAnimationOptionCurveEaseInOut animations:^{
            laserView.frame = CGRectMake(0, self.frame.size.height, self.frame.size.width, 2);
        } completion:nil];
    }
}

- (void)stopScanSession {
    // Remove the line
    [UIView animateWithDuration:0.2 animations:^{
        laserView.alpha = 0.0;
    }];
    
    // Breakdown the metadata output
    [self breakdownMetadataOutput];
    
    // Stop the camera flash
    [self stopCameraFlash];
    
    // Log the stop
    if (verboseLogging) NSLog(@"[RMScannerView] Stopped scan session");
}

- (void)setupMetadataOutput {
    // Log the metadata object
    if (verboseLogging) NSLog(@"[RMScannerView] Creating metadata object");
    
    if (metadataOutput == nil) metadataOutput = [[AVCaptureMetadataOutput alloc] init]; // Setup the metadata object if it doesn't already exist
    if ([self.captureSession.outputs containsObject:metadataOutput] == NO) [self.captureSession addOutput:metadataOutput]; // Add the metadata object if it hasn't been added
    [metadataOutput setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    [metadataOutput setMetadataObjectTypes:@[AVMetadataObjectTypeAztecCode, AVMetadataObjectTypeCode128Code, AVMetadataObjectTypeCode39Code, AVMetadataObjectTypeCode39Mod43Code, AVMetadataObjectTypeCode93Code, AVMetadataObjectTypeEAN13Code, AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypePDF417Code, AVMetadataObjectTypeQRCode, AVMetadataObjectTypeUPCECode]];
}

- (void)breakdownMetadataOutput {
    // Log the breakdown
    if (verboseLogging) NSLog(@"[RMScannerView] Breaking down metadata output");
    
    // Remove the metadata output from the capture session
    if ([self.captureSession.outputs containsObject:metadataOutput] == YES) [self.captureSession removeOutput:metadataOutput];
}

- (void)setupPreviewLayer {
    // Log the creation of the preview layer
    if (verboseLogging) NSLog(@"[RMScannerView] Creating the preview layer");
    
    // Create the preview layer to display the video on
    if (previewLayer == nil) previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    previewLayer.frame = self.layer.bounds;
    previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    previewLayer.position = CGPointMake(CGRectGetMidX(self.layer.bounds), CGRectGetMidY(self.layer.bounds));
    [[previewLayer connection] setVideoOrientation:((AVCaptureVideoOrientation)[[UIDevice currentDevice] orientation])];
    if ([self.layer.sublayers containsObject:previewLayer] == NO) [self.layer addSublayer:previewLayer];
}

#pragma mark - Camera Focus

- (void)setupCameraFocus {
    // Grab the current device from the current capture session
    AVCaptureDevice *device = videoInput.device;
    
    // Create the error object
    NSError *error;
    
    // Lock the hardware configuration to prevent other apps from changing the configuration
    if ([device lockForConfiguration:&error]) {
        
        // Check if auto focus is supported
        if ([device isFocusPointOfInterestSupported] && [device isFocusModeSupported:AVCaptureFocusModeAutoFocus]) {
            // Auto-focus the camera
            [device setFocusMode:AVCaptureFocusModeAutoFocus];
        }
        
        // Check if auto focus range restruction is supported
        if ([device isAutoFocusRangeRestrictionSupported]) {
            // Configure auto-focus for near objects
            [device setAutoFocusRangeRestriction:AVCaptureAutoFocusRangeRestrictionNear];
        }
    
        // Unlock the hardware configuration
        [device unlockForConfiguration];
    } else {
        NSLog(@"[RMScannerView] %@", error);
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
        NSLog(@"[RMScannerView] %@", error);
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
        NSLog(@"[RMScannerView] %@", error);
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
        NSLog(@"[RMScannerView] %@", error);
        if ([[self delegate] respondsToSelector:@selector(errorAcquiringDeviceHardwareLock:)])
            [[self delegate] errorAcquiringDeviceHardwareLock:error];
    }
}

#pragma mark - Output handling

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection {
    // A barcode was scanned, report the scan
	for (AVMetadataObject *metadataObject in metadataObjects) {
        
        // Log the object
        if (verboseLogging) NSLog(@"[RMScannerView] Scanned metadata object: %@", metadataObject);
        
        // Get the AVMetadataMachineReadableCodeObject
		AVMetadataMachineReadableCodeObject *readableObject = (AVMetadataMachineReadableCodeObject *)metadataObject;
        AVMetadataMachineReadableCodeObject *transformedObject = (AVMetadataMachineReadableCodeObject *)[previewLayer transformedMetadataObjectForMetadataObject:metadataObject];
        
        // Call the delegate to report the scan
        if ([self.delegate respondsToSelector:@selector(didScanCode:onCodeType:)])
            [self.delegate didScanCode:readableObject.stringValue onCodeType:readableObject.type];
        
        // Call the delegate to check if scanning is continuous or if it should be stopped after the first scan
        if ([self.delegate respondsToSelector:@selector(shouldEndSessionAfterFirstSuccessfulScan)]) {
            BOOL shouldEndSession = [self.delegate shouldEndSessionAfterFirstSuccessfulScan];
            if (shouldEndSession == YES) {
                [self stopScanSession];
            } else {
                if (displayCodeOutline) {
                    // Update the frame on the boundingBox view, and show it
                    [UIView animateWithDuration:0.2 animations:^{
                        laserView.alpha = 0.0;
                        boundingBox.frame = transformedObject.bounds;
                        boundingBox.alpha = 1.0;
                        boundingBox.corners = [self translatePoints:transformedObject.corners fromView:self toView:boundingBox];
                    }];
                    
                    [UIView animateWithDuration:0.5 delay:2.0 options:UIViewAnimationOptionCurveEaseOut animations:^{
                        laserView.alpha = 1.0;
                        boundingBox.alpha = 0.0;
                    } completion:nil];
                }
                
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

- (NSArray *)translatePoints:(NSArray *)points fromView:(UIView *)fromView toView:(UIView *)toView {
    NSMutableArray *translatedPoints = [NSMutableArray new];
    
    // The points are provided in a dictionary with keys X and Y
    for (NSDictionary *point in points) {
        // Let's turn them into CGPoints
        CGPoint pointValue = CGPointMake([point[@"X"] floatValue], [point[@"Y"] floatValue]);
        
        // Now translate from one view to the other
        CGPoint translatedPoint = [fromView convertPoint:pointValue toView:toView];
        
        // Box them up and add to the array
        [translatedPoints addObject:[NSValue valueWithCGPoint:translatedPoint]];
    }
    
    return [translatedPoints copy];
}

-(void)setScannerViewOrientation:(UIDeviceOrientation)toDeviceOrientation
{
    if (previewLayer) {
        [[previewLayer connection] setVideoOrientation:(AVCaptureVideoOrientation)[[UIDevice currentDevice] orientation]];
    }
}

@end
