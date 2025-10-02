#include "SynthEngine.hpp"

SynthEngine::SynthEngine() {
    // Default initialization
}

void SynthEngine::setSampleRate(double sr) {
    for (int i = 0; i < MAX_VOICES; ++i) {
        voices[i].setSampleRate(sr);
    }
}

void SynthEngine::noteOn(int note, int velocity) {
    // Try to find a free voice
    for (int i = 0; i < MAX_VOICES; ++i) {
        if (!voices[i].isActive()) {
            voices[i].noteOn(note, velocity);
            return;
        }
    }
    
    // If all full, steal the first one (simple strategy)
    // Ideally we would steal the oldest or quietest one
    voices[0].noteOn(note, velocity);
}

void SynthEngine::noteOff(int note) {
    for (int i = 0; i < MAX_VOICES; ++i) {
        if (voices[i].isActive() && voices[i].getNoteNumber() == note) {
            voices[i].noteOff();
            // Don't return, in case multiple voices have same note (unlikely but possible)
            // Actually usually we want to turn off just one, but let's stick to this.
        }
    }
}

void SynthEngine::render(float* outL, float* outR, int numFrames) {
    // Clear buffers
    for (int i = 0; i < numFrames; ++i) {
        outL[i] = 0.0f;
        outR[i] = 0.0f;
    }
    
    // Mix voices
    for (int v = 0; v < MAX_VOICES; ++v) {
        if (voices[v].isActive()) {
            for (int i = 0; i < numFrames; ++i) {
                float sample = voices[v].render();
                outL[i] += sample;
                outR[i] += sample;
            }
        }
    }
    
    // Global Volume / Limiting
    for (int i = 0; i < numFrames; ++i) {
        outL[i] *= 0.2f; // Global gain to prevent clipping with multiple voices
        outR[i] *= 0.2f;
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
