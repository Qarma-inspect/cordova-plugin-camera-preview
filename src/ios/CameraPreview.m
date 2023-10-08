#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>
#import <UIKit/UIKit.h>
#import <ImageIO/ImageIO.h>
#import <MobileCoreServices/MobileCoreServices.h>
#import "AppDelegate.h"

#import "CameraPreview.h"

@implementation CameraPreview

-(void) pluginInitialize{
  // start as transparent
  self.webView.opaque = NO;
  self.webView.backgroundColor = [UIColor clearColor];
}

- (void) startCamera:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera already started!"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    return;
  }

  if (command.arguments.count > 3) {
    CGFloat x = (CGFloat)[command.arguments[0] floatValue] + self.webView.frame.origin.x;
    CGFloat y = (CGFloat)[command.arguments[1] floatValue] + self.webView.frame.origin.y;
    CGFloat width = (CGFloat)[command.arguments[2] floatValue];
    CGFloat height = (CGFloat)[command.arguments[3] floatValue];
    NSString *defaultCamera = command.arguments[4];
    BOOL tapToTakePicture = (BOOL)[command.arguments[5] boolValue];
    BOOL dragEnabled = (BOOL)[command.arguments[6] boolValue];
    BOOL toBack = (BOOL)[command.arguments[7] boolValue];
    CGFloat alpha = (CGFloat)[command.arguments[8] floatValue];
    BOOL tapToFocus = (BOOL) [command.arguments[9] boolValue];

    // Create the session manager
    self.sessionManager = [[CameraSessionManager alloc] init];
    self.sessionManager.frame = CGRectMake(x, y, width, height);

    // render controller setup
    self.cameraRenderController = [[CameraRenderController alloc] init];
    self.cameraRenderController.dragEnabled = dragEnabled;
    self.cameraRenderController.tapToTakePicture = tapToTakePicture;
    self.cameraRenderController.tapToFocus = tapToFocus;
    self.cameraRenderController.sessionManager = self.sessionManager;
    self.cameraRenderController.view.frame = CGRectMake(x, y, width, height);
    self.cameraRenderController.delegate = self;

    [self.viewController addChildViewController:self.cameraRenderController];

    if (toBack) {
      // display the camera below the webview

      // make transparent
      self.webView.opaque = NO;
      self.webView.backgroundColor = [UIColor clearColor];

      [self.webView.superview addSubview:self.cameraRenderController.view];
      [self.webView.superview bringSubviewToFront:self.webView];
    } else {
      self.cameraRenderController.view.alpha = alpha;
      [self.webView.superview insertSubview:self.cameraRenderController.view aboveSubview:self.webView];
    }

    // Setup session
    self.sessionManager.delegate = self.cameraRenderController;

    [self.sessionManager setupSession:defaultCamera completion:^(BOOL started) {

      [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];

    }];

  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid number of parameters"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

- (void) getCameraInfoRotation:(CDVInvokedUrlCommand*)command {
    CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsInt:0];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setCameraParameterResolution:(CDVInvokedUrlCommand*)command {
  CDVPluginResult * pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"iOS ignores this setting deliberately, just use takePicture({width,height})"];
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) stopCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"stopCamera");
  CDVPluginResult *pluginResult;

  if(self.sessionManager != nil) {
    [self.cameraRenderController.view removeFromSuperview];
    [self.cameraRenderController removeFromParentViewController];

    self.cameraRenderController = nil;
    self.sessionManager = nil;

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  }
  else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) hideCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"hideCamera");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != nil) {
    [self.cameraRenderController.view setHidden:YES];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) showCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"showCamera");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != nil) {
    [self.cameraRenderController.view setHidden:NO];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) switchCamera:(CDVInvokedUrlCommand*)command {
  NSLog(@"switchCamera");
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    [self.sessionManager switchCamera:^(BOOL switched) {

      [self.commandDelegate sendPluginResult:[CDVPluginResult resultWithStatus:CDVCommandStatus_OK] callbackId:command.callbackId];

    }];

  } else {

    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

- (void) getSupportedFocusModes:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * focusModes = [self.sessionManager getFocusModes];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:focusModes];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getFocusMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSString * focusMode = [self.sessionManager getFocusMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:focusMode];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setFocusMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  NSString * focusMode = [NSString stringWithFormat:@"%@", [command.arguments objectAtIndex:0]];
  if (self.sessionManager != nil) {
    [self.sessionManager setFocusMode:focusMode];
    NSString * focusMode = [self.sessionManager getFocusMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:focusMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getSupportedFlashModes:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * flashModes = [self.sessionManager getFlashModes];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:flashModes];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getFlashMode:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSInteger flashMode = [self.sessionManager getFlashMode];
    NSString * sFlashMode;
    if (flashMode == 0) {
      sFlashMode = @"off";
    } else if (flashMode == 1) {
      sFlashMode = @"on";
    } else if (flashMode == 2) {
      sFlashMode = @"auto";
    } else {
      sFlashMode = @"unsupported";
    }
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:sFlashMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setFlashMode:(CDVInvokedUrlCommand*)command {
  NSLog(@"Flash Mode");
  NSString *errMsg;
  CDVPluginResult *pluginResult;

  NSString *flashMode = [command.arguments objectAtIndex:0];

  if (self.sessionManager != nil) {
    if ([flashMode isEqual: @"off"]) {
      [self.sessionManager setFlashMode:AVCaptureFlashModeOff];
    } else if ([flashMode isEqual: @"on"]) {
      [self.sessionManager setFlashMode:AVCaptureFlashModeOn];
    } else if ([flashMode isEqual: @"auto"]) {
      [self.sessionManager setFlashMode:AVCaptureFlashModeAuto];
    } else if ([flashMode isEqual: @"torch"]) {
      [self.sessionManager setTorchMode];
    } else {
      errMsg = @"Flash Mode not supported";
    }
  } else {
    errMsg = @"Session not started";
  }

  if (errMsg) {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:errMsg];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setZoom:(CDVInvokedUrlCommand*)command {
  NSLog(@"Zoom");
  CDVPluginResult *pluginResult;

  CGFloat desiredZoomFactor = [[command.arguments objectAtIndex:0] floatValue];

  if (self.sessionManager != nil) {
    [self.sessionManager setZoom:desiredZoomFactor];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getZoom:(CDVInvokedUrlCommand*)command {

  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    CGFloat zoom = [self.sessionManager getZoom];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:zoom ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getMaxZoom:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    CGFloat maxZoom = [self.sessionManager getMaxZoom];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:maxZoom ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getExposureModes:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * exposureModes = [self.sessionManager getExposureModes];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:exposureModes];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getExposureMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSString * exposureMode = [self.sessionManager getExposureMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:exposureMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setExposureMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  NSString * exposureMode = [command.arguments objectAtIndex:0];
  if (self.sessionManager != nil) {
    [self.sessionManager setExposureMode:exposureMode];
    NSString * exposureMode = [self.sessionManager getExposureMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:exposureMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getSupportedWhiteBalanceModes:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * whiteBalanceModes = [self.sessionManager getSupportedWhiteBalanceModes];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:whiteBalanceModes ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getWhiteBalanceMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSString * whiteBalanceMode = [self.sessionManager getWhiteBalanceMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:whiteBalanceMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setWhiteBalanceMode:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  NSString * whiteBalanceMode = [command.arguments objectAtIndex:0];
  if (self.sessionManager != nil) {
    [self.sessionManager setWhiteBalanceMode:whiteBalanceMode];
    NSString * wbMode = [self.sessionManager getWhiteBalanceMode];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:wbMode ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getExposureCompensationRange:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    NSArray * exposureRange = [self.sessionManager getExposureCompensationRange];
    NSMutableDictionary *dimensions = [[NSMutableDictionary alloc] init];
    [dimensions setValue:exposureRange[0] forKey:@"min"];
    [dimensions setValue:exposureRange[1] forKey:@"max"];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDictionary:dimensions];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }
  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getExposureCompensation:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  if (self.sessionManager != nil) {
    CGFloat exposureCompensation = [self.sessionManager getExposureCompensation];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:exposureCompensation ];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) setExposureCompensation:(CDVInvokedUrlCommand*)command {
  NSLog(@"Zoom");
  CDVPluginResult *pluginResult;

  CGFloat exposureCompensation = [[command.arguments objectAtIndex:0] floatValue];

  if (self.sessionManager != nil) {
    [self.sessionManager setExposureCompensation:exposureCompensation];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsDouble:exposureCompensation];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) takePictureToFile:(CDVInvokedUrlCommand *)command {
    NSLog(@"take Picture to file.");

    if (self.cameraRenderController != NULL) {
        //self.onPictureTakenHandlerId = command.callbackId;

        CGFloat width = (CGFloat)[command.arguments[0] floatValue];
        CGFloat height = (CGFloat)[command.arguments[1] floatValue];
        CGFloat quality = (CGFloat)[command.arguments[2] floatValue] / 100.0f;
        NSString * fileName = command.arguments[3];
        double rotation = (double) [command.arguments[4] doubleValue];

        [self invokeTakePicture:width
                     withHeight:height
                    withQuality:quality
                   withFileName:fileName
                  rotateDegrees:rotation
                 withCallbackId:command.callbackId];
    } else {
        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
    }
}

- (void) takePicture:(CDVInvokedUrlCommand*)command {
  NSLog(@"takePicture");
  CDVPluginResult *pluginResult;

  if (self.cameraRenderController != NULL) {
    self.onPictureTakenHandlerId = command.callbackId;

    CGFloat width = (CGFloat)[command.arguments[0] floatValue];
    CGFloat height = (CGFloat)[command.arguments[1] floatValue];
    CGFloat quality = (CGFloat)[command.arguments[2] floatValue] / 100.0f;

    [self invokeTakePicture:width withHeight:height withQuality:quality];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Camera not started"];
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
  }
}

-(void) setColorEffect:(CDVInvokedUrlCommand*)command {
  NSLog(@"setColorEffect");
  CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  NSString *filterName = command.arguments[0];

  if(self.sessionManager != nil){
    if ([filterName isEqual: @"none"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          [self.sessionManager setCiFilter:nil];
          });
    } else if ([filterName isEqual: @"mono"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          CIFilter *filter = [CIFilter filterWithName:@"CIColorMonochrome"];
          [filter setDefaults];
          [self.sessionManager setCiFilter:filter];
          });
    } else if ([filterName isEqual: @"negative"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          CIFilter *filter = [CIFilter filterWithName:@"CIColorInvert"];
          [filter setDefaults];
          [self.sessionManager setCiFilter:filter];
          });
    } else if ([filterName isEqual: @"posterize"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          CIFilter *filter = [CIFilter filterWithName:@"CIColorPosterize"];
          [filter setDefaults];
          [self.sessionManager setCiFilter:filter];
          });
    } else if ([filterName isEqual: @"sepia"]) {
      dispatch_async(self.sessionManager.sessionQueue, ^{
          CIFilter *filter = [CIFilter filterWithName:@"CISepiaTone"];
          [filter setDefaults];
          [self.sessionManager setCiFilter:filter];
          });
    } else {
      pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Filter not found"];
    }
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

// TODO this function probably does not work correctly anymore, as the
// preview layers size is set once, and does not react to this change.
- (void) setPreviewSize: (CDVInvokedUrlCommand*)command {

    CDVPluginResult *pluginResult;

    if (self.sessionManager == nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
        return;
    }

    if (command.arguments.count > 1) {
        CGFloat width = (CGFloat)[command.arguments[0] floatValue];
        CGFloat height = (CGFloat)[command.arguments[1] floatValue];

        self.cameraRenderController.view.frame = CGRectMake(0, 0, width, height);

        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Invalid number of parameters"];
    }

    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void) getSupportedPictureSizes:(CDVInvokedUrlCommand*)command {
  NSLog(@"getSupportedPictureSizes");
  CDVPluginResult *pluginResult;

  if(self.sessionManager != nil){
    NSArray *formats = self.sessionManager.getDeviceFormats;
    NSMutableArray *jsonFormats = [NSMutableArray new];
    int lastWidth = 0;
    int lastHeight = 0;
    for (AVCaptureDeviceFormat *format in formats) {
      CMVideoDimensions dim = format.highResolutionStillImageDimensions;
      if (dim.width!=lastWidth && dim.height != lastHeight) {
        NSMutableDictionary *dimensions = [[NSMutableDictionary alloc] init];
        NSNumber *width = [NSNumber numberWithInt:dim.width];
        NSNumber *height = [NSNumber numberWithInt:dim.height];
        [dimensions setValue:width forKey:@"width"];
        [dimensions setValue:height forKey:@"height"];
        [jsonFormats addObject:dimensions];
        lastWidth = dim.width;
        lastHeight = dim.height;
      }
    }
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:jsonFormats];

  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (NSString *)getBase64Image:(CGImageRef)imageRef withQuality:(CGFloat) quality {
  NSString *base64Image = nil;

  @try {
    UIImage *image = [UIImage imageWithCGImage:imageRef];
    NSData *imageData = UIImageJPEGRepresentation(image, quality);
    base64Image = [imageData base64EncodedStringWithOptions:0];
  }
  @catch (NSException *exception) {
    NSLog(@"error while get base64Image: %@", [exception reason]);
  }

  return base64Image;
}

- (void) tapToFocus:(CDVInvokedUrlCommand*)command {
  CDVPluginResult *pluginResult;

  CGFloat xPoint = [[command.arguments objectAtIndex:0] floatValue];
  CGFloat yPoint = [[command.arguments objectAtIndex:1] floatValue];

  if (self.sessionManager != nil) {
    [self.sessionManager tapToFocus:xPoint yPoint:yPoint];
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK];
  } else {
    pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Session not started"];
  }

  [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (double)radiansFromUIImageOrientation:(UIImageOrientation)orientation {
  switch ([[UIApplication sharedApplication] statusBarOrientation]) {
    case UIDeviceOrientationPortrait:
      return M_PI_2;
    case UIDeviceOrientationLandscapeLeft:
      return 0.f;
    case UIDeviceOrientationLandscapeRight:
      return M_PI;
    case UIDeviceOrientationPortraitUpsideDown:
      return -M_PI_2;
    case UIDeviceOrientationUnknown:
      return 0.f;
    default:
      return 0.f;
  }
}

- (void) invokeTapToFocus:(CGPoint)point {
  [self.sessionManager tapToFocus:point.x yPoint:point.y];
}

- (void) invokeTakePicture {
  [self invokeTakePicture:0.0 withHeight:0.0 withQuality:0.85];
}

- (void) invokeTakePictureOnFocus {
    // the sessionManager will call onFocus, as soon as the camera is done with focussing.
  [self.sessionManager takePictureOnFocus];
}

- (CGImageRef) resizeAndRotateImage:(CFDataRef) capturedImage maxPixelSize:(CGFloat) maxPixelSize rotationAngle: (int) rotationAngle {
    NSOperatingSystemVersion info = [[NSProcessInfo processInfo] operatingSystemVersion];
    NSInteger majorVersion = info.majorVersion;
    if(majorVersion < 17) {
        return [self resizeAndRotateImageOnVersionLessThan17:capturedImage maxPixelSize:maxPixelSize rotationAngle:rotationAngle];
    } else {
        return [self resizeAndRotateImageOnVersionGreaterThan17:capturedImage maxPixelSize:maxPixelSize rotationAngle:rotationAngle];
    }
}

- (CGImageRef) resizeAndRotateImageOnVersionLessThan17:(CFDataRef) capturedImage maxPixelSize:(CGFloat) maxPixelSize rotationAngle: (int) rotationAngle {

    CGImageSourceRef imageSource = CGImageSourceCreateWithData(capturedImage, nil);
    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
        (id) kCGImageSourceCreateThumbnailWithTransform: @YES,
        (id) kCGImageSourceCreateThumbnailFromImageAlways : @YES,
        (id) kCGImageSourceThumbnailMaxPixelSize : @(maxPixelSize),
        (id) kCGImagePropertyOrientation: @(rotationAngle)
    };
    CGImageRef thumbnail = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options);
    CFRelease(imageSource);
    return thumbnail;
}

- (CGImageRef) resizeAndRotateImageOnVersionGreaterThan17:(CFDataRef) capturedImage maxPixelSize:(CGFloat) maxPixelSize rotationAngle: (int) rotationAngle {
    CGImageSourceRef imageSource = CGImageSourceCreateWithData(capturedImage, nil);
    CFDictionaryRef properties = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, NULL);
    CGImageRef image = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
    CFRelease(imageSource);
    
    switch (rotationAngle) {
        case kCGImagePropertyOrientationUp:
        case kCGImagePropertyOrientationUpMirrored:
            return [self resizeAndRotatePortraitUpImage:image];
        case kCGImagePropertyOrientationDown:
        case kCGImagePropertyOrientationDownMirrored:
            return [self resizeAndRotatePortraitDownImage:image];
        case kCGImagePropertyOrientationLeft:
        case kCGImagePropertyOrientationLeftMirrored:
            return [self resizeAndRotateLandscapeLeftImage:image];
        default:
            return [self resizeAndRotateLandscapeRightImage:image];
    }
}

- (CGImageRef) resizeAndRotatePortraitUpImage:(CGImageRef) sourceImage {
    size_t imageWidth = CGImageGetWidth(sourceImage);
    size_t imageHeight = CGImageGetHeight(sourceImage);
    size_t targetWidth = 1200;
    size_t targetHeight = 1600;
    size_t biggerEdge = imageWidth > imageHeight ? imageWidth : imageHeight;
    size_t smallerEdge = imageWidth < imageHeight ? imageWidth : imageHeight;
    float scaleRatio = (float) targetHeight / biggerEdge;
    
    size_t bytesPerRow = biggerEdge * (CGImageGetBitsPerPixel(sourceImage) / 8);
    size_t rawDataSize = targetHeight * bytesPerRow;
    void * rawData = malloc(rawDataSize);
    
    CGContextRef bigContext = CGBitmapContextCreate(rawData, targetHeight, targetHeight, CGImageGetBitsPerComponent(sourceImage), bytesPerRow, CGImageGetColorSpace(sourceImage), CGImageGetBitmapInfo(sourceImage));
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, 0);
    transform = CGAffineTransformScale(transform, scaleRatio, scaleRatio);
    transform = CGAffineTransformTranslate(transform, 0, biggerEdge);
    transform = CGAffineTransformRotate(transform, -M_PI_2);
    
    CGContextConcatCTM(bigContext, transform);
    CGRect drawRect = CGRectMake(0, 0, imageWidth, imageHeight);
    
    CGContextDrawImage(bigContext, drawRect, sourceImage);
    CGContextRef finalImageContext = CGBitmapContextCreateWithData(rawData, targetWidth, targetHeight, CGImageGetBitsPerComponent(sourceImage), bytesPerRow, CGImageGetColorSpace(sourceImage), CGImageGetBitmapInfo(sourceImage), nil, nil);
    
    CGImageRef finalImage = CGBitmapContextCreateImage(finalImageContext);
    
    CGContextRelease(finalImageContext);
    CGContextRelease(bigContext);
    CFRelease(sourceImage);
    free(rawData);
    
    return finalImage;
}

- (CGImageRef) resizeAndRotatePortraitDownImage:(CGImageRef) sourceImage {
    size_t imageWidth = CGImageGetWidth(sourceImage);
    size_t imageHeight = CGImageGetHeight(sourceImage);
    size_t targetWidth = 1200;
    size_t targetHeight = 1600;
    size_t biggerEdge = imageWidth > imageHeight ? imageWidth : imageHeight;
    size_t smallerEdge = imageWidth < imageHeight ? imageWidth : imageHeight;
    float scaleRatio = (float) targetHeight / biggerEdge;
    
    size_t bytesPerRow = biggerEdge * (CGImageGetBitsPerPixel(sourceImage) / 8);

    void * rawData = malloc(targetHeight * bytesPerRow);
    
    CGContextRef bigContext = CGBitmapContextCreate(rawData, targetHeight, targetHeight, CGImageGetBitsPerComponent(sourceImage), bytesPerRow, CGImageGetColorSpace(sourceImage), CGImageGetBitmapInfo(sourceImage));
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, 0);
  
    transform = CGAffineTransformScale(transform, scaleRatio, scaleRatio);
    transform = CGAffineTransformTranslate(transform, smallerEdge, 0);
    transform = CGAffineTransformRotate(transform, M_PI_2);
    
    CGContextConcatCTM(bigContext, transform);
    CGRect drawRect = CGRectMake(0, 0, imageWidth, imageHeight);
    
    CGContextDrawImage(bigContext, drawRect, sourceImage);
    CGContextRef finalImageContext = CGBitmapContextCreateWithData(rawData, targetWidth, targetHeight, CGImageGetBitsPerComponent(sourceImage), bytesPerRow, CGImageGetColorSpace(sourceImage), CGImageGetBitmapInfo(sourceImage), nil, nil);
    
    CGImageRef finalImage = CGBitmapContextCreateImage(finalImageContext);
    
    CGContextRelease(finalImageContext);
    CGContextRelease(bigContext);
    free(rawData);
    CFRelease(sourceImage);
    
    return finalImage;
}

- (CGImageRef) resizeAndRotateLandscapeLeftImage:(CGImageRef) sourceImage {
    size_t imageWidth = CGImageGetWidth(sourceImage);
    size_t imageHeight = CGImageGetHeight(sourceImage);
    size_t targetWidth = 1600;
    size_t targetHeight = 1200;
    size_t biggerEdge = imageWidth > imageHeight ? imageWidth : imageHeight;
    float scaleRatio = (float) targetWidth / biggerEdge;
    
    size_t bytesPerRow = biggerEdge * (CGImageGetBitsPerPixel(sourceImage) / 8);

    void * rawData = malloc(targetWidth * bytesPerRow);
    
    CGContextRef bigContext = CGBitmapContextCreate(rawData, targetWidth, targetWidth, CGImageGetBitsPerComponent(sourceImage), bytesPerRow, CGImageGetColorSpace(sourceImage), CGImageGetBitmapInfo(sourceImage));
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, 0);
    transform = CGAffineTransformScale(transform, scaleRatio, scaleRatio);
    transform = CGAffineTransformTranslate(transform, biggerEdge, biggerEdge);
    transform = CGAffineTransformRotate(transform, M_PI);
    
    CGContextConcatCTM(bigContext, transform);
    CGRect drawRect = CGRectMake(0, 0, imageWidth, imageHeight);
    
    CGContextDrawImage(bigContext, drawRect, sourceImage);
    
    CGContextRef finalImageContext = CGBitmapContextCreateWithData(rawData, targetWidth, targetHeight, CGImageGetBitsPerComponent(sourceImage), bytesPerRow, CGImageGetColorSpace(sourceImage), CGImageGetBitmapInfo(sourceImage), nil, nil);
    
    CGImageRef finalImage = CGBitmapContextCreateImage(finalImageContext);
    
    CGContextRelease(finalImageContext);
    CGContextRelease(bigContext);
    free(rawData);
    CFRelease(sourceImage);
    
    return finalImage;
}

