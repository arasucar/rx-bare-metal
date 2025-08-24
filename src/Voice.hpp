#pragma once
#include "Oscillator.hpp"
#include "Envelope.hpp"

class Voice {
public:
    Voice() = default;
    
    void setSampleRate(double sr);
    void noteOn(int noteNumber, int velocity);
    void noteOff();
    bool isActive() const;
    int getNoteNumber() const;
    
    // Process one sample
    float render();

private:
    Oscillator osc;
    Envelope env;
    int noteNumber = -1;
    float velocity = 0.0f;
    
    // Simple conversion
    double mtof(int note);
};
