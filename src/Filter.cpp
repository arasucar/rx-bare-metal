#include "Filter.hpp"

Filter::Filter() {}

void Filter::setSampleRate(double sr) {
    sampleRate = sr;
    calculateCoefficients();
}

void Filter::setCutoff(float cutoffFreq) {
    cutoff = cutoffFreq;
    calculateCoefficients();
}

void Filter::setResonance(float res) {
    // Clamp resonance to safe values
    resonance = std::max(0.0f, std::min(res, 0.99f));
    calculateCoefficients();
}

void Filter::setType(FilterType t) {
    type = t;
}

void Filter::calculateCoefficients() {
    // Basic Chamberlin SVF approximation
    // F = 2 * sin(PI * cutoff / samplerate)
    f = 2.0f * std::sin(M_PI * cutoff / sampleRate);
    
    // Q damping factor
    // q = 1.0 - resonance
    q = 1.0f - resonance;
}

float Filter::process(float input) {
    // State Variable Filter algorithm (Chamberlin version)
    // Low, High, Band, Notch
    
    // Low Pass
    // lp = buf1 + f * buf0
    // hp = input - lp - q * buf0
    // bp = f * hp + buf0
    // buf0 = bp
    // buf1 = lp
    
    float low = buf1 + f * buf0;
    float high = input - low - q * buf0;
    float band = f * high + buf0;
    float notch = high + low;
    
    buf0 = band;
    buf1 = low;
    
    switch (type) {
        case FilterType::LowPass: return low;
        case FilterType::HighPass: return high;
        case FilterType::BandPass: return band;
        default: return low;
    }
}
