#pragma once
#include "Voice.hpp"
#include <vector>

class SynthEngine {
public:
    SynthEngine();
    void setSampleRate(double sr);
    
    // MIDI handling
    void noteOn(int noteNumber, int velocity);
    void noteOff(int noteNumber);
    
    // Audio processing
    void render(float* outL, float* outR, int numFrames);

private:
    static const int MAX_VOICES = 8;
    Voice voices[MAX_VOICES];
};
