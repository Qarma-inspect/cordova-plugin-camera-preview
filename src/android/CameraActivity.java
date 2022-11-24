package com.cordovaplugincamerapreview;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.pm.ActivityInfo;
import android.app.Fragment;
import android.content.Context;
import android.content.pm.PackageManager;
import android.graphics.Bitmap;
import android.graphics.Bitmap.CompressFormat;
import android.media.AudioManager;
import android.os.AsyncTask;
import android.os.Build;
import android.util.Base64;
import android.graphics.BitmapFactory;
import android.graphics.Canvas;
import android.graphics.ImageFormat;
import android.graphics.Matrix;
import android.graphics.Rect;
import android.graphics.YuvImage;
import android.os.Bundle;
import android.util.Log;
import android.util.DisplayMetrics;
import android.view.Display;
import android.view.WindowManager;
import android.view.GestureDetector;
import android.view.Gravity;
import android.view.LayoutInflater;
import android.view.MotionEvent;
import android.view.Surface;
import android.view.SurfaceHolder;
import android.view.SurfaceView;
import android.view.View;
import android.view.ViewGroup;
import android.view.ViewTreeObserver;
import android.widget.FrameLayout;
import android.widget.ImageView;
import android.widget.RelativeLayout;
import android.hardware.Camera;
import android.hardware.Camera.PictureCallback;
import android.hardware.Camera.ShutterCallback;
import android.hardware.Camera.CameraInfo;
import androidx.exifinterface.media.ExifInterface;

import org.apache.cordova.LOG;
import org.apache.cordova.CordovaWebView;

import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.FileOutputStream;
import java.io.IOException;
import java.lang.Exception;
import java.lang.Integer;
import java.text.SimpleDateFormat;
import java.util.Calendar;
import java.util.Date;
import java.util.List;
import java.util.Arrays;
import java.util.Locale;
import java.util.concurrent.Executors;
import android.media.MediaRecorder;
import android.media.CamcorderProfile;

public class CameraActivity extends Fragment {

  public interface CameraPreviewListener {
    void onPictureTaken(String originalPicture);

    void onPictureTakenToFile(String pathToFile, String pathToThumbnail);

    void onPictureTakenError(String message);

    void onFocusSet(int pointX, int pointY);

    void onFocusSetError(String message);

    void onCameraStarted();

    void onCameraStartedError(String message);
      void onStartRecordVideo();
      void onStartRecordVideoError(String message);
      void onStopRecordVideo(String file);
      void onStopRecordVideoError(String error);
  }

  private CameraPreviewListener eventListener;
  private static final String TAG = "CameraActivity";
  public FrameLayout mainLayout;
  public FrameLayout frameContainerLayout;

  private Preview mPreview;
  private boolean canTakePicture = true;

  private View view;
  private Camera.Parameters cameraParameters;
  private Camera mCamera;
  private int numberOfCameras;
  private int cameraCurrentlyLocked;
  private int currentQuality;

  // The first rear facing camera
  private int defaultCameraId;
  public String defaultCamera;
  public boolean tapToTakePicture;
  public boolean dragEnabled;
  public boolean tapToFocus;

  public int width;
  public int height;
  public int x;
  public int y;
  private enum RecordingState {INITIALIZING, STARTED, STOPPED};
  private RecordingState mRecordingState = RecordingState.INITIALIZING;
  private MediaRecorder mRecorder = null;
  private String recordFilePath;
  private CordovaWebView cordovaWebView;


  public void setEventListener(CameraPreviewListener listener) {
    eventListener = listener;
  }

  private String appResourcesPackage;

  @Override
  public View onCreateView(LayoutInflater inflater, ViewGroup container, Bundle savedInstanceState) {
    appResourcesPackage = getActivity().getPackageName();

    // Inflate the layout for this fragment
    view = inflater.inflate(getResources().getIdentifier("camera_activity", "layout", appResourcesPackage), container, false);
    createCameraPreview();
    return view;
  }

  public void setRect(int x, int y, int width, int height) {
    this.x = x;
    this.y = y;
    this.width = width;
    this.height = height;
  }

