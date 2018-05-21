package com.viscompass.visompass;

import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.Sensor;
import android.hardware.SensorManager;

enum Turn{
    port, stbd
}

public class CompassModel implements SensorEventListener{
    Float diffTolerance = 0.0f;
    Float headingTarget = 0.0f;
    Float headingCurrent = 0.0f;
    Correction headingCorrection = new Correction(Turn.port,0.0f,false);
    private SensorManager sensorManager;
    private Float tackDegrees = 100.0f;

    public CompassModel(SensorManager sM){
        sensorManager = sM;
        sensorManager.registerListener(this, sensorManager.getDefaultSensor(Sensor.TYPE_ORIENTATION),SensorManager.SENSOR_DELAY_GAME);

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
    public Float getDiffTolerance(){
        return diffTolerance;
    }

    public void setDiffTolerance(Float dt){
        diffTolerance = dt;
    }

    public void setTargetHeading(){
        headingTarget = headingCurrent;

    }
    public void onSensorChanged(SensorEvent event) {

        // get the angle around the z-axis rotated
        headingCurrent = event.values[0];
        calculateCorrection();

    }
    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {
        // not in use
    }
    public void calculateCorrection(){
        Float diff = 0.0f;


        diff = headingTarget - headingCurrent;
        if (diff == -180){headingCorrection.amount = 180.0f;}
        else if (diff > 180){headingCorrection.amount = diff - 360.0f;}
        else if (diff < -180) {headingCorrection.amount = diff + 360.0f;}
        else {headingCorrection.amount = diff;};


        headingCorrection.direction = (headingCorrection.amount < 0) ? Turn.port:Turn.stbd;
        headingCorrection.required = (Math.abs(headingCorrection.amount) > 5) ? true : false; //also need to calculate this based on sensitivity
    }

    void modifyTarget(Float delta){
     if(headingTarget != null){
         headingTarget = (headingTarget + delta) % 180;
     }
    }

public void tackPort(){
        modifyTarget(-tackDegrees);
}

public void tackStbd(){
        modifyTarget(tackDegrees);
}

}
