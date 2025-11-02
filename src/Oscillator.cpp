#include "Oscillator.hpp"

// Polynomial Band-Limited Step (PolyBLEP)
// t is the phase offset (0..1) relative to the discontinuity
double Oscillator::polyBLEP(double t) {
    double dt = phaseIncrement / (2.0 * M_PI);
    
    // 0 < t < 1
    if (t < dt) {
        t /= dt;
        return t+t - t*t - 1.0;
    }
    // -1 < t < 0
    else if (t > 1.0 - dt) {
        t = (t - 1.0) / dt;
        return t*t + t+t + 1.0;
    }
    return 0.0;
}

float Oscillator::getNextSample() {
    phaseIncrement = (2.0 * M_PI * frequency) / sampleRate;
    double t = phase / (2.0 * M_PI); // Normalized phase 0..1
    
    float sample = 0.0f;
    
    switch (waveform) {
        case Waveform::Sine:
            sample = std::sin(phase);
            break;
            
        case Waveform::Triangle:
        {
            // Triangle can be derived from Square (integration) but direct PolyBLEP is also possible
            // A simple approximation is 8/PI^2 * sin(x) ... but let's stick to the geometric one for now
            // Or use the integrated Square approach which is cleaner
            
            // Naive Triangle
            // sample = -1.0 + (2.0 * phase / (2.0 * M_PI));
            // sample = 2.0f * (std::abs(2.0f * sample) - 1.0f);
            
            // For now, let's leave Triangle naive as it has less high-freq content than Saw/Square
             double value = phase / (2.0 * M_PI); // 0..1
             if (value < 0.5) {
                 sample = -1.0 + 4.0 * value;
             } else {
                 sample = 3.0 - 4.0 * value;
             }
            break;
        }
            
        case Waveform::Saw:
        {
            // Naive Saw: (2 * t) - 1
            double naive = (2.0 * t) - 1.0;
            // Subtract PolyBLEP at the discontinuity (t=0 and t=1)
            sample = naive - polyBLEP(t);
            // Flip to match typical Saw ramp-down if desired, but this is ramp-up
            sample *= -1.0; 
            break;
        }
            
        case Waveform::Square:
        {
            // Naive Square: t < 0.5 ? 1 : -1
            double naive = (t < 0.5) ? 1.0 : -1.0;
            // Discontinuity at 0 and 0.5
            // At 0: minus PolyBLEP(t)
            // At 0.5: plus PolyBLEP((t - 0.5) % 1.0)
            
            double pb = polyBLEP(t);
            pb -= polyBLEP(fmod(t + 0.5, 1.0));
            
            sample = naive + pb;
            break;
        }
    }

    phase += phaseIncrement;
    if (phase >= 2.0 * M_PI) phase -= 2.0 * M_PI;
    
    return sample * 0.2f; // Volume safety
}