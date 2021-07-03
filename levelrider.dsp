declare filename "levelrider_stereo.dsp";
declare name 		"Level Rider";
declare version 	"1.0";
declare author 		"Evermind";
declare license 	"BSD";
declare copyright 	"(c) Evermind 2021";

//-----------------------------------------------
// 			Volume control in dB
//-----------------------------------------------

import("stdfaust.lib");

envelop			= abs : max(ba.db2linear(-70)) : ba.linear2db : min(10)  : max ~ -(80.0/ma.SR);

//get desired level in db and convert to linear
target		= vslider("h:[1]Config/[0][unit:dB]Target", 0, -40, +4, 0.1) : ba.db2linear : si.smoo;

//get desired speed
sec_time_window  = vslider("h:[1]Config/[1][unit:ms]Speed", 100, 1, 2000, 1) : /(1000);
samp_time_window = sec_time_window : ba.sec2samp;

//get max change
maxchange   = vslider("h:[1]Config/[2][unit:dB]Max change", 3, 0, 20, 0.01) : ba.db2linear : si.smoo;

//get current level, RMS
current_rms = _ <: attach(_, envelop(_) : hbargraph("[0][unit:dB]Input", -70, 10)) : ba.slidingRMS(samp_time_window);

//calculate desired change
desired_change = target / current_rms;

//calculate actual change
actual_change = min(maxchange,desired_change) : max(1/maxchange) <: attach(_,ba.linear2db : hbargraph("[2]Adjustment[unit:dB]",-20,20));

process		= _,_ : sp.stereoize(* (actual_change));
