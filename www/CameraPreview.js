var argscheck = require('cordova/argscheck'),
    utils = require('cordova/utils'),
    exec = require('cordova/exec');

var PLUGIN_NAME = "CameraPreview";

var CameraPreview = function() {};

function isFunction(obj) {
    return !!(obj && obj.constructor && obj.call && obj.apply);
};

CameraPreview.startCamera = function(options, onSuccess, onError) {
    options = options || {};
    options.x = options.x || 0;
    options.y = options.y || 0;
    options.width = options.width || window.screen.width;
    options.height = options.height || window.screen.height;
    options.camera = options.camera || CameraPreview.CAMERA_DIRECTION.FRONT;
    if (typeof(options.tapPhoto) === 'undefined') {
        options.tapPhoto = true;
    }

    if (typeof (options.tapFocus) == 'undefined') {
        options.tapFocus = false;
    }

    options.previewDrag = options.previewDrag || false;
    options.toBack = options.toBack || false;
    if (typeof(options.alpha) === 'undefined') {
        options.alpha = 1;
    }

    exec(onSuccess, onError, PLUGIN_NAME, "startCamera", [options.x, options.y, options.width, options.height, options.camera, options.tapPhoto, options.previewDrag, options.toBack, options.alpha, options.tapFocus]);
};

CameraPreview.getCameraInfoRotation = function(cameraName, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getCameraInfoRotation", [cameraName]);
}

CameraPreview.setCameraParameterResolution = function(width, height, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "setCameraParameterResolution", [width, height]);
}

CameraPreview.stopCamera = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "stopCamera", []);
};

CameraPreview.switchCamera = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "switchCamera", []);
};

CameraPreview.hide = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "hideCamera", []);
};

CameraPreview.show = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "showCamera", []);
};

CameraPreview.takePictureToFile = function(opts, onSuccess, onError) {
    if (!opts) {
        opts = {};
    } else if (isFunction(opts)) {
        onSuccess = opts;
        opts = {};
    }

    if (!isFunction(onSuccess)) {
        return false;
    }

    opts.width = opts.width || 0;
    opts.height = opts.height || 0;

    if (!opts.quality || opts.quality > 100 || opts.quality < 0) {
        opts.quality = 85;
    }

    var fileName = opts.fileName || "tempFile.jpg";

    if(typeof opts.orientation == "undefined" || opts.orientation == null){
        opts.orientation = 0;
    }

    exec(
        onSuccess,
        onError,
        PLUGIN_NAME,
        "takePictureToFile",
        [
            opts.width,
            opts.height,
            opts.quality,
            fileName,
            opts.orientation,
        ]);
};

CameraPreview.takePicture = function(opts, onSuccess, onError) {
    if (!opts) {
        opts = {};
    } else if (isFunction(opts)) {
        onSuccess = opts;
        opts = {};
    }

    if (!isFunction(onSuccess)) {
        return false;
    }

    opts.width = opts.width || 0;
    opts.height = opts.height || 0;

    if (!opts.quality || opts.quality > 100 || opts.quality < 0) {
        opts.quality = 85;
    }

    if(typeof opts.orientation == "undefined" || opts.orientation == null){
        opts.orientation = 0;
    }

    exec(onSuccess, onError, PLUGIN_NAME, "takePicture", [opts.width, opts.height, opts.quality]);
};

CameraPreview.setColorEffect = function(effect, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "setColorEffect", [effect]);
};

CameraPreview.setZoom = function(zoom, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "setZoom", [zoom]);
};

CameraPreview.getMaxZoom = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getMaxZoom", []);
};

CameraPreview.getZoom = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getZoom", []);
};

CameraPreview.setPreviewSize = function(dimensions, onSuccess, onError) {
    dimensions = dimensions || {};
    dimensions.width = dimensions.width || window.screen.width;
    dimensions.height = dimensions.height || window.screen.height;

    exec(onSuccess, onError, PLUGIN_NAME, "setPreviewSize", [dimensions.width, dimensions.height]);
};

CameraPreview.getSupportedPictureSizes = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getSupportedPictureSizes", []);
};

CameraPreview.getSupportedPreviewSizes = function(onSucces, onError) {
  exec(onSucces, onError, PLUGIN_NAME, "getSupportedPreviewSizes", []);
};

CameraPreview.getSupportedFlashModes = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getSupportedFlashModes", []);
};