  private void createCameraPreview() {
    if (mPreview == null) {
      setDefaultCameraId();

      //set box position and size
      FrameLayout.LayoutParams layoutParams = new FrameLayout.LayoutParams(width, height);
      layoutParams.setMargins(x, y, 0, 0);
      frameContainerLayout = (FrameLayout) view.findViewById(getResources().getIdentifier("frame_container", "id", appResourcesPackage));
      frameContainerLayout.setLayoutParams(layoutParams);

      //video view
      mPreview = new Preview(getActivity());
      mainLayout = (FrameLayout) view.findViewById(getResources().getIdentifier("video_view", "id", appResourcesPackage));
      mainLayout.setLayoutParams(new RelativeLayout.LayoutParams(RelativeLayout.LayoutParams.MATCH_PARENT, RelativeLayout.LayoutParams.MATCH_PARENT));
      mainLayout.addView(mPreview);
      mainLayout.setEnabled(false);

      final GestureDetector gestureDetector = new GestureDetector(getActivity().getApplicationContext(), new TapGestureDetector());

      getActivity().runOnUiThread(new Runnable() {
        @Override
        public void run() {
          frameContainerLayout.setClickable(true);
          frameContainerLayout.setOnTouchListener(new View.OnTouchListener() {

            private int mLastTouchX;
            private int mLastTouchY;
            private int mPosX = 0;
            private int mPosY = 0;

            @Override
            public boolean onTouch(View v, MotionEvent event) {
              FrameLayout.LayoutParams layoutParams = (FrameLayout.LayoutParams) frameContainerLayout.getLayoutParams();
              final int viewWidth = (int) v.getWidth();
              final int viewHeight = (int) v.getHeight();

              boolean isSingleTapTouch = gestureDetector.onTouchEvent(event);
              if (event.getAction() != MotionEvent.ACTION_MOVE && isSingleTapTouch) {
                if (tapToTakePicture && tapToFocus) {
                  Log.d(TAG, "Touch at " + ((int) event.getX(0)) + ", " + ((int) event.getY(0)));
                  setFocusArea(
                          (int) event.getX(0),
                          (int) event.getY(0),
                          new Camera.AutoFocusCallback() {
                            public void onAutoFocus(boolean success, Camera camera) {
                              if (success) {
                                takePicture(0, 0, 85);
                              } else {
                                Log.d(TAG, "onTouch:" + " setFocusArea() did not suceed");
                              }
                            }
                          },
                          viewWidth,
                          viewHeight
                  );

                } else if (tapToTakePicture) {
                  takePicture(0, 0, 85);

                } else if (tapToFocus) {
                  setFocusArea(
                          (int) event.getX(0),
                          (int) event.getY(0),
                          new Camera.AutoFocusCallback() {
                            public void onAutoFocus(boolean success, Camera camera) {
                              if (success) {
                                // A callback to JS might make sense here.
                              } else {
                                Log.d(TAG, "onTouch:" + " setFocusArea() did not suceed");
                              }
                            }
                          },
                          viewWidth,
                          viewHeight
                  );
                }
                return true;
              } else {
                if (dragEnabled) {
                  int x;
                  int y;

                  switch (event.getAction()) {
                    case MotionEvent.ACTION_DOWN:
                      if (mLastTouchX == 0 || mLastTouchY == 0) {
                        mLastTouchX = (int) event.getRawX() - layoutParams.leftMargin;
                        mLastTouchY = (int) event.getRawY() - layoutParams.topMargin;
                      } else {
                        mLastTouchX = (int) event.getRawX();
                        mLastTouchY = (int) event.getRawY();
                      }
                      break;
                    case MotionEvent.ACTION_MOVE:

                      x = (int) event.getRawX();
                      y = (int) event.getRawY();

                      final float dx = x - mLastTouchX;
                      final float dy = y - mLastTouchY;

                      mPosX += dx;
                      mPosY += dy;

                      layoutParams.leftMargin = mPosX;
                      layoutParams.topMargin = mPosY;

                      frameContainerLayout.setLayoutParams(layoutParams);

                      // Remember this touch position for the next move event
                      mLastTouchX = x;
                      mLastTouchY = y;

                      break;
                    default:
                      break;
                  }
                }
              }
              return true;
            }
          });
        }
      });
    }
  }

  private void setDefaultCameraId() {
    // Find the total number of cameras available
    try {
        numberOfCameras = Camera.getNumberOfCameras();
        int camId = defaultCamera.equals("front") ? Camera.CameraInfo.CAMERA_FACING_FRONT : Camera.CameraInfo.CAMERA_FACING_BACK;
        // Find the ID of the default camera
        Camera.CameraInfo cameraInfo = new Camera.CameraInfo();
        for (int i = 0; i < numberOfCameras; i++) {
            Camera.getCameraInfo(i, cameraInfo);
            if (cameraInfo.facing == camId) {
                defaultCameraId = camId;
                break;
            }
        }
    } catch (Exception e) {
        Log.d(TAG, e.getMessage());
        e.printStackTrace();
    }
  }

  @Override
  public void onResume() {
    super.onResume();
    try {
        mCamera = Camera.open(defaultCameraId);
        if(mCamera == null) {
          eventListener.onCameraStartedError("Cannot access CameraService");
        } else {
            if (cameraParameters != null) {
                mCamera.setParameters(cameraParameters);
            }

            cameraCurrentlyLocked = defaultCameraId;

            if (mPreview.mPreviewSize == null) {
                mPreview.setCamera(mCamera, cameraCurrentlyLocked);
                eventListener.onCameraStarted();
            } else {
                mPreview.switchCamera(mCamera, cameraCurrentlyLocked);
                mCamera.startPreview();
            }

            Log.d(TAG, "cameraCurrentlyLocked:" + cameraCurrentlyLocked);

            final FrameLayout newFrameContainerLayout = (FrameLayout) view.findViewById(getResources().getIdentifier("frame_container", "id", appResourcesPackage));

            ViewTreeObserver viewTreeObserver = newFrameContainerLayout.getViewTreeObserver();

            if (viewTreeObserver.isAlive()) {
                viewTreeObserver.addOnGlobalLayoutListener(new ViewTreeObserver.OnGlobalLayoutListener() {
                    @Override
                    public void onGlobalLayout() {
                        try {
                            newFrameContainerLayout.getViewTreeObserver().removeGlobalOnLayoutListener(this);
                            newFrameContainerLayout.measure(View.MeasureSpec.UNSPECIFIED, View.MeasureSpec.UNSPECIFIED);
                            final RelativeLayout frameCamContainerLayout = (RelativeLayout) view.findViewById(getResources().getIdentifier("frame_camera_cont", "id", appResourcesPackage));

                            FrameLayout.LayoutParams camViewLayout = new FrameLayout.LayoutParams(newFrameContainerLayout.getWidth(), newFrameContainerLayout.getHeight());
                            camViewLayout.gravity = Gravity.CENTER_HORIZONTAL | Gravity.CENTER_VERTICAL;
                            frameCamContainerLayout.setLayoutParams(camViewLayout);
                        } catch (Exception e) {
                            Log.d(TAG, e.getMessage());
                            e.printStackTrace();
                        }
                    }
                });
            }
        }
    } catch (Exception e) {
        e.printStackTrace();
        Log.d(TAG, e.getMessage());
    }
  }

