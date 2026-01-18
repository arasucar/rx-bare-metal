#pragma once
#include "dsp/DspGraph.hpp"
#include "dsp/OscillatorNode.hpp"
#include "dsp/FilterNode.hpp"
#include "dsp/EnvelopeNode.hpp"

class Voice {
public:
    Voice();
    
    void setSampleRate(double sr);
    void noteOn(int noteNumber, int velocity);
    void noteOff();
    bool isActive() const;
    int getNoteNumber() const;
    
    // Process audio for this voice
    void render(DspBuffer& buffer);

    // Parameters
    void setFilterCutoff(float cutoff) { filterNode.setCutoff(cutoff); }
    void setFilterResonance(float res) { filterNode.setResonance(res); }
    void setEnvelopeParams(float a, float d, float s, float r) { envNode.setParameters(a, d, s, r); }
    void setWaveform(Waveform w) { oscNode.setWaveform(w); }

private:
    DspGraph graph;
    OscillatorNode oscNode;
    FilterNode filterNode;
    EnvelopeNode envNode;
    
    int noteNumber = -1;
    float velocity = 0.0f;
    
    double mtof(int note);
};