CameraPreview.setFlashMode = function(flashMode, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "setFlashMode", [flashMode]);
};

CameraPreview.getFlashMode = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getFlashMode", []);
};

CameraPreview.getSupportedFocusModes = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getSupportedFocusModes", []);
};

CameraPreview.getFocusMode = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getFocusMode", []);
};

CameraPreview.setFocusMode = function(focusMode, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "setFocusMode", [focusMode]);
};

CameraPreview.tapToFocus = function(xPoint, yPoint, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "tapToFocus", [xPoint, yPoint]);
};


CameraPreview.getExposureModes = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getExposureModes", []);
};

CameraPreview.getExposureMode = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getExposureMode", []);
};

CameraPreview.setExposureMode = function(exposureMode, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "setExposureMode", [exposureMode]);
};

CameraPreview.getExposureCompensation = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getExposureCompensation", []);
};

CameraPreview.setExposureCompensation = function(exposureCompensation, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "setExposureCompensation", [exposureCompensation]);
};

CameraPreview.getExposureCompensationRange = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getExposureCompensationRange", []);
};

CameraPreview.getSupportedWhiteBalanceModes = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getSupportedWhiteBalanceModes", []);
};

CameraPreview.getWhiteBalanceMode = function(onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "getWhiteBalanceMode", []);
};

CameraPreview.setWhiteBalanceMode = function(whiteBalanceMode, onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "setWhiteBalanceMode", [whiteBalanceMode]);
};

CameraPreview.startRecordVideo = function (opts, onSuccess, onError) {
    if (!opts) {
      opts = {};
    } else if (isFunction(opts)) {
      onSuccess = opts;
      opts = {};
    }
  
    if (!isFunction(onSuccess)) {
      return false;
    }
  
    opts.width = opts.width || 0;
    opts.height = opts.height || 0;
  
    if (!opts.quality || opts.quality > 100 || opts.quality < 0) {
      opts.quality = 85;
    }
  
    exec(onSuccess, onError, PLUGIN_NAME, "startRecordVideo", [opts.fileName, opts.cameraDirection, opts.rotation, opts.width, opts.height, opts.quality, opts.withFlash]);
};
  
CameraPreview.stopRecordVideo = function (onSuccess, onError) {
    exec(onSuccess, onError, PLUGIN_NAME, "stopRecordVideo");
};

CameraPreview.FOCUS_MODE = {
    FIXED: 'fixed',
    AUTO: 'auto',
    CONTINUOUS: 'continuous', // IOS Only
    CONTINUOUS_PICTURE: 'continuous-picture', // Android Only
    CONTINUOUS_VIDEO: 'continuous-video', // Android Only
    EDOF: 'edof', // Android Only
    INFINITY: 'infinity', // Android Only
    MACRO: 'macro' // Android Only
};

CameraPreview.EXPOSURE_MODE = {
    LOCK: 'lock',
    AUTO: 'auto', // IOS Only
    CONTINUOUS: 'continuous', // IOS Only
    CUSTOM: 'custom' // IOS Only
};

CameraPreview.WHITE_BALANCE_MODE = {
    LOCK: 'lock',
    AUTO: 'auto',
    CONTINUOUS: 'continuous',
    INCANDESCENT: 'incandescent',
    CLOUDY_DAYLIGHT: 'cloudy-daylight',
    DAYLIGHT: 'daylight',
    FLUORESCENT: 'fluorescent',
    SHADE: 'shade',
    TWILIGHT: 'twilight',
    WARM_FLUORESCENT: 'warm-fluorescent'
};

CameraPreview.FLASH_MODE = {
    OFF: 'off',
    ON: 'on',
    AUTO: 'auto',
    RED_EYE: 'red-eye', // Android Only
    TORCH: 'torch'
};

CameraPreview.COLOR_EFFECT = {
    AQUA: 'aqua', // Android Only
    BLACKBOARD: 'blackboard', // Android Only
    MONO: 'mono',
    NEGATIVE: 'negative',
    NONE: 'none',
    POSTERIZE: 'posterize',
    SEPIA: 'sepia',
    SOLARIZE: 'solarize', // Android Only
    WHITEBOARD: 'whiteboard' // Android Only
};

CameraPreview.CAMERA_DIRECTION = {
    BACK: 'back',
    FRONT: 'front'
};

module.exports = CameraPreview;
