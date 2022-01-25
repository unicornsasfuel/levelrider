declare name 		"Level Rider";
declare version 	"2.0";
declare author 		"Evermind";
declare license 	"BSD";
declare copyright 	"(c) Evermind 2021";


import("stdfaust.lib");

/////////////////////////////
// Parameters
////////////////////////////
//get desired speed
sec_time_window  = vslider("v:Level Rider/h:Levels/h:[1]Config/[1][unit:ms]RMS time", 100, 1, 2000, 1) : /(1000);
samp_time_window = sec_time_window : ba.sec2samp;

//get desired level in db and convert to linear
target		= vslider("v:Level Rider/h:Levels/h:[1]Config/[0][unit:dB]Target", 0, -40, +4, 0.1) : ba.db2linear : si.smoo;

//get max change
maxchange   = vslider("v:Level Rider/h:Levels/h:[1]Config/[2][unit:dB]Max change", 3, 0, 20, 0.01) : ba.db2linear : si.smoo;

//stereo link or don't
is_stereo_linked = checkbox("v:Level Rider/[1]Unlink stereo channels?") : _ != 1;

/////////////////////////
// Helpers
////////////////////////
// Taken from BSD-licensed code (c)2006 GRAME
envelop			= abs : max(ba.db2linear(-70)) : ba.linear2db : min(10)  : max ~ -(80.0/ma.SR);

//get current level, RMS
current_rms(x) = _ <: attach(_, envelop(_) : vbargraph("v:Level Rider/h:Levels/h:[0]Input/[unit:dB]Channel %x", -70, 10)) : ba.slidingRMS(samp_time_window);
 
//calculate desired change
desired_change(x) = target / max(current_rms(x), ma.MIN);

//calculate actual change
actual_change(x) = min(maxchange,desired_change(x)) : max(1/maxchange) <: attach(_,ba.linear2db : vbargraph("v:Level Rider/h:Levels/h:[2]Adjustment/[unit:dB]Channel %x",-20,20));

apply_linked_gain(a,b,c,d) = b*((a+c)/2), d*((a+c)/2);
apply_unlinked_gain(a,b,c,d) = (a*b, c*d);
apply_gain(is_stereo_linked, a,b,c,d) = ba.select2stereo(is_stereo_linked, apply_linked_gain(a,b,c,d), apply_unlinked_gain(a,b,c,d));

process		= par(x,2, _ <: (actual_change(x)), _) : apply_gain(is_stereo_linked);
