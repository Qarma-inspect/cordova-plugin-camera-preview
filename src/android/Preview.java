package com.cordovaplugincamerapreview;

import android.app.Activity;
import android.content.Context;
import android.graphics.ImageFormat;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.hardware.Camera;
import android.util.DisplayMetrics;
import android.util.Log;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.View;
import android.widget.RelativeLayout;
import org.apache.cordova.LOG;
import android.view.TextureView.SurfaceTextureListener;
import android.view.TextureView;
import android.graphics.SurfaceTexture;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.util.List;

class Preview extends RelativeLayout implements TextureView.SurfaceTextureListener {
  private final String TAG = "Preview";

  TextureView mSurfaceView;
  SurfaceHolder mHolder;
  Camera.Size mPreviewSize;
  List<Camera.Size> mSupportedPreviewSizes;
  Camera mCamera;
  int cameraId;
  int displayOrientation;
  int viewWidth;
  int viewHeight;

  Preview(Context context) {
    super(context);

    mSurfaceView = new TextureView(context);
    mSurfaceView.setSurfaceTextureListener(this);
    addView(mSurfaceView);

    requestLayout();
  }

  public void onSurfaceTextureAvailable(SurfaceTexture surface, int width, int height) {
    try {
      if(mCamera != null) {
        // Now that the size is known, set up the camera parameters and begin
        // the preview.
        mSupportedPreviewSizes = mCamera.getParameters().getSupportedPreviewSizes();
        if (mSupportedPreviewSizes != null) {
          mPreviewSize = getOptimalPreviewSize(mSupportedPreviewSizes, width, height);
        }
        Camera.Parameters parameters = mCamera.getParameters();
        parameters.setPreviewSize(mPreviewSize.width, mPreviewSize.height);
        requestLayout();
        mCamera.setParameters(parameters);
        mCamera.setPreviewTexture(surface);

        mCamera.startPreview();
      }
    } catch (Exception e) {
        e.printStackTrace();
    }
  }

  public void onSurfaceTextureSizeChanged(SurfaceTexture surface, int width, int height) {
    // Ignored, Camera does all the work for us
  }

  public boolean onSurfaceTextureDestroyed(SurfaceTexture surface) {
    try {
      if (mCamera != null) {
        mCamera.stopPreview();
      }
    } catch (Exception exception) {
      Log.e(TAG, "Exception caused by surfaceDestroyed()", exception);
    }
    return true;
  }

  public void onSurfaceTextureUpdated(SurfaceTexture surface) {
    // Invoked every time there's a new Camera preview frame
  }