  @Override
  public void onPause() {
    super.onPause();

    if(mRecorder != null) {
      try {
        mRecorder.stop();
        mRecorder.reset();
        mRecorder.release();
        mRecorder = null;
      }
      catch (Exception e) {
        Log.d(TAG, "failed to stop media recorder");
      }
    }

    // Because the Camera object is a shared resource, it's very important to release it when the activity is paused.
    if (mCamera != null) {
//      setDefaultCameraId();
      mPreview.setCamera(null, -1);
      mCamera.setPreviewCallback(null);
      mCamera.release();
      mCamera = null;
    }
  }

  public Camera getCamera() {
    return mCamera;
  }

  public void switchCamera() {
    // check for availability of multiple cameras
    if (numberOfCameras == 1) {
      //There is only one camera available
    } else {
      Log.d(TAG, "numberOfCameras: " + numberOfCameras);

      // OK, we have multiple cameras. Release this camera -> cameraCurrentlyLocked
      if (mCamera != null) {
        mCamera.stopPreview();
        mPreview.setCamera(null, -1);
        mCamera.release();
        mCamera = null;
      }

      Log.d(TAG, "cameraCurrentlyLocked := " + Integer.toString(cameraCurrentlyLocked));
      try {
        cameraCurrentlyLocked = (cameraCurrentlyLocked + 1) % numberOfCameras;
        Log.d(TAG, "cameraCurrentlyLocked new: " + cameraCurrentlyLocked);
      } catch (Exception exception) {
        Log.d(TAG, exception.getMessage());
      }

      // Acquire the next camera and request Preview to reconfigure parameters.
      mCamera = Camera.open(cameraCurrentlyLocked);

      if (cameraParameters != null) {
        Log.d(TAG, "camera parameter not null");

        // Check for flashMode as well to prevent error on frontward facing camera.
        List<String> supportedFlashModesNewCamera = mCamera.getParameters().getSupportedFlashModes();
        String currentFlashModePreviousCamera = cameraParameters.getFlashMode();
        if (supportedFlashModesNewCamera != null && supportedFlashModesNewCamera.contains(currentFlashModePreviousCamera)) {
          Log.d(TAG, "current flash mode supported on new camera. setting params");
         /* mCamera.setParameters(cameraParameters);
            The line above is disabled because parameters that can actually be changed are different from one device to another. Makes less sense trying to reconfigure them when changing camera device while those settings gan be changed using plugin methods.
         */
        } else {
          Log.d(TAG, "current flash mode NOT supported on new camera");
        }

      } else {
        Log.d(TAG, "camera parameter NULL");
      }

      mPreview.switchCamera(mCamera, cameraCurrentlyLocked);

      mCamera.startPreview();
    }
  }

  public void setCameraParameters(Camera.Parameters params) {
    cameraParameters = params;

    if (mCamera != null && cameraParameters != null) {
      mCamera.setParameters(cameraParameters);
    }
  }

  public boolean hasFrontCamera() {
    return getActivity().getApplicationContext().getPackageManager().hasSystemFeature(PackageManager.FEATURE_CAMERA_FRONT);
  }

