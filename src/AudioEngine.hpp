#pragma once
#include "miniaudio.h"
#include "SynthEngine.hpp"
#include "ScopeBuffer.hpp"
#include "dsp/DspBuffer.hpp"

class AudioEngine {
public:
    AudioEngine();
    ~AudioEngine();
    bool start();
    void stop();
    
    SynthEngine& getSynth() { return synth; }
    ScopeBuffer& getScopeBuffer() { return scopeBuffer; }

private:
    ma_device device;
    SynthEngine synth;
    ScopeBuffer scopeBuffer;
    DspBuffer internalBuffer; // Planar buffer for processing

    static void dataCallback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount);
};