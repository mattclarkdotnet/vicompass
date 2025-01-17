package com.viscompass.visompass;

import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.Sensor;
import android.hardware.SensorManager;

import java.util.Date;

enum Turn{
    port, stbd
}

public class CompassModel implements SensorEventListener{
    int diffTolerance = 5;
    Float headingTarget = 0.0f;
    Float headingCurrent = 0.0f;
    Integer responsivenessIndex = 2;
    long[] responsivenessWindows = {10000, 6000,3000,1500,750};
    Correction headingCorrection = new Correction(Turn.port,0.0f,false);
    ObservationHistory oh;
    private SensorManager sensorManager;
    private Float tackDegrees = 100.0f;
    private final float[] accelerometerReading = new float[3];
    private final float[] magnetometerReading = new float[3];

    private final float[] rotationMatrix = new float[9];
    private final float[] orientationAngles = new float[3];

    public CompassModel(SensorManager sM){
        sensorManager = sM;
        sensorManager.registerListener(this, sensorManager.getOrientation();
        oh = new ObservationHistory(3000);

    }
    public CompassModel()
    {
        //create a compass model without a sensor manager for testing purposes
    }


    public String getCurrentHeading(){
        return Integer.toString(Math.round(headingCurrent));
    }
    public String getTargetHeading(){
        return Integer.toString(Math.round(headingTarget));
    }
    public Correction getCorrection(){
        return headingCorrection;
    }
    public int getDiffTolerance(){
        return diffTolerance;
    }

    public void setDiffTolerance(int dt){
        if(dt > 0) {
            diffTolerance = dt;
            calculateCorrection();
        }
    }

    public void setTargetHeading(){
        headingTarget = headingCurrent;

    }
    public void setResponsiveness(Integer index){
        responsivenessIndex = index;
        oh.window_msecs = responsivenessWindows[index];

    }

    public void onSensorChanged(SensorEvent event) {

        // get the angle around the z-axis rotated
        oh.addObservation(new Observation(event.values[0], new Date()));
        headingCurrent = oh.smoothed(new Date());
        calculateCorrection();

    }
    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // not in use
    }
    public void calculateCorrection(){

        headingCorrection.amount = correctionDegrees(headingTarget, headingCurrent);
        headingCorrection.direction = (headingCorrection.amount < 0) ? Turn.port:Turn.stbd;
        headingCorrection.required = (Math.abs(headingCorrection.amount) > (float)diffTolerance) ? true : false;
    }

    public Float correctionDegrees(Float ht, Float hc){
        Float diff = 0.0f;

        diff = ht - hc;
        if (diff == -180){return 180.0f;}
        else if (diff > 180){return diff - 360.0f;}
        else if (diff < -180) {return diff + 360.0f;}
        else {return diff;}
    }

    void modifyTarget(Float delta){
     if(headingTarget != null){
         headingTarget = (headingTarget + delta) % 360;
         if(headingTarget < 0){
             headingTarget += 360;
         }
         calculateCorrection();
     }
    }

public void tackPort(){
        modifyTarget(-tackDegrees);
}

public void tackStbd(){
        modifyTarget(tackDegrees);
}

}
