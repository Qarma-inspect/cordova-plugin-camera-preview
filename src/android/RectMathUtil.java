package com.cordovaplugincamerapreview;

import android.graphics.Rect;


public class RectMathUtil {

    public static Rect contain(int currentWidth, int currentHeight, int preferredWidth, int preferredHeight) {
        float currentAspectRatio = (float) currentHeight / (float) currentWidth;
        float preferredAspectRatio = (float) preferredHeight / (float) preferredWidth;

        if (currentAspectRatio < preferredAspectRatio) {

            int height = currentHeight;
            int width = Math.round( height / preferredAspectRatio);
            int offsetX = (currentWidth - width) / 2;

            return new Rect(offsetX, 0, currentWidth - offsetX, height);
        } else {

            int width = currentWidth;
            int height = Math.round(preferredAspectRatio * width);
            int offsetY = (currentHeight - height) / 2;

            return new Rect(0, offsetY, currentWidth, currentHeight - offsetY);
        }
    }

}
