package com.viscompass.visompass;

import org.junit.Before;
import org.junit.Test;

import java.util.Date;

import static org.junit.Assert.*;

public class ObservationHistoryTests {

    @Before
    public void setUp() throws Exception{

    }

    @Test
    public void testSmoothedHeadingCalculatesCorrectly() throws Exception{
        ObservationHistory oh;
        oh = new ObservationHistory(10000);
        Long lDate;
        Date date = new Date();
        lDate = date.getTime();
        oh.addObservation(new Observation(92.0f, new Date(lDate-4000)));
        oh.addObservation(new Observation(91.0f, new Date(lDate-3000)));
        oh.addObservation(new Observation(90.0f, new Date(lDate-2000)));
        oh.addObservation(new Observation(89.0f, new Date(lDate-1000)));
        oh.addObservation(new Observation(88.0f, new Date(lDate)));

        assertTrue( (oh.smoothed(new Date(lDate)) < 90.0f));
        assertTrue((oh.smoothed(new Date(lDate)) > 88.0f));
    }

    @Test
    public void testSmoothedHeadingUsesWindow() throws Exception{
        ObservationHistory oh;
        oh = new ObservationHistory(10000);
        Long lDate;
        Date date = new Date();
        lDate = date.getTime();
        oh.addObservation(new Observation(92.0f, new Date(lDate-6000)));
        oh.addObservation(new Observation(91.0f, new Date(lDate-5000)));
        oh.addObservation(new Observation(89.0f, new Date(lDate-4000)));
        oh.addObservation(new Observation(88.0f, new Date(lDate-3000)));
        oh.addObservation(new Observation(90.0f, new Date(lDate)));
        oh.addObservation(new Observation(10.0f, new Date(lDate-16000)));

        assertTrue( (oh.smoothed(new Date(lDate)) < 90.0f));
        assertTrue((oh.smoothed(new Date(lDate)) > 88.0f));
    }
    @Test
    public void testMostRecentObservation() throws Exception{
        ObservationHistory oh;
        oh = new ObservationHistory(10000);
        Long lDate;
        Date date = new Date();
        lDate = date.getTime();
        oh.addObservation(new Observation(91.0f, new Date(lDate-5000)));
        oh.addObservation(new Observation(89.0f, new Date(lDate-4000)));
        oh.addObservation(new Observation(90.0f, new Date(lDate)));

        assertEquals(90.0f, oh.mostRecentObservation.v,0.000001);
    }
}
