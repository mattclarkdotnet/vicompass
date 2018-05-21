package com.viscompass.visompass;

public class Correction {
Turn direction;
Float amount;
Boolean required;

public Correction (Turn drn,Float amt,Boolean rqd){
    direction = drn;
    amount = amt;
    required = rqd;
}
}
