package com.viscompass.visompass;

import androidx.annotation.NonNull;

import java.util.Date;

public class Observation implements Comparable{
    public Float v;
    public Date t;

    public Observation(Float heading, Date date){
        v = heading;
        t = date;
    }
    @Override
    public int compareTo(@NonNull Object o) {
        Date compareDate = ((Observation)o).t;
        return compareDate.compareTo(this.t);
    }
}
