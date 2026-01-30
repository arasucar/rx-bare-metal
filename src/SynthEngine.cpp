#include "SynthEngine.hpp"

SynthEngine::SynthEngine() {
}

void SynthEngine::setSampleRate(double sr) {
    for (int i = 0; i < MAX_VOICES; ++i) {
        voices[i].setSampleRate(sr);
    }
}

void SynthEngine::noteOn(int note, int velocity) {
    for (int i = 0; i < MAX_VOICES; ++i) {
        if (!voices[i].isActive()) {
            voices[i].noteOn(note, velocity);
            return;
        }
    }
    voices[0].noteOn(note, velocity);
}

void SynthEngine::noteOff(int note) {
    for (int i = 0; i < MAX_VOICES; ++i) {
        if (voices[i].isActive() && voices[i].getNoteNumber() == note) {
            voices[i].noteOff();
        }
    }
}

void SynthEngine::render(DspBuffer& outputBuffer) {
    outputBuffer.clear();
    int numFrames = outputBuffer.getNumFrames();
    
    // We'll use a temporary buffer for each voice to mix into the main one
    static DspBuffer voiceBuffer(2, 1024);
    voiceBuffer.resize(2, numFrames);
    
    for (int v = 0; v < MAX_VOICES; ++v) {
        if (voices[v].isActive()) {
            voiceBuffer.clear();
            voices[v].render(voiceBuffer);
            outputBuffer.add(voiceBuffer);
        }
    }
    
    // Global Volume / Limiting
    float* outL = outputBuffer.getChannel(0);
    float* outR = outputBuffer.getChannel(1);
    for (int i = 0; i < numFrames; ++i) {
        outL[i] *= masterVolume;
        outR[i] *= masterVolume;
    }
}

void SynthEngine::setFilterCutoff(float cutoff) {
    for (int i = 0; i < MAX_VOICES; ++i) voices[i].setFilterCutoff(cutoff);
}

void SynthEngine::setFilterResonance(float res) {
    for (int i = 0; i < MAX_VOICES; ++i) voices[i].setFilterResonance(res);
}

void SynthEngine::setEnvelopeParams(float a, float d, float s, float r) {
    for (int i = 0; i < MAX_VOICES; ++i) voices[i].setEnvelopeParams(a, d, s, r);
}

void SynthEngine::setWaveform(int waveformIndex) {
    Waveform w = Waveform::Saw;
    if (waveformIndex == 0) w = Waveform::Sine;
    else if (waveformIndex == 1) w = Waveform::Triangle;
    else if (waveformIndex == 2) w = Waveform::Saw;
    else if (waveformIndex == 3) w = Waveform::Square;
    
    for (int i = 0; i < MAX_VOICES; ++i) voices[i].setWaveform(w);
}
