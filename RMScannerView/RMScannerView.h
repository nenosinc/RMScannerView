//
//  RMScannerView.h
//  RMScannerView
//
//  Created by iRare Media on 12/3/13.
//  Copyright (c) 2014 iRare Media. All rights reserved.
//


#if __has_feature(objc_modules)
    // We recommend enabling Objective-C Modules in your project Build Settings for numerous benefits over regular #imports. Read more from the Modules documentation: http://clang.llvm.org/docs/Modules.html
    @import Foundation;
    @import UIKit;
    @import AVFoundation;
#else
    #import <Foundation/Foundation.h>
    #import <UIKit/UIKit.h>
    #import <AVFoundation/AVFoundation.h>
#endif

#if !__has_feature(objc_arc)
    // Add the -fobjc-arc flag to enable ARC for only these files, as described in the ARC documentation: http://clang.llvm.org/docs/AutomaticReferenceCounting.html
    #error RMScannerView is built with Objective-C ARC. You must enable ARC for these files.
#endif

#ifndef __IPHONE_7_0
    #error RMScannerView is built with features only available is iOS SDK 7.0 and later.
#endif


#import "RMOutlineBox.h"


@class RMScannerView;
@protocol RMScannerViewDelegate;

/** A UIView subclass for scanning and reading barcodes.
 Quickly and efficiently scans a large variety of barcodes using the device's built in hardware */
NS_CLASS_AVAILABLE_IOS(7_0) @interface RMScannerView : UIView <AVCaptureMetadataOutputObjectsDelegate>

@property (strong) AVCaptureSession *captureSession;

/// Verbose logging prints extra messages to the log which explains what's going on
@property BOOL verboseLogging;

/// Display scanner animations - red scan line moving up and down and stops when a barcode is found
@property BOOL animateScanner;

/// Display code outline - red box appears around barcode when it is detected - disappears after inactivity. Only appears if the delegate method, \p shouldEndSessionAfterFirstSuccessfulScan returns NO.
@property BOOL displayCodeOutline;

/// Scanner line color used for scanner animations
@property UIColor *scannerLineColor UI_APPEARANCE_SELECTOR;

/// The RMScannerView delegate object used to set the delegate. The delegate reports scan data, errors, and requests information from the delegate.
@property (nonatomic, weak) IBOutlet id <RMScannerViewDelegate> delegate;

/** Checks if a scan session is in progress
 @return YES if a scan session is currently in progress. NO if either a scan session or a capture session are not in progress. */
- (BOOL)isScanSessionInProgress;

/** Checks if a capture session is in progress
 @return YES if a capture session is currently in progress. NO a capture session is not in progress. May return YES even if a scan session is \b not in progress. */
- (BOOL)isCaptureSessionInProgress;

/** Starts the current barcode scanner capture session
 @discussion This method should be called when the encapsulating UIViewController is presented or is loaded, or at any appropriate time. A session will not automatically start when the RMScannerView is loaded (ex. by an interface file). Calling this method begins the AVCaptureSession and starts the collection of camera data - including scan data. */
- (void)startCaptureSession;

/** Starts a new scanning session and keeps the same capture session (or creates a new one if none exist)
 @discussion This method can be called to start a new scanning session after one has been stopped (ex. automatically after a scan). This will start a new stream of scan data. */
- (void)startScanSession;

/** Stops the current barcode scan. This only prevents the scan data from being read. It will not stop any video feed or halt any animations.
 @discussion This method should be called when a scan has completed (if continuous scans are not enabled) but the scanner is still visible on screen. */
- (void)stopScanSession;

/** Stops the current barcode scanner capture session. This causes the video feed to freeze, animations to halt, and prevents the scan data from being read.
 @discussion This method should be called when the encapsulating UIViewController is dismissed, unloaded, or deallocated. Calling this method stops the AVCaptureSession and prevents the collection of any further camera or hardware data - including scan data. It will also remove any animations on the view. */
- (void)stopCaptureSession;

/** Converts the \p codeType passed in the \p didScanCode:onCodeType: delegate method to a human readable barcode type name
 @param codeType The AVMetadataObjectType string passed in the \p didScanCode:onCodeType: delegate method, or any AVMetadataObjectType barcode string.
 @return A human-friendly barcode type name. May return \p nil if the barcode type is not recognized */
- (NSString *)humanReadableCodeTypeForCode:(NSString *)codeType;

/** Set the flash mode for the current scan session. Ending a scan session turns off the flash automatically.
 @param flashMode The AVCaptureFlashMode which specifies the flash mode, ON, OFF, or AUTO. */
- (void)setDeviceFlash:(AVCaptureFlashMode)flashMode;

@end

@class RMScannerView;

/** The delegate object for the scanner reports all errors and scans, it also retieves data from the delegate about how the scanner should behave. */
@protocol RMScannerViewDelegate <NSObject>

@required

/** Sent to the delegate when a barcode is successfully scanned
 @param scannedCode The readable scanned barcode string
 @param codeType The type of barcode which was scanned */
- (void)didScanCode:(NSString *)scannedCode onCodeType:(NSString *)codeType;

/** Sent to the delegate when the scanner fails to properly setup the scan session. This usually occurs because it was started on a device without a camera. A possible solution would be to present the user with a prompt to manually enter the barcode text.
 @param error The relevant error object containg the error code, solutions, and reasons. */
- (void)errorGeneratingCaptureSession:(NSError *)error;

@optional

/** Sent to the delegate when the user taps to focus and the scanner fails to attain a hardware lock on the users device. A hardware lock must be attained in order to focus the device camera at the point where the user tapped.
 @param error The relevant error object containg the error code, solutions, and reasons. */
- (void)errorAcquiringDeviceHardwareLock:(NSError *)error;

/** Sent to the delegate when the scanner needs to know if it should stop scanning, or continously scan until the \p stopCaptureSession method is called.
 @discussion If YES is returned by this method, the scan session is ended, but the capture session will continue. You must call \p stopCaptureSession manually.
 @return YES if the scanner should stop looking for barcodes and reporting them after the first successful scan. NO if the scanner should continuously scan for barcodes - this may result in a constant stream of data from the \p didScanCode:onCodeType method. */
- (BOOL)shouldEndSessionAfterFirstSuccessfulScan;

@end