- (CGImageRef) resizeAndRotateLandscapeRightImage:(CGImageRef) sourceImage {
    size_t imageWidth = CGImageGetWidth(sourceImage);
    size_t imageHeight = CGImageGetHeight(sourceImage);
    size_t targetWidth = 1600;
    size_t targetHeight = 1200;
    size_t biggerEdge = imageWidth > imageHeight ? imageWidth : imageHeight;
    float scaleRatio = (float) targetWidth / biggerEdge;
    
    size_t bytesPerRow = targetWidth * (CGImageGetBitsPerPixel(sourceImage) / 8);
    
    CGAffineTransform transform = CGAffineTransformMakeTranslation(0, 0);
    transform = CGAffineTransformScale(transform, scaleRatio, scaleRatio);
    
    CGContextRef context = CGBitmapContextCreateWithData(NULL, targetWidth, targetHeight, CGImageGetBitsPerComponent(sourceImage), bytesPerRow, CGImageGetColorSpace(sourceImage), CGImageGetBitmapInfo(sourceImage), nil, nil);
    CGContextConcatCTM(context, transform);
    CGRect drawRect = CGRectMake(0, 0, imageWidth, imageHeight);
    CGContextDrawImage(context, drawRect, sourceImage);
    CGImageRef finalImage = CGBitmapContextCreateImage(context);
    
    CGContextRelease(context);
    CFRelease(sourceImage);
    
    return finalImage;
}

