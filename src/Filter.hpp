#pragma once
#include <cmath>
#include <algorithm>

enum class FilterType {
    LowPass,
    HighPass,
    BandPass
};

class Filter {
public:
    Filter();
    void setSampleRate(double sr);
    void setCutoff(float cutoffFreq);
    void setResonance(float res);
    void setType(FilterType type);
    
    float process(float input);

private:
    double sampleRate = 44100.0;
    float cutoff = 1000.0f;
    float resonance = 0.5f;
    FilterType type = FilterType::LowPass;
    
    // State variables
    float buf0 = 0.0f;
    float buf1 = 0.0f;
    
    // Coefficients
    float f = 0.0f;
    float q = 0.0f;
    
    void calculateCoefficients();
};
