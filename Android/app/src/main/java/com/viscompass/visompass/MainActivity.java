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
import android.widget.Button;
import android.widget.CompoundButton;
import android.widget.Switch;
import android.widget.TextView;

import java.util.Date;
import java.util.HashMap;
import java.util.Timer;
import java.util.TimerTask;

import static android.content.Context.SENSOR_SERVICE;
import static java.util.Objects.isNull;

public class MainActivity extends AppCompatActivity implements View.OnClickListener {
    CompassModel model;
    TextView tvHeading, tvTarget, tvCorrection, tvTolerance, tvPortArrow, tvStbdArrow;
    Switch switch1;
    Timer timer;
    Timer beepTimer;
    float slowest_interval_secs = 2.0f;
    float fastest_interval_secs = 0.1f;
    private static long beepInterval;
    Date lastBeepTime;
    int beepSound;
    MediaPlayer mpNormal;
    MediaPlayer mpHigh;
    MediaPlayer mpLow;
    SoundPool spBeeps;
    HashMap soundPoolMap;
    private static long interval = 1000;
    final Handler handler = new Handler();
    Button btnQQ,btnQ,btnM,btnS,btnSS;
    Button btnPort,btnStbd,btnPlus, btnMinus;

@Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);
        Context context = this;
        model = new CompassModel((SensorManager) getSystemService(SENSOR_SERVICE));
        tvHeading = (TextView) findViewById(R.id.tvHeading);
        tvTarget = (TextView) findViewById(R.id.tvTarget);
        tvCorrection = (TextView) findViewById(R.id.tvCorrection);
        tvTolerance = (TextView) findViewById(R.id.tvTolerance);
        tvTolerance.setText(Integer.toString(model.getDiffTolerance()));
        tvPortArrow = (TextView) findViewById(R.id.tvPortArrow);
        tvStbdArrow = (TextView) findViewById(R.id.tvStbdArrow);
        btnPlus = (Button) findViewById(R.id.btnPlus);
        btnPlus.setOnClickListener(this);
        btnMinus = (Button) findViewById(R.id.btnMinus);
        btnMinus.setOnClickListener(this);
        btnQQ = (Button) findViewById(R.id.btnQQ);
        btnQQ.setOnClickListener(this);
        btnQ = (Button) findViewById(R.id.btnQ);
        btnQ.setOnClickListener(this);
        btnM = (Button) findViewById(R.id.btnM);
        btnM.setOnClickListener(this);
        btnS = (Button) findViewById(R.id.btnS);
        btnS.setOnClickListener(this);
        btnSS = (Button) findViewById(R.id.btnSS);
        btnSS.setOnClickListener(this);
        btnPort = (Button) findViewById(R.id.btnPort);
        btnPort.setOnClickListener(this);
        btnStbd = (Button) findViewById(R.id.btnStbd);
        btnStbd.setOnClickListener(this);
        tvTarget.setOnTouchListener(new OnSwipeTouchListener(context){
            @Override
            public void onSwipeLeft(){
               model.tackStbd();
            }

            @Override
            public void onSwipeRight() {
                model.tackPort();
            }
        });

        //Set default responsiveness
        model.setResponsiveness(2);
        deselectAllSensitivityButtons();
        btnM.setBackgroundResource(R.drawable.bordered_button_selected);

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
                }
                else{
                    tvTarget.setText("---");
                    tvCorrection.setText("---");
                    tvCorrection.setTextColor(Color.WHITE);
                    tvPortArrow.setVisibility(View.INVISIBLE);
                    tvStbdArrow.setVisibility(View.INVISIBLE);
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
public void onClick(View view){
    if(view.equals(btnSS)) {
        model.setResponsiveness(0);
        deselectAllSensitivityButtons();
        btnSS.setBackgroundResource(R.drawable.bordered_button_selected);
    }
    if(view.equals(btnS)) {
        model.setResponsiveness(1);
        deselectAllSensitivityButtons();
        btnS.setBackgroundResource(R.drawable.bordered_button_selected);
    }
    if(view.equals(btnM)) {
        model.setResponsiveness(2);
        deselectAllSensitivityButtons();
        btnM.setBackgroundResource(R.drawable.bordered_button_selected);
    }
    if(view.equals(btnQ)) {
        model.setResponsiveness(3);
        deselectAllSensitivityButtons();
        btnQ.setBackgroundResource(R.drawable.bordered_button_selected);
    }
    if(view.equals(btnQQ)) {
        model.setResponsiveness(4);
        deselectAllSensitivityButtons();
        btnQQ.setBackgroundResource(R.drawable.bordered_button_selected);
    }
    if(view.equals(btnPort)){
        model.modifyTarget(-1.0f);
    }
    if(view.equals(btnStbd)){
        model.modifyTarget(1.0f);
    }
    if(view.equals(btnPlus)){
        model.setDiffTolerance(model.getDiffTolerance() + 1);
        tvTolerance.setText(Integer.toString(model.getDiffTolerance()));
    }
    if(view.equals(btnMinus)){
        model.setDiffTolerance(model.getDiffTolerance() -1);
        tvTolerance.setText(Integer.toString(model.getDiffTolerance()));
    }


}

    public void updateUI() {
        updateScreenUI();
        updateBeepUI();
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
                    tvStbdArrow.setVisibility(View.INVISIBLE);
                    tvPortArrow.setVisibility(View.VISIBLE);
                }
                else if(corr.direction == Turn.stbd){
                    tvCorrection.setTextColor(Color.GREEN);
                    tvPortArrow.setVisibility(View.INVISIBLE);
                    tvStbdArrow.setVisibility(View.VISIBLE);
                };
            }
            else{
                tvCorrection.setTextColor(Color.WHITE);
                tvStbdArrow.setVisibility(View.INVISIBLE);
                tvPortArrow.setVisibility(View.INVISIBLE);
            };
        }



    }

    void updateBeepUI(){
        if(!switch1.isChecked()){
            if(beepTimer != null){
                beepTimer.cancel();
            }
            return;
        }
        Correction corr = model.getCorrection();

        if(!corr.required){
            beepInterval = 5000;
            beepSound = (int)soundPoolMap.get("Normal");
        }
        else{
            float degrees = Math.abs(corr.amount);
            float numerator = model.diffTolerance * slowest_interval_secs;
            float intervalSecs = Math.max(fastest_interval_secs, numerator/degrees);
            if (intervalSecs < 0.05f){
                intervalSecs = 0.05f;
            }
            beepInterval = (long)(intervalSecs*1000);
            switch (corr.direction){
                case stbd:
                    beepSound = (int)soundPoolMap.get("High");
                    break;
                case port:
                    beepSound = (int)soundPoolMap.get("Low");
                    break;
            }
        }
        beepMaybe();

    }

    void beepMaybe(){
        if (beepInterval == 0 || beepSound == 0){
            return;
        }

        if (beepTimer == null || lastBeepTime == null){
            lastBeepTime = new Date();
            beepTimer = new Timer();
            TimerTask taskBeep = new TimerTask() {
                @Override
                public void run() {
                    handler.post(new Runnable() {
                        public void run() {
                            beepMaybe();
                        }
                    });
                }
            };
            beepTimer.schedule(taskBeep,MainActivity.beepInterval, MainActivity.beepInterval);
            spBeeps.play(beepSound,1.0f,1.0f,1,0,1);
        }
        else{
            long timeSinceLastBeep = new java.util.Date().getTime() - lastBeepTime.getTime();
            if(beepInterval <= timeSinceLastBeep){
                beepTimer.cancel();

                lastBeepTime = new Date();
                beepTimer = new Timer();
                TimerTask taskBeep = new TimerTask() {
                    @Override
                    public void run() {
                        handler.post(new Runnable() {
                            public void run() {
                                beepMaybe();
                            }
                        });
                    }
                };
                beepTimer.schedule(taskBeep,MainActivity.beepInterval, MainActivity.beepInterval);
                spBeeps.play(beepSound,1.0f,1.0f,1,0,1);
            }
            else{

                beepTimer.cancel();
                beepTimer = new Timer();
                TimerTask taskBeep = new TimerTask() {
                    @Override
                    public void run() {
                        handler.post(new Runnable() {
                            public void run() {
                                beepMaybe();
                            }
                        });
                    }
                };
                beepTimer.schedule(taskBeep,MainActivity.beepInterval, MainActivity.beepInterval);
            }
        }


    }
void deselectAllSensitivityButtons(){
    btnSS.setBackgroundResource(R.drawable.bordered_button);
    btnS.setBackgroundResource(R.drawable.bordered_button);
    btnM.setBackgroundResource(R.drawable.bordered_button);
    btnQ.setBackgroundResource(R.drawable.bordered_button);
    btnQQ.setBackgroundResource(R.drawable.bordered_button);
}
    }

