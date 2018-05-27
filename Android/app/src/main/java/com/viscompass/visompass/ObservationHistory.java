package com.viscompass.visompass;

import java.util.ArrayList;
import java.util.Collections;
import java.util.Date;
import java.util.Enumeration;

public class ObservationHistory {
    Double gamma = 2.0;
    long window_msecs = 10000;
    long interval = 1000;
    ArrayList<Observation> otherObservations;
    Observation mostRecentObservation;

public ObservationHistory(long window_msecs){
    this.window_msecs = window_msecs;
    otherObservations = new ArrayList<Observation>();
}

public void addObservation(Observation o){
    if(mostRecentObservation != null){
        otherObservations.add(mostRecentObservation);
        otherObservations.add(o);
        Collections.sort(otherObservations);
        mostRecentObservation = otherObservations.remove(0);
    }
    else{
        mostRecentObservation = o;
    };

}

public Float smoothed(Date refDateTime){

    ArrayList<Float> iseries = interval_series(refDateTime);
    if(iseries.size() == 0){return null;};
    Float sv = iseries.remove(0);
    for(int counter = 0; counter < iseries.size();counter++){
        long delta_t = (long)(counter + 1) * interval;
        Float delta_v = weight(delta_t) * deltaFunc(sv,iseries.get(counter));
        sv = sv + delta_v;
    }
    return sv;
}

Float deltaFunc(Float v1, Float v2){
    return v2-v1;
}
ArrayList<Float> interval_series(Date refTime){
    ArrayList<Float> s = new ArrayList<Float>();
    long t = refTime.getTime();
    long earliest_t = t - window_msecs;
    s.add(mostRecentObservation.v);
    if(otherObservations != null) {
        for (int counter = 0; counter < otherObservations.size(); counter++) {
            Observation obs = otherObservations.get(counter);
            if (obs.t.getTime() < earliest_t) {
                otherObservations.remove(counter);
            } else if (t >= obs.t.getTime() && t > earliest_t) {
                s.add(obs.v);
                t -= interval;
                if (t < earliest_t) {
                    break;
                }
            }
            ;
        }
    }
return s;

}
Float weight(long delta_t){
    if(delta_t >= window_msecs){return 0.0f;};
    double linear_weight = ((double)window_msecs - (double)delta_t) / (double)window_msecs;
    return (float)Math.pow((double)linear_weight, gamma);

}



}
