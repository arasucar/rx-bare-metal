#pragma once
#include "miniaudio.h"
#include "SynthEngine.hpp"
#include "ScopeBuffer.hpp"
#include "dsp/DspBuffer.hpp"
#include <memory>

class AudioEngine {
public:
    AudioEngine();
    ~AudioEngine();
    bool start();
    void stop();
    
    // API aliases for compatibility with main.mm
    void initialize() { start(); }
    void teardown() { stop(); }
    
    SynthEngine* getSynthEngine() { return &synth; }
    
    void noteOn(int note, int velocity) { synth.noteOn(note, velocity); }
    void noteOff(int note) { synth.noteOff(note); }
    void setMasterVolume(float vol) { synth.setMasterVolume(vol); }

    SynthEngine& getSynth() { return synth; }
    ScopeBuffer& getScopeBuffer() { return scopeBuffer; }

private:
    ma_device device;
    SynthEngine synth;
    ScopeBuffer scopeBuffer;
    DspBuffer internalBuffer; // Planar buffer for processing

    static void dataCallback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount);
};