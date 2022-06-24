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

  NSString * focusMode = [[command.arguments objectAtIndex:0] stringValue];
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
  NSLog(@"tapToFocus");
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
  double radians;

  switch ([[UIApplication sharedApplication] statusBarOrientation]) {
    case UIDeviceOrientationPortrait:
      radians = M_PI_2;
      break;
    case UIDeviceOrientationLandscapeLeft:
      radians = 0.f;
      break;
    case UIDeviceOrientationLandscapeRight:
      radians = M_PI;
      break;
    case UIDeviceOrientationPortraitUpsideDown:
      radians = -M_PI_2;
      break;
  }

  return radians;
}

-(CGImageRef) CGImageRotated:(CGImageRef) originalCGImage withRadians:(double) radians {
  CGSize imageSize = CGSizeMake(CGImageGetWidth(originalCGImage), CGImageGetHeight(originalCGImage));
  CGSize rotatedSize;
  if (radians == M_PI_2 || radians == -M_PI_2) {
    rotatedSize = CGSizeMake(imageSize.height, imageSize.width);
  } else {
    rotatedSize = imageSize;
  }

  double rotatedCenterX = rotatedSize.width / 2.f;
  double rotatedCenterY = rotatedSize.height / 2.f;

  UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, 1.f);
  CGContextRef rotatedContext = UIGraphicsGetCurrentContext();
  if (radians == 0.f || radians == M_PI) { // 0 or 180 degrees
    CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
    if (radians == 0.0f) {
      CGContextScaleCTM(rotatedContext, 1.f, -1.f);
    } else {
      CGContextScaleCTM(rotatedContext, -1.f, 1.f);
    }
    CGContextTranslateCTM(rotatedContext, -rotatedCenterX, -rotatedCenterY);
  } else if (radians == M_PI_2 || radians == -M_PI_2) { // +/- 90 degrees
    CGContextTranslateCTM(rotatedContext, rotatedCenterX, rotatedCenterY);
    CGContextRotateCTM(rotatedContext, radians);
    CGContextScaleCTM(rotatedContext, 1.f, -1.f);
    CGContextTranslateCTM(rotatedContext, -rotatedCenterY, -rotatedCenterX);
  }

  CGRect drawingRect = CGRectMake(0.f, 0.f, imageSize.width, imageSize.height);
  CGContextDrawImage(rotatedContext, drawingRect, originalCGImage);
  CGImageRef rotatedCGImage = CGBitmapContextCreateImage(rotatedContext);

  UIGraphicsEndImageContext();

  return rotatedCGImage;
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

- (CIImage *) resizeImage:(CIImage *) imageToResize fromWidth:(CGFloat) fromWidth fromHeight:(CGFloat) fromHeight toWidth:(CGFloat) width toHeight:(CGFloat) height {
    if(width > 0 && height > 0 && fromWidth > 0 && fromHeight > 0){
        CGFloat scaleHeight = width/fromWidth;
        CGFloat scaleWidth = height/fromHeight;
        CGFloat scale = scaleHeight > scaleWidth ? scaleWidth : scaleHeight;

        CIFilter *resizeFilter = [CIFilter filterWithName:@"CIBicubicScaleTransform"];
        [resizeFilter setValue:imageToResize forKey:kCIInputImageKey];
        [resizeFilter setValue:[NSNumber numberWithFloat:1.0f] forKey:@"inputAspectRatio"];
        [resizeFilter setValue:[NSNumber numberWithFloat:scale] forKey:@"inputScale"];
        return [resizeFilter outputImage];
    } else {
        return imageToResize;
    }
}

- (CIImage * ) resizeImage:(UIImage *) capturedImage toWidth:(CGFloat) width toHeight:(CGFloat) height {

    CIImage * initialImage =[[CIImage alloc] initWithCGImage:[capturedImage CGImage]];

    CGFloat initialWidth = capturedImage.size.width;
    CGFloat initialHeight = capturedImage.size.height;

    return [self resizeImage:initialImage fromWidth:initialWidth fromHeight:initialHeight toWidth:width toHeight:height];
}

