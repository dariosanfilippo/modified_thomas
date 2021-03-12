// =============================================================================
//      Modified Thomas complex generator
// ============================================================================= 
//
//  Complex sound generator based on modified Thomas equations.
//  The model is structurally-stable through hyperbolic tangent function
//  saturators and allows for parameters in unstable ranges to explore 
//  different dynamics. Furthermore, this model includes DC-blockers in the 
//  feedback paths to counterbalance a tendency towards fixed-point attractors 
//  – thus enhancing complex behaviours – and obtain signals suitable for audio.
//  Besides the original parameters in the model, this system includes a
//  saturating threshold determining the positive and negative bounds in the
//  equations, while the output peaks are within the [-1.0; 1.0] range.
//
//  The system can be triggered by an impulse or by a constant of arbitrary
//  values for deterministic and reproducable behaviours. Alternatively,
//  the oscillator can be fed with external inputs to be used as a nonlinear
//  distortion unit.
//
// =============================================================================

import("stdfaust.lib");

declare name "Modified Thomas complex generator";
declare author "Dario Sanfilippo";
declare copyright "Copyright (C) 2021 Dario Sanfilippo 
    <sanfilippo.dario@gmail.com>";
declare version "1.1";
declare license "GPL v3.0 license";

thomas(l, b, dt, x_0, y_0, z_0) =   x_level(out * (x / l)) , 
                                    y_level(out * (y / l)) , 
                                    z_level(out * (z / l))
    letrec {
        'x = fi.highpass(1, 10, tanh(l, (x_0 + x + (sin(y) - b * x) * dt)));
        'y = fi.highpass(1, 10, tanh(l, (y_0 + y + (sin(z) - b * y) * dt)));
        'z = fi.highpass(1, 10, tanh(l, (z_0 + z + (sin(x) - b * z) * dt)));
    };

// tanh() saturator with adjustable saturating threshold
tanh(l, x) = l * ma.tanh(x / l);

// smoothing function for click-free parameter variations using 
// a one-pole low-pass with a 20-Hz cut-off frequency.
smooth(x) = fi.pole(pole, x * (1.0 - pole))
    with {
        pole = exp(-2.0 * ma.PI * 20.0 / ma.SR);
    };

// GUI parameters
x_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[5]x[style:dB]", -60, 0)));
y_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[6]y[style:dB]", -60, 0)));
z_level(x) = attach(x , abs(x) : ba.linear2db : 
    levels_group(hbargraph("[7]z[style:dB]", -60, 0)));
global_group(x) = vgroup("[1]Global", x);
levels_group(x) = hgroup("[5]Levels (dB)", x);
b = global_group(hslider("[2]b", 3, -20, 20, .000001) : smooth);  
dt = global_group(
    hslider("[9]dt (time delta)[scale:exp]", 0.1, 0.000001, 1, .000001) : 
        smooth);
input(x) = global_group(nentry("[3]Input value", 1, 0, 10, .000001) <: 
    _ * impulse + _ * checkbox("[1]Constant inputs") + 
        x * checkbox("[0]External inputs"));
impulse = checkbox("[2]Impulse inputs") <: _ - _' : abs;
limit = global_group(
    hslider("[9]Saturation limit[scale:exp]", 4, 1, 1024, .000001) : smooth);
out = global_group(hslider("[9]Output scaling[scale:exp]", 0, 0, 1, .000001) : 
    smooth);

process(x1, x2, x3) = thomas(limit, b, dt, input(x1), input(x2), 
    input(x3));
