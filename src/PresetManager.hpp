#pragma once
#include "SynthEngine.hpp"
#include <string>

struct Preset {
    std::string name;
    float cutoff;
    float resonance;
    float attack;
    float decay;
    float sustain;
    float release;
    int waveform;
};

class PresetManager {
public:
    static void savePreset(const std::string& filename, const Preset& preset);
    static bool loadPreset(const std::string& filename, Preset& outPreset);
    
    // Hardcoded factory presets for now to avoid external dependencies
    static Preset getFactoryPreset(int index);
    static int getFactoryPresetCount();
    static const char* getFactoryPresetName(int index);
};
