#import <Cordova/CDV.h>
#import <Cordova/CDVPlugin.h>
#import <Cordova/CDVInvokedUrlCommand.h>

#import "CameraSessionManager.h"
#import "CameraRenderController.h"

@interface CameraPreview : CDVPlugin <TakePictureDelegate, FocusDelegate>

- (void) startCamera:(CDVInvokedUrlCommand*)command;
- (void) stopCamera:(CDVInvokedUrlCommand*)command;
- (void) showCamera:(CDVInvokedUrlCommand*)command;
- (void) hideCamera:(CDVInvokedUrlCommand*)command;
- (void) getFocusMode:(CDVInvokedUrlCommand*)command;
- (void) setFocusMode:(CDVInvokedUrlCommand*)command;
- (void) getFlashMode:(CDVInvokedUrlCommand*)command;
- (void) setFlashMode:(CDVInvokedUrlCommand*)command;
- (void) setZoom:(CDVInvokedUrlCommand*)command;
- (void) getZoom:(CDVInvokedUrlCommand*)command;
- (void) getMaxZoom:(CDVInvokedUrlCommand*)command;
- (void) getExposureModes:(CDVInvokedUrlCommand*)command;
- (void) getExposureMode:(CDVInvokedUrlCommand*)command;
- (void) setExposureMode:(CDVInvokedUrlCommand*)command;
- (void) getExposureCompensation:(CDVInvokedUrlCommand*)command;
- (void) setExposureCompensation:(CDVInvokedUrlCommand*)command;
- (void) getExposureCompensationRange:(CDVInvokedUrlCommand*)command;
- (void) setPreviewSize: (CDVInvokedUrlCommand*)command;
- (void) switchCamera:(CDVInvokedUrlCommand*)command;
- (void) takePicture:(CDVInvokedUrlCommand*)command;
- (void) takePictureToFile:(CDVInvokedUrlCommand*)command;
- (void) setColorEffect:(CDVInvokedUrlCommand*)command;
- (void) getSupportedPictureSizes:(CDVInvokedUrlCommand*)command;
- (void) getSupportedFlashModes:(CDVInvokedUrlCommand*)command;
- (void) getSupportedFocusModes:(CDVInvokedUrlCommand*)command;
- (void) tapToFocus:(CDVInvokedUrlCommand*)command;
- (void) getSupportedWhiteBalanceModes:(CDVInvokedUrlCommand*)command;
- (void) getWhiteBalanceMode:(CDVInvokedUrlCommand*)command;
- (void) setWhiteBalanceMode:(CDVInvokedUrlCommand*)command;
- (void) getCameraInfoRotation:(CDVInvokedUrlCommand*)command;
- (void) setCameraParameterResolution:(CDVInvokedUrlCommand*)command;

- (void) invokeTakePicture:(CGFloat) width withHeight:(CGFloat) height withQuality:(CGFloat) quality;

- (void) invokeTakePicture:(CGFloat) width withHeight:(CGFloat) height withQuality:(CGFloat) quality withFileName:(NSString *) fileName rotateDegrees:(double) rotation;

- (void) invokeTakePicture;

- (void) invokeTapToFocus:(CGPoint) point;

- (void) captureOutput:(AVCapturePhotoOutput *)output didFinishProcessingPhoto:(AVCapturePhoto *)photo error:(nullable NSError *)error;

@property (nonatomic) CameraSessionManager *sessionManager;
@property (nonatomic) CameraRenderController *cameraRenderController;
@property (nonatomic) NSString *onPictureTakenHandlerId;
@property (nonatomic) NSString * _Nonnull commandId;
@property (nonatomic) NSString * _Nonnull targetFileName;
@property (nonatomic) int targetRotation;
@property (nonatomic) NSInteger iosVersion;
@property (nonatomic) CFAbsoluteTime startedTime;

@end