- (void) invokeTakePicture:(CGFloat) width
                withHeight:(CGFloat) height
               withQuality:(CGFloat) quality
              withFileName:(NSString *) fileName
             rotateDegrees:(double) rotation
            withCallbackId:(NSString *) callbackId {
    NSString * thumbnailFileName = [@"thumb-" stringByAppendingString:fileName];

    CFAbsoluteTime start = CFAbsoluteTimeGetCurrent();

    AVCaptureConnection *connection = [self.sessionManager.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
   
    [self.sessionManager.stillImageOutput captureStillImageAsynchronouslyFromConnection:(connection) completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {
        
        if (error) {
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:[NSString stringWithFormat:@"%@", error]];
            [self.commandDelegate sendPluginResult:pluginResult callbackId: callbackId];
            NSLog(@"%@", error);
            return;
        } else {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
            NSString* rootPath = paths[0];
            NSString* path = [rootPath stringByAppendingPathComponent:@"NoCloud"];
            NSString* fullPath = [path stringByAppendingFormat: @"/%@", fileName];
            NSString * thumbPath = [path stringByAppendingFormat: @"/%@", thumbnailFileName];

            CFAbsoluteTime dataCaptured = CFAbsoluteTimeGetCurrent();

            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            CFDataRef imgDataRef = (CFDataRef) CFBridgingRetain(imageData);
            int orientation = [self getRotationIndex:rotation];

            // resize, rotate and write image to disk
            CGImageRef capturedImageRef = [self resizeAndRotateImage:imgDataRef maxPixelSize:1600 rotationAngle:orientation];
            CGImageWriteToFile(capturedImageRef, fullPath, quality);
            CFRelease(capturedImageRef);

            // resize, rotate and write thumbnail image to disk
            CGImageRef thumbnailImageRef = [self resizeAndRotateImage:imgDataRef maxPixelSize:200 rotationAngle:orientation];
            CGImageWriteToFile(thumbnailImageRef, thumbPath, 1);
            CFRelease(thumbnailImageRef);

            NSError *writeError = nil;
            CFRelease(imgDataRef);

            CFAbsoluteTime imagesWrittenToDisk = CFAbsoluteTimeGetCurrent();

            NSMutableArray *params = [[NSMutableArray alloc] init];
            [params addObject:fileName];
            [params addObject:thumbnailFileName];
            [params addObject:@(start)];
            [params addObject:@(dataCaptured)];
            [params addObject:@(imagesWrittenToDisk)];

            if(writeError){
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error while writing files."];
                [self.commandDelegate sendPluginResult:pluginResult callbackId: callbackId];
                NSLog(@"%@", error);
            } else {
                CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:params];
                [self.commandDelegate sendPluginResult:pluginResult callbackId: callbackId];
            }
        }
    }];
}

void CGImageWriteToFile(CGImageRef image, NSString *path, CGFloat quality) {
    CFURLRef url = (__bridge CFURLRef) [NSURL fileURLWithPath:path];

    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, nil);

    CFDictionaryRef options = (__bridge CFDictionaryRef) @{
           (id) kCGImageDestinationLossyCompressionQuality: @(quality)
    };
    CGImageDestinationAddImage(destination, image, options);

    if (!CGImageDestinationFinalize(destination)) {
        NSLog(@"Failed to write image to %@", path);
    }

    CFRelease(destination);
}

- (int) getRotationIndex:(double) angle {
    if(angle == 0.0) {
        return kCGImagePropertyOrientationUp;
    } else if (angle == 90.0) {
        return kCGImagePropertyOrientationLeft;
    } else if (angle == 180.0) {
        return kCGImagePropertyOrientationDown;
    } else if (angle == 270.0) {
        return kCGImagePropertyOrientationRight;
    } else {
        return kCGImagePropertyOrientationUp;
    }
}
@end
