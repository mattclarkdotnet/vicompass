package com.viscompass.visompass;

import org.junit.Before;
import org.junit.Test;

import static org.junit.Assert.*;

public class CompassModelTests {
    CompassModel cm;
    @Before
    public void setUp() throws Exception{
        cm = new CompassModel();
    }
    @Test
    public void testCorrectionCalculation() throws Exception {
        assertEquals(0.0f, cm.correctionDegrees(0.0f,0.0f),0.000001);
        assertEquals(0.0f, cm.correctionDegrees(90.0f,90.0f),0.000001);
        assertEquals(0.0f, cm.correctionDegrees(180.0f,180.0f),0.000001);
        assertEquals(0.0f, cm.correctionDegrees(270.0f,270.0f),0.000001);
        assertEquals(0.0f, cm.correctionDegrees(359.0f,359.0f),0.000001);
        assertEquals(0.0f, cm.correctionDegrees(1.0f,1.0f),0.000001);
        assertEquals(10.0f, cm.correctionDegrees(20.0f,10.0f),0.000001);
        assertEquals(-10.0f, cm.correctionDegrees(10.0f,20.0f),0.000001);
        assertEquals(30.0f, cm.correctionDegrees(20.0f,350.0f),0.000001);
        assertEquals(-30.0f, cm.correctionDegrees(350.0f,20.0f),0.000001);
        assertEquals(30.0f, cm.correctionDegrees(350.0f,320.0f),0.000001);
        assertEquals(170.0f, cm.correctionDegrees(0.0f,190.0f),0.000001);
        assertEquals(20.0f, cm.correctionDegrees(190.0f,170.0f),0.000001);
        assertEquals(180.0f, cm.correctionDegrees(90.0f,270.0f),0.000001);
        assertEquals(180.0f, cm.correctionDegrees(270.0f,90.0f),0.000001);
    }
}