- (CGImageRef) resizeImageSource:(CFDataRef) capturedImage maxPixelSize:(CGFloat) maxPixelSize rotationAngle: (int) rotationAngle {
    
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

- (CIImage * ) fixFrontCameraMirror: (CIImage * ) capturedImage forCamera:(AVCaptureDevicePosition)camera {
    if (camera == AVCaptureDevicePositionFront) {
        CGAffineTransform matrix = CGAffineTransformTranslate(CGAffineTransformMakeScale(1, -1), 0, capturedImage.extent.size.height);
        return [capturedImage imageByApplyingTransform:matrix];
    } else {
        return capturedImage;
    }
}

- (CIImage *) filterImage : (CIImage * ) imageToFilter {
    CIFilter *filter = [self.sessionManager ciFilter];
    if (filter != nil) {
        [self.sessionManager.filterLock lock];
        [filter setValue:imageToFilter forKey:kCIInputImageKey];
        CIImage * finalCImage = [filter outputImage];
        [self.sessionManager.filterLock unlock];
        return finalCImage;
    } else {
        return imageToFilter;
    }
}

- (CGImageRef) rotateImage:(CIImage * ) finalCImage withDegrees:(double) additionalDegrees {
    CGImageRef finalImage = [self.cameraRenderController.ciContext createCGImage:finalCImage fromRect:finalCImage.extent];
    UIImage *resultImage = [UIImage imageWithCGImage:finalImage];

    // rotate the image, such that it lines up with the screen.
    double radians = [self radiansFromUIImageOrientation:resultImage.imageOrientation];

    //
    double degreesToRadians = [self evenAngleInDegreesToRadians:additionalDegrees];
    double additionOfAngles = [self addEvenAnglesInRadians:degreesToRadians to:radians];

    CGImageRef resultFinalImage = [self CGImageRotated:finalImage withRadians:additionOfAngles];

    CGImageRelease(finalImage); // release CGImageRef to remove memory leaks
    return resultFinalImage;
}

/**
 Input must be one of 0.0, 90, 180, 270, 360, -90, -180, -270

 Returns one of 0.0, M_PI_2, M_PI, -M_PI_2;
 **/
- (double) evenAngleInDegreesToRadians:(double) degrees{
    if(degrees == 0.0 || degrees == 360){
        return 0.0;
    } else if(degrees == 90 || degrees == -270){
        return M_PI_2;
    } else if(degrees == 180 || degrees == -180) {
        return M_PI;
    } else if (degrees == 270 || degrees == -90) {
        return -M_PI_2;
    } else {
        return 0.0;
    }
}

/**
 Both inputs must be one of 0.0, M_PI_2, M_PI, -M_PI_2

 Returns one of 0.0, M_PI_2, M_PI, -M_PI_2
 **/
- (double) addEvenAnglesInRadians:(double) radians1 to:(double) radians2 {
    if(radians2 == 0.0){
        return radians1;
    }

    if (radians1 == 0.0){
        return radians2;
    } else if (radians1 == -M_PI_2) {

        if(radians2 == -M_PI_2){
            return M_PI;
        } else if ( radians2 == M_PI_2) {
            return 0.0;
        } else if ( radians2 == M_PI) {
            return M_PI_2;
        } else {
            return -M_PI_2;
        }

    } else if (radians1 == M_PI) {

        if(radians2 == -M_PI_2){
            return M_PI_2;
        } else if (radians2 == M_PI_2) {
            return -M_PI_2;
        } else if (radians2 == M_PI){
            return 0.0;
        } else {
            return M_PI;
        }

    } else if (radians1 == M_PI_2){

        if(radians2 == -M_PI_2){
            return 0;
        } else if (radians2 == M_PI_2){
            return M_PI;
        } else if (radians2 == M_PI){
            return -M_PI_2;
        } else {
            return M_PI_2;
        }

    } else {
        return 0.0;
    }
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
            CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Error after calling captureStillImage."];
            [self.commandDelegate sendPluginResult:pluginResult callbackId: callbackId];
            NSLog(@"%@", error);
            return;
        } else {
            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
            NSString* rootPath = paths[0];
            NSString* path = [rootPath stringByAppendingPathComponent:@"NoCloud"];
            NSString* fullPath = [path stringByAppendingFormat: @"/%@", fileName];
            NSString * thumbPath = [path stringByAppendingFormat: @"/%@", thumbnailFileName];
            NSLog(@"%@", path);
            NSLog(@"%@", thumbPath);
            
            CFAbsoluteTime dataCaptured = CFAbsoluteTimeGetCurrent();
            
            NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
            CFDataRef imgDataRef = (CFDataRef) CFBridgingRetain(imageData);
            int orientation = [self getRotationIndex:rotation];
            
            // resize, rotate and write image to disk
            CGImageRef capturedImageRef = [self resizeImageSource:imgDataRef maxPixelSize:1600 rotationAngle:orientation];
            CGImageWriteToFile(capturedImageRef, fullPath);
            CFRelease(capturedImageRef);
            
            // resize, rotate and write thumbnail image to disk
            CGImageRef thumbnailImageRef = [self resizeImageSource:imgDataRef maxPixelSize:200 rotationAngle:orientation];
            CGImageWriteToFile(thumbnailImageRef, thumbPath);
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
                // [pluginResult setKeepCallbackAsBool:true];
                [self.commandDelegate sendPluginResult:pluginResult callbackId: callbackId];
            }
        }
    }];
}

void CGImageWriteToFile(CGImageRef image, NSString *path) {
    CFURLRef url = (__bridge CFURLRef) [NSURL fileURLWithPath:path];
    CGImageDestinationRef destination = CGImageDestinationCreateWithURL(url, kUTTypeJPEG, 1, nil);
    
    CGImageDestinationAddImage(destination, image, nil);

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

- (void) invokeTakePicture:(CGFloat) width withHeight:(CGFloat) height withQuality:(CGFloat) quality{
    AVCaptureConnection *connection = [self.sessionManager.stillImageOutput connectionWithMediaType:AVMediaTypeVideo];
    [self.sessionManager.stillImageOutput captureStillImageAsynchronouslyFromConnection:(connection) completionHandler:^(CMSampleBufferRef sampleBuffer, NSError *error) {

      NSLog(@"Done creating still image");

      if (error) {
        NSLog(@"%@", error);
      } else {
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:sampleBuffer];
        UIImage *capturedImage  = [[UIImage alloc] initWithData:imageData];
        CIImage *capturedCImage = [self resizeImage:capturedImage toWidth:width toHeight:height];

        CIImage *imageToFilter = [self fixFrontCameraMirror:capturedCImage forCamera:self.sessionManager.defaultCamera];
        CIImage *finalCImage = [self filterImage:imageToFilter];
        
        CGImageRef resultFinalImage = [self rotateImage:finalCImage withDegrees:0.0];

        NSString *base64Image = [self getBase64Image:resultFinalImage withQuality:quality];

        CGImageRelease(resultFinalImage); // release CGImageRef to remove memory leaks

        NSMutableArray *params = [[NSMutableArray alloc] init];
        [params addObject:base64Image];

        CDVPluginResult *pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsArray:params];
        // [pluginResult setKeepCallbackAsBool:true];
        [self.commandDelegate sendPluginResult:pluginResult callbackId:self.onPictureTakenHandlerId];
      }
    }];
}
@end
