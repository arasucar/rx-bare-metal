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
    
    // Parameters
    void setFilterCutoff(float cutoff);
    void setFilterResonance(float res);
    void setEnvelopeParams(float a, float d, float s, float r);
    void setWaveform(int waveformIndex); // 0=Sine, 1=Tri, 2=Saw, 3=Square

private:
    static const int MAX_VOICES = 8;
    Voice voices[MAX_VOICES];
};
