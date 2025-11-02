#pragma once
#include <cmath>

enum class Waveform {
    Sine,
    Triangle,
    Saw,
    Square
};

class Oscillator {
public:
    void setSampleRate(double sr) { sampleRate = sr; }
    void setFrequency(double freq) { frequency = freq; }
    void setWaveform(Waveform wave) { waveform = wave; }
    float getNextSample();

private:
    double polyBLEP(double t);
    
    double phase = 0.0;
    double frequency = 440.0;
    double sampleRate = 44100.0;
    double phaseIncrement = 0.0;
    Waveform waveform = Waveform::Saw; // Default to Saw for richer sound
};