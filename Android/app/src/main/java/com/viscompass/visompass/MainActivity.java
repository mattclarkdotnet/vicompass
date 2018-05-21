package com.viscompass.visompass;

import android.content.res.ColorStateList;
import android.graphics.Color;
import android.hardware.SensorManager;
import android.media.AudioManager;
import android.media.MediaPlayer;
import android.media.SoundPool;
import android.os.Handler;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.content.Context;
import android.view.View;
import android.widget.CompoundButton;
import android.widget.Switch;
import android.widget.TextView;

import java.util.HashMap;
import java.util.Timer;
import java.util.TimerTask;

import static android.content.Context.SENSOR_SERVICE;

public class MainActivity extends AppCompatActivity {
    CompassModel model;
    TextView tvHeading;
    TextView tvTarget;
    TextView tvCorrection;
    TextView tvTolerance;
    Switch switch1;
    Timer timer;
    Timer beepTimer;
    MediaPlayer mpNormal;
    MediaPlayer mpHigh;
    MediaPlayer mpLow;
    SoundPool spBeeps;
    HashMap soundPoolMap;
    private static long interval = 1000;
    final Handler handler = new Handler();

@Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        model = new CompassModel((SensorManager) getSystemService(SENSOR_SERVICE));
        tvHeading = (TextView) findViewById(R.id.tvHeading);
        tvTarget = (TextView) findViewById(R.id.tvTarget);
        tvCorrection = (TextView) findViewById(R.id.tvCorrection);
        tvTolerance = (TextView) findViewById(R.id.tvTolerance);
        model.setDiffTolerance(Float.parseFloat(tvTolerance.getText().toString()));

        mpNormal = MediaPlayer.create(getApplicationContext(),R.raw.drum200);
        mpNormal.setLooping(true);
        mpHigh = MediaPlayer.create(getApplicationContext(),R.raw.click_high);
        mpHigh.setLooping(true);
        mpLow = MediaPlayer.create(getApplicationContext(),R.raw.click_low);
        mpLow.setLooping(true);

        spBeeps = new SoundPool(1, AudioManager.STREAM_MUSIC,100);
        soundPoolMap = new HashMap<String,Integer>(3);
        soundPoolMap.put("Normal",spBeeps.load(getApplicationContext(),R.raw.drum200,1));
        soundPoolMap.put("High",spBeeps.load(getApplicationContext(),R.raw.click_high,2));
        soundPoolMap.put("Low",spBeeps.load(getApplicationContext(),R.raw.click_low,3));


        switch1 = (Switch) findViewById(R.id.switch1);
        switch1.setOnCheckedChangeListener(new CompoundButton.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(CompoundButton buttonView, boolean isChecked) {
                if(isChecked){
                    model.setTargetHeading();
                    tvTarget.setVisibility(View.VISIBLE);
                    tvCorrection.setVisibility((View.VISIBLE));
                }
            }
        });
        timer = new Timer();
        TimerTask taskNew = new TimerTask() {
            @Override
            public void run() {
                handler.post(new Runnable() {
                    public void run() {
                        updateUI();
                    }
                });
            }
        };
        timer.schedule(taskNew,MainActivity.interval, MainActivity.interval);
    }

    public void updateUI() {
        updateScreenUI();
    }

    void updateScreenUI(){
        Correction corr = model.getCorrection();
        tvHeading.setText(model.getCurrentHeading());
        if(switch1.isChecked()){
            tvTarget.setText(model.getTargetHeading());
            tvCorrection.setText(Integer.toString(Math.abs(Math.round(corr.amount))));
            if(corr.required){
                if(corr.direction == Turn.port){
                    tvCorrection.setTextColor(Color.RED);
                    spBeeps.play((int)soundPoolMap.get("Low"),1.0f,0.0f,1,1,1);
                    //if(mpNormal.isPlaying()){mpNormal.pause();};
                    //if(mpHigh.isPlaying()){mpHigh.pause();};
                    //mpLow.start();
                }
                else if(corr.direction == Turn.stbd){
                    tvCorrection.setTextColor(Color.GREEN);
                    spBeeps.play((int)soundPoolMap.get("High"),0.0f,1.0f,1,1,1);
                    //if(mpNormal.isPlaying()){mpNormal.pause();};
                    //if(mpLow.isPlaying()){mpLow.pause();};
                    //mpHigh.start();

                };
            }
            else{
                tvCorrection.setTextColor(Color.WHITE);
                spBeeps.play((int)soundPoolMap.get("Normal"),1.0f,1.0f,1,1,1);
                //if(mpHigh.isPlaying()){mpHigh.pause();};
                //if(mpLow.isPlaying()){mpLow.pause();};
                //mpNormal.start();
            };
        }
        else{
            tvTarget.setVisibility(View.INVISIBLE);
            tvCorrection.setVisibility(View.INVISIBLE);
        }


    }

    }

