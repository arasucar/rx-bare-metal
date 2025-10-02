#pragma once
#include "Oscillator.hpp"
#include "Envelope.hpp"
#include "Filter.hpp"

class Voice {
public:
    Voice() = default;
    
    void setSampleRate(double sr);
    void noteOn(int noteNumber, int velocity);
    void noteOff();
    bool isActive() const;
    int getNoteNumber() const;
    
    // Parameters
    void setFilterCutoff(float cutoff) { filter.setCutoff(cutoff); }
    void setFilterResonance(float res) { filter.setResonance(res); }
    void setEnvelopeParams(float a, float d, float s, float r) { env.setParameters(a, d, s, r); }
    void setWaveform(Waveform w) { osc.setWaveform(w); }

    // Process one sample
    float render();

private:
    Oscillator osc;
    Envelope env;
    Filter filter;
    int noteNumber = -1;
    float velocity = 0.0f;
    
    // Simple conversion
    double mtof(int note);
};