  public void setCamera(Camera camera, int cameraId) {
    mCamera = camera;
    this.cameraId = cameraId;
    if (camera != null) {
      mSupportedPreviewSizes = mCamera.getParameters().getSupportedPreviewSizes();
      setCameraDisplayOrientation();

      List<String> mFocusModes = mCamera.getParameters().getSupportedFocusModes();

      Camera.Parameters params = mCamera.getParameters();
      if (mFocusModes.contains("continuous-picture")) {
        params.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_PICTURE);
      } else if (mFocusModes.contains("continuous-video")){
        params.setFocusMode(Camera.Parameters.FOCUS_MODE_CONTINUOUS_VIDEO);
      } else if (mFocusModes.contains("auto")){
        params.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
      }
      mCamera.setParameters(params);
    }
  }

  public int getDisplayOrientation() {
    return displayOrientation;
  }

  public void printPreviewSize(String from) {
    Log.d(TAG, "printPreviewSize from " + from + ": > width: " + mPreviewSize.width + " height: " + mPreviewSize.height);
  }
  public void setCameraPreviewSize() {
    if (mCamera != null) {
      Camera.Parameters parameters = mCamera.getParameters();
      parameters.setPreviewSize(mPreviewSize.width, mPreviewSize.height);
      mCamera.setParameters(parameters);
    }
  }

  public int getCorrectedOrientation() {
    Camera.CameraInfo info = new Camera.CameraInfo();
    int rotation = ((Activity) getContext()).getWindowManager().getDefaultDisplay().getRotation();
    int degrees = 0;
    int result;

    //DisplayMetrics dm = new DisplayMetrics();

    Camera.getCameraInfo(cameraId, info);
    //((Activity) getContext()).getWindowManager().getDefaultDisplay().getMetrics(dm);

    switch (rotation) {
      case Surface.ROTATION_0:
        degrees = 0;
        break;
      case Surface.ROTATION_90:
        degrees = 90;
        break;
      case Surface.ROTATION_180:
        degrees = 180;
        break;
      case Surface.ROTATION_270:
        degrees = 270;
        break;
    }

    if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
      result = (info.orientation + degrees) % 360;
      result = (360 - result) % 360;
    } else {
      result = (info.orientation - degrees + 360) % 360;
    }

    Log.d(TAG, "screen is rotated " + degrees + "deg from natural");
    Log.d(TAG, (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT ? "front" : "back") + " camera is oriented -" + info.orientation + "deg from natural");
    Log.d(TAG, "need to rotate preview " + result + "deg");
    return result;
  }

  private void setCameraDisplayOrientation() {
    displayOrientation = getCorrectedOrientation();
    mCamera.setDisplayOrientation(displayOrientation);
  }

  public void switchCamera(Camera camera, int cameraId) {
    try {
      setCamera(camera, cameraId);

      Log.d("CameraPreview", "before set camera");

      camera.setPreviewDisplay(mHolder);

      Log.d("CameraPreview", "before getParameters");

      Camera.Parameters parameters = camera.getParameters();

      Log.d("CameraPreview", "before setPreviewSize");

      mSupportedPreviewSizes = parameters.getSupportedPreviewSizes();
      mPreviewSize = getOptimalPreviewSize(mSupportedPreviewSizes, mSurfaceView.getWidth(), mSurfaceView.getHeight());
      parameters.setPreviewSize(mPreviewSize.width, mPreviewSize.height);
      Log.d(TAG, mPreviewSize.width + " " + mPreviewSize.height);

      camera.setParameters(parameters);
    } catch (IOException exception) {
      Log.e(TAG, exception.getMessage());
    }
  }

  @Override
  protected void onMeasure(int widthMeasureSpec, int heightMeasureSpec) {
    // We purposely disregard child measurements because act as a
    // wrapper to a SurfaceView that centers the camera preview instead
    // of stretching it.
    final int width = resolveSize(getSuggestedMinimumWidth(), widthMeasureSpec);
    final int height = resolveSize(getSuggestedMinimumHeight(), heightMeasureSpec);
    setMeasuredDimension(width, height);

    if (mSupportedPreviewSizes != null) {
      mPreviewSize = getOptimalPreviewSize(mSupportedPreviewSizes, width, height);
    }
  }

  @Override
  protected void onLayout(boolean changed, int l, int t, int r, int b) {

    if (changed && getChildCount() > 0) {
      final View child = getChildAt(0);

      int width = r - l;
      int height = b - t;

      int previewWidth = width;
      int previewHeight = height;

      if (mPreviewSize != null) {
        previewWidth = mPreviewSize.width;
        previewHeight = mPreviewSize.height;

        if(displayOrientation == 90 || displayOrientation == 270) {
          previewWidth = mPreviewSize.height;
          previewHeight = mPreviewSize.width;
        }

        LOG.d(TAG, "previewWidth:" + previewWidth + " previewHeight:" + previewHeight);
      }

      int nW;
      int nH;
      int top;
      int left;

      float scale = 1.0f;

      // Center the child SurfaceView within the parent.
      if (width * previewHeight < height * previewWidth) {
        Log.d(TAG, "center horizontally");
        int scaledChildWidth = (int)((previewWidth * height / previewHeight) * scale);
        nW = (width + scaledChildWidth) / 2;
        nH = (int)(height * scale);
        top = 0;
        left = (width - scaledChildWidth) / 2;
      } else {
        Log.d(TAG, "center vertically");
        int scaledChildHeight = (int) ((previewHeight * width / previewWidth) * scale);
        nW = (int) (width * scale);
        nH = (height + scaledChildHeight) / 2;
        top = (height - scaledChildHeight) / 2;
        left = 0;
      }
      child.layout(left, top, nW, nH);

      Log.d("layout", "left:" + left);
      Log.d("layout", "top:" + top);
      Log.d("layout", "right:" + nW);
      Log.d("layout", "bottom:" + nH);
    }
  }

  private Camera.Size getOptimalPreviewSize(List<Camera.Size> sizes, int w, int h) {
    final double ASPECT_TOLERANCE = 0.1;
    double targetRatio = (double) w / h;
    if (displayOrientation == 90 || displayOrientation == 270) {
      targetRatio = (double) h / w;
    }

    if(sizes == null){
      return null;
    }

    Camera.Size optimalSize = null;
    double minDiff = Double.MAX_VALUE;

    int targetHeight = 1200;
    int targetWidth = 1600;
    int targetResolution = targetHeight * targetWidth;

    // Try to find an size match aspect ratio and size
    for (Camera.Size size : sizes) {
      double ratio = (double) size.width / size.height;
      if (Math.abs(ratio - targetRatio) > ASPECT_TOLERANCE) continue;
      if (Math.abs(size.height * size.width - targetResolution) < minDiff) {
        optimalSize = size;
        minDiff = Math.abs(size.height * size.width - targetResolution);
      }
    }

    // Cannot find the one match the aspect ratio, ignore the requirement
    if (optimalSize == null) {
      minDiff = Double.MAX_VALUE;
      for (Camera.Size size : sizes) {
        if (Math.abs(size.height * size.width - targetResolution) < minDiff) {
          optimalSize = size;
          minDiff = Math.abs(size.height * size.width - targetResolution);
        }
      }
    }

    Log.d(TAG, "optimal preview size: w: " + optimalSize.width + " h: " + optimalSize.height);
    return optimalSize;
  }

  public void setOneShotPreviewCallback(Camera.PreviewCallback callback) {
    if(mCamera != null) {
      mCamera.setOneShotPreviewCallback(callback);
    }
  }
}