  public static Bitmap flipBitmap(Bitmap source) {
    Matrix matrix = new Matrix();
    matrix.preScale(1.0f, -1.0f);

    return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, true);
  }

  public static Bitmap applyMatrix(Bitmap source, Matrix matrix) {
      return Bitmap.createBitmap(source, 0, 0, source.getWidth(), source.getHeight(), matrix, true);
  }

  private static int exifToDegrees(int exifOrientation) {
      if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_90) { return 90; }
      else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_180) {  return 180; }
      else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_270) {  return 270; }
      return 0;
  }

  private static int exifToHorizontalDegrees(int exifOrientation) {
      if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_90) { return 90; }
      else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_180) {  return 0; }
      else if (exifOrientation == ExifInterface.ORIENTATION_ROTATE_270) {  return 270; }
      return 180;
  }

  ShutterCallback shutterCallback = new ShutterCallback() {
    public void onShutter() {
      // do nothing, availabilty of this callback causes default system shutter sound to work
    }
  };

  PictureCallback jpegPictureCallback = new PictureCallback() {
    public void onPictureTaken(byte[] data, Camera arg1) {
      Log.d(TAG, "CameraPreview jpegPictureCallback");

      try {

        if (cameraCurrentlyLocked == Camera.CameraInfo.CAMERA_FACING_FRONT) {
          Bitmap bitmap = BitmapFactory.decodeByteArray(data, 0, data.length);
          bitmap = flipBitmap(bitmap);

          ByteArrayOutputStream outputStream = new ByteArrayOutputStream();
          bitmap.compress(Bitmap.CompressFormat.JPEG, currentQuality, outputStream);
          data = outputStream.toByteArray();
        }

        String encodedImage = Base64.encodeToString(data, Base64.NO_WRAP);

        eventListener.onPictureTaken(encodedImage);
        Log.d(TAG, "CameraPreview pictureTakenHandler called back");
      } catch (OutOfMemoryError e) {
        // most likely failed to allocate memory for rotateBitmap
        Log.d(TAG, "CameraPreview OutOfMemoryError");
        // failed to allocate memory
        eventListener.onPictureTakenError("Picture too large (memory)");
      } catch (Exception e) {
        Log.d(TAG, "CameraPreview onPictureTaken general exception");
      } finally {
        canTakePicture = true;
        mCamera.startPreview();
      }
    }
  };

  //this function is kept but we don't use it, resolution will be chosen from Javascript side, and pass to takePictureToFile as width and height
  public Camera.Size getOptimalPictureSize(final int width, final int height, final Camera.Size previewSize, final List<Camera.Size> supportedSizes) {
    /*
      get the supportedPictureSize that:
      - matches exactly width and height
      - has the closest aspect ratio to the preview aspect ratio
      - has picture.width and picture.height closest to width and height
      - has the highest supported picture width and height up to 2 Megapixel if width == 0 || height == 0
    */
    Camera.Size size = mCamera.new Size(width, height);

    Log.d(TAG, "CameraPreview requested " + size.width + 'x' + size.height);

    // convert to landscape if necessary
    if (size.width < size.height) {
      int temp = size.width;
      size.width = size.height;
      size.height = temp;
    }

    double previewAspectRatio = (double) previewSize.width / (double) previewSize.height;

    if (previewAspectRatio < 1.0) {
      // reset ratio to landscape
      previewAspectRatio = 1.0 / previewAspectRatio;
    }

    Log.d(TAG, "CameraPreview previewAspectRatio " + previewAspectRatio);

    //Change from 0.1 to 0.5, so that it wont filter all big enough resolutions
    double aspectTolerance = 0.5;
    double bestDifference = Double.MAX_VALUE;

    for (int i = 0; i < supportedSizes.size(); i++) {
      Camera.Size supportedSize = supportedSizes.get(i);

      Log.d(TAG, "CameraPreview test " + supportedSize.width + "x" + supportedSize.height + (supportedSize.width == width) );
      // Perfect match
      if (supportedSize.width == width && supportedSize.height == height) {
        Log.d(TAG, "CameraPreview optimalPictureSize " + supportedSize.width + 'x' + supportedSize.height);
        return supportedSize;
      }

      double difference = Math.abs(previewAspectRatio - ((double) supportedSize.width / (double) supportedSize.height));

      if (difference < bestDifference - aspectTolerance) {
        // better aspectRatio found
        if ((width != 0 && height != 0) || (supportedSize.width * supportedSize.height < 2048 * 1024)) {
          size.width = supportedSize.width;
          size.height = supportedSize.height;
          bestDifference = difference;
        }
      } else if (difference < bestDifference + aspectTolerance) {
        // same aspectRatio found (within tolerance)
        if (width == 0 || height == 0) {
          // set highest supported resolution below 2 Megapixel
          if ((size.width < supportedSize.width) && (supportedSize.width * supportedSize.height < 2048 * 1024)) {
            size.width = supportedSize.width;
            size.height = supportedSize.height;
          }
        } else {

          boolean isSupportedSmallerRequest = supportedSize.width * supportedSize.height < width * height;
          boolean isChosenSmallerRequest = size.width * size.height < width * height;
          boolean isSupportedSmallerChosen = supportedSize.width * supportedSize.height < size.width * size.height;

          if (isSupportedSmallerRequest && isChosenSmallerRequest && !isSupportedSmallerChosen) {
            size.width = supportedSize.width;
            size.height = supportedSize.height;
          }

          if (!isSupportedSmallerRequest && isChosenSmallerRequest) {
            size.width = supportedSize.width;
            size.height = supportedSize.height;
          }

          if (!isSupportedSmallerRequest && !isChosenSmallerRequest && isSupportedSmallerChosen) {
            size.width = supportedSize.width;
            size.height = supportedSize.height;
          }
        }
      }
    }
    Log.d(TAG, "CameraPreview optimalPictureSize " + size.width + 'x' + size.height);
    return size;
  }

  @SuppressLint("StaticFieldLeak")
  public void takePictureToFile(
          final int width,
          final int height,
          final int quality,
          final String targetFileName,
          final int orientation
  ) {
    Log.d(TAG, "CameraPreview takePictureToFile width: " + width +
            ", height: " + height +
            ", quality: " + quality +
            ", targetFileName: " + targetFileName +
            ", orientation:" + orientation
    );

    final String targetThumbnailFilename = "thumb-" +targetFileName;

    if(mPreview == null) {
      canTakePicture = true;
      Log.d(TAG, "mPreview is NULL");
      eventListener.onPictureTakenError("Not initialized");
      return;
    }

//    if(!canTakePicture) {
//      Log.d(TAG, "Can not take picture right now! Too Fast");
//      eventListener.onPictureTakenError("Too fast");
//      return;
//    }

    //canTakePicture = false;

    final Context context = getActivity().getApplicationContext();
    final SimpleDateFormat format = new SimpleDateFormat("HH:mm:ss.SSS", Locale.getDefault());

    Camera.Parameters params = mCamera.getParameters();

    params.setPictureSize(width, height);

    currentQuality = quality;

    int limitTo360Degrees = (orientation + mPreview.getCorrectedOrientation() + 360) % 360;
    Log.d("Preview", "Setting camera rotation to " + limitTo360Degrees);
    params.setRotation(limitTo360Degrees);

    mCamera.setParameters(params);

    Log.d(TAG, "mCamera.takePicture: " + format.format(Calendar.getInstance().getTime()));

    final PictureCallback pictureCallback = new PictureCallback() {
      @SuppressLint("StaticFieldLeak")
      public void onPictureTaken(final byte[] data, Camera arg1) {
        Log.d(TAG, "onPictureTaken: " + format.format(Calendar.getInstance().getTime()));

        new AsyncTask<Void, Void, Void>() {
          @Override
          protected Void doInBackground(Void... voids) {
            if(Build.MODEL.equals("SM-A135F")) {
                processImageSMA135F(data, quality, targetFileName, targetThumbnailFilename, getActivity().getApplicationContext());
            } else {
                processImage(data, quality, targetFileName, targetThumbnailFilename, getActivity().getApplicationContext());
            }
            return null;
          }

        }.execute();

        new AsyncTask<Void, Void, Void>() {
          @Override
          protected Void doInBackground(Void... voids) {

            try {
              Log.d(TAG, "mCamera.startPreview STA: \t" + format.format(Calendar.getInstance().getTime()));
              mCamera.startPreview();
              Log.d(TAG, "mCamera.startPreview END: \t" + format.format(Calendar.getInstance().getTime()));
            } catch (Exception ignored) {

            } finally {
              //canTakePicture = true;
            }
            return null;
          }
        }.execute();
      }
    };

    new AsyncTask<Void, Void, Void>(){
      @Override
      protected Void doInBackground(Void... voids) {
        try {
            AudioManager audioManager = (AudioManager) context.getSystemService(Context.AUDIO_SERVICE);
            int volume = audioManager.getStreamVolume(AudioManager.STREAM_NOTIFICATION);
            if(volume != 0) {
                mCamera.takePicture(shutterCallback, null, pictureCallback);
            } else {
                mCamera.takePicture(null, null, pictureCallback);
            }
        } catch (Exception e) {
          Log.e(TAG, "Camera.takePicture failed");
          try {
            mCamera.startPreview();
          } catch(Exception ignored){

          } finally {
            eventListener.onPictureTakenError("Camera.takePicture failed");
          }
        }
        return null;
      }
    }.execute();

    canTakePicture = true;
  }

  private void processImage(byte[] data, int quality, String targetFileName, String targetThumbnailFilename, Context context) {
      try {
          Matrix matrix = new Matrix();

          ExifInterface exifInterface = new ExifInterface(new ByteArrayInputStream(data));
          int rotation = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
          int rotationInDegrees = exifToDegrees(rotation);

          if (rotation != 0f) {
              matrix.preRotate(rotationInDegrees);
          }

          FileOutputStream outputStream = null;
          outputStream = context.openFileOutput(targetFileName, Context.MODE_PRIVATE);

          File outputFile = context.getFileStreamPath(targetFileName);
          Bitmap outputData = BitmapFactory.decodeByteArray(data, 0, data.length);
          outputData = applyMatrix(outputData, matrix);
          int imageWidth = outputData.getWidth();
          int imageHeight= outputData.getHeight();
          if(imageWidth * imageHeight > 1600 * 1200 && Math.max(imageWidth, imageHeight) / Math.min(imageWidth, imageHeight) == 4/3) {
              int newWidth = imageWidth > imageHeight ? 1600 : 1200;
              int newHeight = imageWidth > imageHeight ? 1200 : 1600;
              Bitmap scaledDownImage = Bitmap.createScaledBitmap(outputData, newWidth, newHeight, true);
              scaledDownImage.compress(CompressFormat.JPEG, quality, outputStream);
          } else {
              outputData.compress(CompressFormat.JPEG, quality, outputStream);
          }

          Rect scaledRect = RectMathUtil.contain(outputData.getWidth(), outputData.getHeight(), 200, 200);
          // turn image to correct aspect ratio.
          Bitmap partOfImage = Bitmap.createBitmap(outputData, scaledRect.left, scaledRect.top, scaledRect.width(), scaledRect.height());
          // scale down without stretching.
          Bitmap scaledDown = Bitmap.createScaledBitmap(partOfImage, 200, 200, true);

          FileOutputStream thumbOutputStream = context.openFileOutput(targetThumbnailFilename, Context.MODE_PRIVATE);
          File thumbOutputFile = context.getFileStreamPath(targetThumbnailFilename);

          scaledDown.compress(CompressFormat.JPEG, Math.max(quality - 20, 20), thumbOutputStream);

          eventListener.onPictureTakenToFile(outputFile.getName(), thumbOutputFile.getName());
      } catch (IOException e) {
          Log.d(TAG, "CameraPreview IOException");
          eventListener.onPictureTakenError("IO Error when extracting exif");
      }
      catch (Exception e) {
          e.printStackTrace();
          eventListener.onPictureTakenError("Failed to write files to disk");
      }
  }

  private void processImageSMA135F(byte[] data, int quality, String targetFileName, String targetThumbnailFilename, Context context) {
      try {
          Bitmap outputData = BitmapFactory.decodeByteArray(data, 0, data.length);

          Matrix matrix = new Matrix();
          ExifInterface exifInterface = new ExifInterface(new ByteArrayInputStream(data));
          int rotation = exifInterface.getAttributeInt(ExifInterface.TAG_ORIENTATION, ExifInterface.ORIENTATION_NORMAL);
          boolean isHorizontal = rotation == ExifInterface.ORIENTATION_NORMAL || rotation == ExifInterface.ORIENTATION_ROTATE_180;
          int newWidth = 1600;
          int newHeight = 1200;
          Bitmap scaledDownImage = Bitmap.createScaledBitmap(outputData, newWidth, newHeight, true);

          // remove duplicated part
          int[] pixels = new int[(newWidth - 940) * newHeight];
          scaledDownImage.getPixels(pixels, 0, newWidth - 940, 940, 0, newWidth - 940, newHeight);
          scaledDownImage.setPixels(pixels, 0, newWidth - 940, 805, 0, newWidth - 940, newHeight);

          // make image vertical to remove the abundant part in the bottom
          matrix.postRotate(90);
          scaledDownImage = applyMatrix(scaledDownImage, matrix);
          scaledDownImage.reconfigure(scaledDownImage.getWidth(), scaledDownImage.getHeight() - 135, Bitmap.Config.ARGB_8888);

          // rotate back to horizontal if necessary
          if (isHorizontal) {
            int degree = exifToHorizontalDegrees(rotation);
            matrix.preRotate(degree);
            scaledDownImage = applyMatrix(scaledDownImage, matrix);
          }
          streamBitmapToFile(scaledDownImage, context, quality, targetFileName);

          // thumbnail image
          Bitmap thumbnail = Bitmap.createScaledBitmap(scaledDownImage, 200, 200, true);
          streamBitmapToFile(thumbnail, context, Math.max(quality - 20, 20), targetThumbnailFilename);
          eventListener.onPictureTakenToFile(targetFileName, targetThumbnailFilename);
      } catch (IOException e) {
          Log.d(TAG, "CameraPreview IOException");
          eventListener.onPictureTakenError("IO Error when extracting exif");
      }
      catch (Exception e) {
          e.printStackTrace();
          eventListener.onPictureTakenError("Failed to write files to disk");
      }
  }

  public void startRecord(CordovaWebView webview, final String filePath, final String camera, final int width, final int height, final int quality, final boolean withFlash){
//    Log.d(TAG, "CameraPreview startRecord camera: " + camera + " width: " + width + ", height: " + height + ", quality: " + quality);

    if(mCamera != null) {
      Activity activity = getActivity();
      muteStream(true, activity);
      if (this.mRecordingState == RecordingState.STARTED) {
        Log.d(TAG, "Already Recording");
        return;
      }

      this.recordFilePath = filePath;
      int mOrientationHint = calculateOrientationHint();
      int videoWidth = 0;
      int videoHeight = 0;
      Camera.Parameters cameraParams = mCamera.getParameters();
      List<Camera.Size> sizes = cameraParams.getSupportedVideoSizes();
      for(int i = 0; i < sizes.size(); i++) {
          Camera.Size tempSize = sizes.get(i);
          if(tempSize.width == width && tempSize.height == height) {
             videoWidth = width;
             videoHeight = height;
             break;
          } else if(tempSize.width == height && tempSize.height == width) {
            videoWidth = height;
            videoHeight = width;
            break;
          }
      }
      List<String> flashModes = cameraParams.getSupportedFlashModes();
      for(int i = 0; i < flashModes.size(); i++) {
          String mode = flashModes.get(i);
          if(mode == Camera.Parameters.FLASH_MODE_TORCH) {
              cameraParams.setFlashMode(Camera.Parameters.FLASH_MODE_TORCH);
              break;
          }
      }
        mCamera.startPreview();

      mCamera.unlock();
      mRecorder = new MediaRecorder();

      try {
        mRecorder.setCamera(mCamera);

        CamcorderProfile profile;
        if (CamcorderProfile.hasProfile(defaultCameraId, CamcorderProfile.QUALITY_720P)) {
          profile = CamcorderProfile.get(defaultCameraId, CamcorderProfile.QUALITY_720P);
        } else {
          if (CamcorderProfile.hasProfile(defaultCameraId, CamcorderProfile.QUALITY_480P)) {
            profile = CamcorderProfile.get(defaultCameraId, CamcorderProfile.QUALITY_480P);
          } else {
            if (CamcorderProfile.hasProfile(defaultCameraId, CamcorderProfile.QUALITY_720P)) {
              profile = CamcorderProfile.get(defaultCameraId, CamcorderProfile.QUALITY_720P);
            } else {
              if (CamcorderProfile.hasProfile(defaultCameraId, CamcorderProfile.QUALITY_1080P)) {
                profile = CamcorderProfile.get(defaultCameraId, CamcorderProfile.QUALITY_1080P);
              } else {
                profile = CamcorderProfile.get(defaultCameraId, CamcorderProfile.QUALITY_LOW);
              }
            }
          }
        }
        mRecorder.setAudioSource(MediaRecorder.AudioSource.VOICE_RECOGNITION);
        mRecorder.setVideoSource(MediaRecorder.VideoSource.CAMERA);
        mRecorder.setProfile(profile);
        mRecorder.setOutputFile(filePath);
        mRecorder.setMaxDuration(12000);
        mRecorder.setOrientationHint(mOrientationHint);
        mRecorder.setVideoEncodingBitRate(2500000);
        mRecorder.setOnInfoListener(new MediaRecorder.OnInfoListener() {
            @Override
            public void onInfo(MediaRecorder mediaRecorder, int i, int i1) {
                if(i == MediaRecorder.MEDIA_RECORDER_INFO_MAX_DURATION_REACHED) {
                    mediaRecorder.stop();
                    mediaRecorder.reset();
                    mediaRecorder.release();
                    webview.sendJavascript("cordova.fireDocumentEvent('videoRecorderUpdate', {filePath: '"+ filePath + "' }, true);");
                }
            }
        });
        if(videoWidth != 0 && videoHeight != 0) {
            mRecorder.setVideoSize(videoWidth, videoHeight);
        }
        mRecorder.prepare();
        Log.d(TAG, "Starting recording");
        mRecorder.start();
        eventListener.onStartRecordVideo();
      } catch (IOException e) {
        eventListener.onStartRecordVideoError(e.getMessage());
      } catch (NullPointerException e) {
          eventListener.onStartRecordVideoError(e.getMessage());
      } catch (IllegalStateException e){
          eventListener.onStartRecordVideoError(e.getMessage());
      }

    } else {
        eventListener.onStartRecordVideoError("Requiring RECORD_AUDIO permission to continue");
      Log.d(TAG, "Requiring RECORD_AUDIO permission to continue");
    }
  }

  public int calculateOrientationHint() {
    DisplayMetrics dm = new DisplayMetrics();
    Camera.CameraInfo info = new Camera.CameraInfo();
    Camera.getCameraInfo(defaultCameraId, info);
    int cameraRotationOffset = info.orientation;
    Activity activity = getActivity();

    activity.getWindowManager().getDefaultDisplay().getMetrics(dm);
    int currentScreenRotation = activity.getWindowManager().getDefaultDisplay().getRotation();

    int degrees = 0;
    switch (currentScreenRotation) {
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

    int orientation;
    if (info.facing == Camera.CameraInfo.CAMERA_FACING_FRONT) {
      orientation = (cameraRotationOffset + degrees) % 360;
      if (degrees != 0) {
        orientation = (360 - orientation) % 360;
      }
    } else {
      orientation = (cameraRotationOffset - degrees + 360) % 360;
    }
    Log.w(TAG, "************orientationHint ***********= " + orientation);

    return orientation;
  }

  public void stopRecord() {
    Log.d(TAG, "stopRecord");
    try {
      mRecorder.stop();
      mRecorder.reset();   // clear recorder configuration
      mRecorder.release(); // release the recorder object
      mRecorder = null;
      mCamera.lock();
      Camera.Parameters cameraParams = mCamera.getParameters();
      cameraParams.setFlashMode(Camera.Parameters.FLASH_MODE_OFF);
      mCamera.setParameters(cameraParams);
      mCamera.startPreview();
      eventListener.onStopRecordVideo(this.recordFilePath);
    } catch (Exception e) {
      eventListener.onStopRecordVideoError(e.getMessage());
    }
  }

  public void muteStream(boolean mute, Activity activity) {
    AudioManager audioManager = ((AudioManager)activity.getApplicationContext().getSystemService(Context.AUDIO_SERVICE));
    int direction = mute ? audioManager.ADJUST_MUTE : audioManager.ADJUST_UNMUTE;
    audioManager.setStreamMute(AudioManager.STREAM_SYSTEM, true);
    audioManager.setStreamMute(AudioManager.STREAM_MUSIC, true);

  }

  private void streamBitmapToFile(Bitmap image, Context context, int quality, String targetFileName) {
      try {
          FileOutputStream outputStream = null;
          outputStream = context.openFileOutput(targetFileName, Context.MODE_PRIVATE);
          image.compress(CompressFormat.JPEG, quality, outputStream);
          outputStream.close();
      } catch (Exception e) {
          e.printStackTrace();
          eventListener.onPictureTakenError("Failed to write files to disk");
      }

  }

  public void takePicture(final int width, final int height, final int quality) {
    Log.d(TAG, "CameraPreview takePicture width: " + width + ", height: " + height + ", quality: " + quality);

    if (mPreview != null) {
      if (!canTakePicture) {
        return;
      }

      canTakePicture = false;

      new Thread() {
        public void run() {
          Camera.Parameters params = mCamera.getParameters();

          Camera.Size size = getOptimalPictureSize(width, height, params.getPreviewSize(), params.getSupportedPictureSizes());
          params.setPictureSize(size.width, size.height);
          currentQuality = quality;

          if (cameraCurrentlyLocked == Camera.CameraInfo.CAMERA_FACING_FRONT) {
            // The image will be recompressed in the callback
            params.setJpegQuality(99);
          } else {
            params.setJpegQuality(quality);
          }

          params.setRotation(0);

          mCamera.setParameters(params);
          mCamera.takePicture(shutterCallback, null, jpegPictureCallback);
        }
      }.start();
    } else {
      canTakePicture = true;
    }
  }

  public void setFocusArea(
          final int pointX,
          final int pointY,
          final Camera.AutoFocusCallback callback
  ) {
    this.setFocusArea(pointX, pointY, callback, width, height);
  }

  public void setFocusArea(
          final int pointX,
          final int pointY,
          final Camera.AutoFocusCallback callback,
          final int viewWidth,
          final int viewHeight
  ) {
    try {
        if (mCamera != null) {

            mCamera.cancelAutoFocus();

            int screenRotation = getActivity().getWindowManager().getDefaultDisplay().getRotation();
            int screenRotationDegrees = 0;

            switch (screenRotation) {
                case Surface.ROTATION_0:
                    screenRotationDegrees = 0;
                    break;
                case Surface.ROTATION_90:
                    screenRotationDegrees = 90;
                    break;
                case Surface.ROTATION_180:
                    screenRotationDegrees = 180;
                    break;
                case Surface.ROTATION_270:
                    screenRotationDegrees = 270;
                    break;
            }

            Camera.CameraInfo info = new Camera.CameraInfo();
            Camera.getCameraInfo(defaultCameraId, info);
            int cameraRotation = info.orientation;

            Log.d(TAG, "CameraRotation: " + cameraRotation + ", ScreenRotation: " + screenRotationDegrees);

            Camera.Parameters parameters = mCamera.getParameters();

            int rotateCoordinatesClockwise = ((screenRotationDegrees - cameraRotation) + 360) % 360;

            Rect focusRect = calculateTapArea(pointX, pointY, viewWidth, viewHeight, rotateCoordinatesClockwise);
            parameters.setFocusMode(Camera.Parameters.FOCUS_MODE_AUTO);
            parameters.setFocusAreas(Arrays.asList(new Camera.Area(focusRect, 1000)));

            if (parameters.getMaxNumMeteringAreas() > 0) {
                Rect meteringRect = calculateTapArea(pointX, pointY, viewWidth, viewHeight, rotateCoordinatesClockwise);
                parameters.setMeteringAreas(Arrays.asList(new Camera.Area(meteringRect, 1000)));
            }

            setCameraParameters(parameters);
            mCamera.autoFocus(callback);
        }
    } catch(Exception e) {
        Log.d(TAG, e.getMessage());
        e.printStackTrace();
        callback.onAutoFocus(false, this.mCamera);
    }
  }

  private Rect calculateTapArea(float x, float y, float viewWidth, float viewHeight, int rotation) {
    float scaledX = (x / viewWidth) * 2000 - 1000; // go from x in [0, viewWidth] to [-1000, 1000]
    float scaledY = (y / viewHeight) * 2000 - 1000;

    float rotatedX = scaledX;
    float rotatedY = scaledY;

    if (rotation < 0) {
      rotation = rotation + 360;
    }
    if (rotation == 360) {
      rotation = 0;
    }

    // we need to rotate coordinates clockwise, to make up for the difference between
    // screen coordinates and coordinates of the camera.
    // for example, if the screen has a orientation of 0 (upward) , but the camera has an orientation of
    // 270 (to the left), we need to rotate the coordinates 90 degrees clockwise, around (0,0),
    // so that they match up with what the user sees on the screen.

    // imaging drawing a point in the camera space, then rotating it 90 degrees clockwise, to match
    // up when the screen space.

    if (rotation == 270) {
      rotatedX = scaledY;
      rotatedY = -scaledX;
    }
    if (rotation == 180) {
      rotatedX = -scaledX;
      rotatedY = -scaledY;
    }
    if (rotation == 90) {
      rotatedX = -scaledY;
      rotatedY = scaledX;
    }

    // make a rectangle around the centerpoint, but make sure that coordinates
    // do not leave [-1000, 1000]
    return new Rect(
            Math.round(Math.max(-1000, rotatedX - 50)),
            Math.round(Math.max(-1000, rotatedY - 50)),
            Math.round(Math.min(1000, rotatedX + 50)),
            Math.round(Math.min(1000, rotatedY + 50))
    );
  }
}