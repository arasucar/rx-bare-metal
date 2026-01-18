#define MINIAUDIO_IMPLEMENTATION
#include "AudioEngine.hpp"
#include <iostream>

AudioEngine::AudioEngine() : internalBuffer(2, 512) {
    ma_device_config config = ma_device_config_init(ma_device_type_playback);
    config.playback.format   = ma_format_f32;
    config.playback.channels = 2;
    config.sampleRate        = 44100;
    config.dataCallback      = dataCallback;
    config.pUserData         = this;

    if (ma_device_init(NULL, &config, &device) != MA_SUCCESS) {
        std::cerr << "Failed to initialize miniaudio device." << std::endl;
    }
    
    synth.setSampleRate(44100.0);
}

AudioEngine::~AudioEngine() {
    ma_device_uninit(&device);
}

void AudioEngine::dataCallback(ma_device* pDevice, void* pOutput, const void* pInput, ma_uint32 frameCount) {
    AudioEngine* engine = (AudioEngine*)pDevice->pUserData;
    
    // Ensure our internal planar buffer matches the requested size
    engine->internalBuffer.resize(2, frameCount);
    engine->internalBuffer.clear();
    
    // Render from synth to planar buffer
    engine->synth.render(engine->internalBuffer);
    
    // Convert planar to interleaved for miniaudio output
    float* out = (float*)pOutput;
    float* pL = engine->internalBuffer.getChannel(0);
    float* pR = engine->internalBuffer.getChannel(1);
    
    if (pL && pR) {
        for (ma_uint32 i = 0; i < frameCount; ++i) {
            out[i*2] = pL[i];
            out[i*2 + 1] = pR[i];
        }
        // Write to scope for visualization
        engine->scopeBuffer.write(pL, frameCount);
    }
}

bool AudioEngine::start() {
    return ma_device_start(&device) == MA_SUCCESS;
}

void AudioEngine::stop() {
    ma_device_stop(&device);
}