#pragma once
#include <cmath>

class Oscillator {
public:
    void setSampleRate(double sr) { sampleRate = sr; }
    void setFrequency(double freq) { frequency = freq; }
    float getNextSample();

private:
    double phase = 0.0;
    double frequency = 440.0;
    double sampleRate = 44100.0;
};