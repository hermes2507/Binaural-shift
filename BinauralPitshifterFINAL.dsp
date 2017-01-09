
import("music.lib");
import("filter.lib");
import("stdfaust.lib");

//Wah de Julius Smith
crybabyEffect(wah) = *(gs(s)) : tf2(1,-1,0,a1s(s),a2s(s))
with { // wah = pedal angle in [0,1]

s = 0.999; 
Q  = pow(2.0,(2.0*(1.0-wah)+1.0));
fr = 450.0*pow(2.0,2.3*wah);
g  = 0.1*pow(4.0,wah);


frn = fr/SR; // pole frequency (cycles per sample)
R = 1 - PI*frn/Q; // pole radius
theta = 2*PI*frn; // pole angle
a1 = 0-2.0*R*cos(theta); // biquad coeff
a2 = R*R;                // biquad coeff

a1s(s) = a1 :smooth(s); // "dezippering"
a2s(s) = a2 :smooth(s);
gs(s) =  g  :smooth(s);


};

wahGroup(x)=vgroup("[3]WahWah Fx",x);

bp = wahGroup(checkbox("[7]Wah Bypass [osc:/1/fader16 0 1]"));



wahEffect = _:crybabyEffect((wahdpth)*osc(oscilator))
with{
    
    oscilator = wahGroup(vslider("[5]WahFreq [osc:/1/fader8]",0,0,50,0.1));
    
    wahdpth = wahGroup(vslider("[6]WahDepth [osc:/1/fader9]",0,0,1,0.01));

    

};


echoFunction = _:((+:fdelay(44100,echoDelay))~*(feedback))
with{
    echoGroup(x) = hgroup("[1]Delay",x);

    echoDelay= echoGroup(vslider("[4]Time [osc:/1/fader13] [tooltip: Echo que va desde 0.001 a 1 s] [unit: ms]", 0.05, 0.001, 1, 0.001)*SR);

    feedback = echoGroup(vslider("[5]Feedback [osc:/1/fader5 0 0.99] [tooltip: va de 0 a 0.99]",0,0,0.99,0.01):smooth(0.999));

};

panGroup(x) = vgroup("[0]Pan",x);


binaural_final = _,_ <: (gain*(type2*pitch+type*pitch3:echoFunction:ba.bypass1(bp,wahEffect)),gain*(type2*pitch+type*pitch2:echoFunction:ba.bypass1(bp,wahEffect)) : *(wet),*(wet)), *(1-wet), *(1-wet) +> _,_
with{

    pitchGroup(x) = hgroup("[2]Pitch Shift",x);
    
    //Pitchshifter Simple
    transpose (w, x, s, sig)  =
        fdelay1s(d,sig)*fmin(d/x,1) + fdelay1s(d+w,sig)*(1-fmin(d/x,1))
        with {
            i = 1 - pow(2, s/12);
            d = i : (+ : +(w) : fmod(_,w)) ~ _;
            };


    pitchshifter = transpose(1000,10,pitchGroup(vslider("[0]Pitch1 [osc:/1/xy1/0] [osc:/1/fader6]", 0, -12, +12, 0.01))
                 //hslider("window (samp)", 1000, 50, 10000, 1)
                 //hslider("xfade (samples)", 10, 1, 10000, 1)
                );


    pitchshifter2 = transpose(1000,10,pitchGroup(vslider("[1]Pitch2 [osc:/1/xy1/1] [osc:/1/fader7]", 0, -12, +12, 0.01))
                //hslider("window2 (samp)", 1000, 50, 10000, 1)
                //hslider("xfade2 (samp)", 10, 1, 10000, 1)
                );


    pan=(1-(depth*osc(freqs)/2+0.5)):smooth(0.999)
    with{

        

        freqs=panGroup(vslider("[2]Pan Freq[osc:/1/fader2]",0,0,10,0.01));

        depth=panGroup(vslider("[3]Pan Depth[osc:/1/fader3]",0,0,1,0.01));

//[osc:/accxyz/0 -10 10] [osc:/1/fader2] [osc:/1/fader3]

    };

type = panGroup(checkbox("[0]Binaural Mode [osc:/1/fader15 0 1]"));
        type2 = type == 0;
        
    pitch = (pitchshifter*(1-pan)+pitchshifter2*(pan));
    pitch2=(pitchshifter*(pan)+pitchshifter2*(pan));
    pitch3=(pitchshifter*(1-pan)+pitchshifter2*(1-pan));

    
    masterGroup(x)=hgroup("[4]General",x);

    wet = masterGroup(vslider("[6]Wet [osc:/1/fader12 0 1] [style:center]",0,0,1,0.01));
    gain= masterGroup(vslider("[7]Master [osc:/1/fader10 0 1]",0.6,0,1,0.01));

};


y = _:echoFunction:wahEffect<:pitch,pitch;


//pitch3=(pitchshifter*(pan)+pitchshifter2*(1-pan));

fxctrl(g,w,Fx) =  _,_ <: (*(g),*(g) : Fx : *(w),*(w)), *(1-w), *(1-w) +> _,_;

//process = _:echoFunction:wahEffect<:(type2*pitch+type*pitch3),(type2*pitch+type*pitch2);


//process = _,_ <: (gain*(type2*pitch+type*pitch3:echoFunction:wahEffect),gain*(type2*pitch+type*pitch2:echoFunction:wahEffect) : *(wet),*(wet)), *(1-wet), *(1-wet) +> _,_;

process = hgroup("BinauralShift",binaural_final);






