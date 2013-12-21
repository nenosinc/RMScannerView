<img width=725 src="https://raw.github.com/iRareMedia/UIScannerView/master/ScanBanner.png"/>

Simple barcode scanner UIView subclass for iOS apps. Quickly and efficiently scans a large variety of barcodes using the iOS device's built in camera.

UIScannerView is a UIView subclass for scanning barcodes in iOS applications. UIScannerView uses advanced barcode scanning built specifically for iOS. Scan both 2D and 1D barcodes such as PDF417, QR, Aztec, EAN, UPC, Code 128, etc. Get a barcode scanner up and running in your iOS app in only a few minutes.

If you like the project, please [star it](https://github.com/iRareMedia/UIScannerView) on GitHub! Watch the project on GitHub for updates. If you use UIScannerView in your app, send an email to contact@iraremedia.com or let us know on Twitter @iRareMedia.

# Project Features
UIScannerView is a great way to integrate barcode scanning in your iOS app. Below are a few key project features and highlights.
* Scan Aztec, Code 128, Code 39, Code 39 Mod 43, Code 93, EAN13, EAN8, PDF417, QR, and UPCE codes.  
* Use the iOS device's native hardware / camera and corresponding AVFoundation classes  
* Supports tap-to-focus, auto focus, and various other AVCaptureSession features  
* Setup only takes a few minutes and can be done almost entirely in interface files  
* Access in-depth documentation, code comments, and verbose logging  
* Delegate methods, properties, and methods give you complete control over your scan  
* iOS Sample-app demonstrates how to quickly and easily setup a UIScannerView  
* Frequent updates to the project based on user issues and requests  
* Easily contribute to the project

# Project Information
Learn more about the project requirements, licensing, and contributions.

## Requirements
Requires Xcode 5.0.1 for use in any iOS Project. Requires a minimum of iOS 7.0 as the deployment target. Works with and is optimized for ARC and 64-bit Architecture (arm64).  
* Supported build target - iOS 7.0  (Xcode 5.0.1, Apple LLVM compiler 5.0)  
* Earliest supported deployment target - iOS 7.0  
* Earliest compatible deployment target - iOS 7.0  

NOTE: 'Supported' means that the library has been tested with this version. 'Compatible' means that the library should work on this OS version (i.e. it doesn't rely on any unavailable SDK features) but is no longer being tested for compatibility and may require tweaking or bug fixes to run correctly.

## License 
You are free to make changes and use this in either personal or commercial projects. Attribution is not required, but it appreciated. A little *Thanks!* (or something to that affect) would be much appreciated. If you use UIScannerView in your app, send an email to contact@iraremedia.com or let us know on Twitter @iRareMedia. See the [full UIScannerView license here](https://github.com/iRareMedia/UIScannerView/blob/master/LICENSE.md).

## Contributions
Any contribution is more than welcome! You can contribute through pull requests and issues on GitHub. Learn more [about contributing to the project here](https://github.com/iRareMedia/UIScannerView/blob/master/CONTRIBUTING.md).

## Sample App
The iOS Sample App included with this project demonstrates how to setup and use many of the features in UIScannerView.

# Documentation
All methods, properties, types, and delegate methods available on the UIScannerView class are documented below. If you're using [Xcode 5](https://developer.apple.com/technologies/tools/whats-new.html) with UIScannerView, documentation is available directly within Xcode (just Option-Click any method for Quick Help).

## Setup
Adding UIScannerView to your project is easy. Follow these steps below to get everything up and running.
  
  1. Add the `UIScannerView.h` and `UIScannerView.m` files into your project  
  2. Import where necessary, `#import "UIScannerView.h"`  
  3. Setup the UIScannerView when your UIViewController or view loads:

        [scannerView setVerboseLogging:YES]; // Set verbose logging to YES so we can see exactly what's going on
        [scannerView startCaptureSession]; // Start the capture session when the view loads - this will also start a scan session

  4. Add a UIView to the corresponding / desired View Controller and set the view's custom class to `UIScannerView`  
  5. Subscribe to the `UIScannerView` delegate either through the interface (using the outlets inspector) or through code by subscribing to the `UIScannerViewDelegate` and then setting it.

## Sessions
UIScannerView manages barcode scanning in *sessions* which can be started or stopped at anytime. There are various session levels, each having a slightly different effect which is suitable for a different period. The **capture session** is the encompassing session which includes the stream of camera data, scan data, and any animations on the view.  The **scan session** is part of the capture session. It includes only the scan data. A scan session can be stopped separate of the capture session.

## Methods
There are many methods available on UIScannerView. The most important / highlight methods are documented below. All other methods are documented in the header file and with in-code comments. You should not attempt to use methods which are not listed in the header file.

### Starting a Capture Session
Starts the current barcode scanner capture session. This method should be called when the encapsulating UIViewController is presented or is loaded, or at any appropriate time. A session will not automatically start when the UIScannerView is loaded (ex. by an interface file). Calling this method begins the AVCaptureSession and starts the collection of camera data - including scan data.

    [scannerView startCaptureSession];

### Starting a Scan Session
Starts a new scanning session and keeps the same capture session (or creates a new one if none exist). This method can be called to start a new scanning session after one has been stopped (ex. automatically after a scan). This will start a new stream of scan data.

    [scannerView startScanSession];
    
You do not need to start both a scan and capture session at the same time. They are mutually inclusive. Starting a scan session will start a capture session if one does not exist or is stopped. Starting a capture session will also start a scan session. **However**, capture sessions differ from scan sessions in that they are more of an initializer - they do extra setup work and checks that may not be necessary if one is already started.

### Stopping a Scan Session
Stops the current barcode scan. This only prevents the scan data collection. It will not stop any video feed or halt any animations. This method may be called when a scan has completed (if continuous scans are not enabled) but the scanner is still visible on screen.

    [scannerView stopScanSession];
    
### Ending a Capture Session
Stops the current barcode scanner capture session. This causes the video feed to freeze, animations to halt, and prevents the scan data collection. This method should be called when the encapsulating UIViewController is dismissed, unloaded, or deallocated. Calling this method stops the AVCaptureSession and prevents the collection of any further camera or hardware data - including scan data. It will also remove any animations on the view.

    [scannerView stopCaptureSession];

### Checking for Sessions
Check if a scan session is in progress. Returns YES if a scan session is currently in progress. NO if either a scan session or a capture session are not in progress.

    BOOL isScanning = [scannerView isScanSessionInProgress];
    
Check if a capture session is in progress. Return YES if a capture session is currently in progress. NO a capture session is not in progress. May return YES even if a scan session is **not** in progress.

    BOOL isCapturing = [scannerView isCaptureSessionInProgress];

### Parsing Scan Data
If needed, you can display the scanned barcode format to your user with this method. It converts the `codeType` object passed in the `didScanCode:onCodeType:` delegate method to a human readable barcode type name. The `codeType` is an AVMetadataObjectType string passed in the `didScanCode:onCodeType:` delegate method, or any AVMetadataObjectType barcode string. Returns a human-friendly barcode type name. May return `nil` if the barcode type is not recognized.

    NSString *barcodeType = [scannerView humanReadableCodeTypeForCode:codeType];

### Camera Flash
Turn the camera flash to ON, OFF, or AUTO for the current scan session.

    [scannerView setDeviceFlash:AVCaptureFlashMode];

## Delegates
The most important part of the UIScannerView is it's delegate. Information is sent to the delegate about scanned barcodes. Requests are also sent to the delegate to gather preferences and settings. Error messages may also be sent to the delegate.

### Gathering Scan Data
When a barcode is recognized and scanned, this delegate method is called. You can use this delegate method to retrieve scan information such as the barcode data and barcode type. This method may be continuously called if the `shouldEndSessionAfterFirstSuccessfulScan` delegate method returns NO.

    - (void)didScanCode:(NSString *)scannedCode onCodeType:(NSString *)codeType;

### Registering for Errors
There are two types of errors that may occur when trying to setup or scan. 

The first is a capture session error - a required delegate method. It is sent to the delegate when the scanner fails to properly setup the scan session. This usually occurs because it was started on a device without a camera. A possible solution would be to present the user with a prompt to manually enter the barcode text.

    - (void)errorGeneratingCaptureSession:(NSError *)error;

The second is a device hardware lock error - an optional delegate method. It is sent to the delegate when the scanner cannot acquire a hardware lock in order to change configurations. This usually occurs when the user taps-to-focus. This may occur because another running application or process has a lock on the hardware configuration which prevents the scanner from focusing the camera.

    - (void)errorAcquiringDeviceHardwareLock:(NSError *)error;

### Session Settings
After a barcode is scanned, the scanner must decide to continuously send data to the delegate or to stop sending information after the first successful scan. Use this delegate to specify whether data should continue to be sent or just sent once. Continuous data means that `didScanCode:onCodeType:` delegate is called repeatedly until the barcode disappears or is no longer readable. 

Return YES if the scanner should stop looking for barcodes and reporting them after the first successful scan. NO if the scanner should continuously scan for barcodes. Leaving this delegate method unimplemented will result in the same action as returning YES.

    - (BOOL)shouldEndSessionAfterFirstSuccessfulScan;