#include "PresetManager.hpp"
#include <fstream>
#include <iostream>

// Simple text-based format: key=value
void PresetManager::savePreset(const std::string& filename, const Preset& preset) {
    std::ofstream file(filename);
    if (file.is_open()) {
        file << "name=" << preset.name << "\n";
        file << "cutoff=" << preset.cutoff << "\n";
        file << "resonance=" << preset.resonance << "\n";
        file << "attack=" << preset.attack << "\n";
        file << "decay=" << preset.decay << "\n";
        file << "sustain=" << preset.sustain << "\n";
        file << "release=" << preset.release << "\n";
        file << "waveform=" << preset.waveform << "\n";
        file.close();
        std::cout << "Saved preset to " << filename << std::endl;
    }
}

bool PresetManager::loadPreset(const std::string& filename, Preset& outPreset) {
    std::ifstream file(filename);
    if (!file.is_open()) return false;
    
    std::string line;
    while (std::getline(file, line)) {
        size_t delimiterPos = line.find('=');
        if (delimiterPos == std::string::npos) continue;
        
        std::string key = line.substr(0, delimiterPos);
        std::string value = line.substr(delimiterPos + 1);
        
        if (key == "name") outPreset.name = value;
        else if (key == "cutoff") outPreset.cutoff = std::stof(value);
        else if (key == "resonance") outPreset.resonance = std::stof(value);
        else if (key == "attack") outPreset.attack = std::stof(value);
        else if (key == "decay") outPreset.decay = std::stof(value);
        else if (key == "sustain") outPreset.sustain = std::stof(value);
        else if (key == "release") outPreset.release = std::stof(value);
        else if (key == "waveform") outPreset.waveform = std::stoi(value);
    }
    return true;
}

static const int PRESET_COUNT = 3;
static Preset factoryPresets[PRESET_COUNT] = {
    { "Default Saw", 2000.0f, 0.3f, 0.01f, 0.1f, 0.7f, 0.5f, 2 },
    { "Soft Pad", 800.0f, 0.1f, 0.5f, 0.5f, 0.8f, 1.0f, 1 }, // Triangle
    { "Square Bass", 300.0f, 0.6f, 0.01f, 0.2f, 0.4f, 0.2f, 3 } // Square
};

Preset PresetManager::getFactoryPreset(int index) {
    if (index >= 0 && index < PRESET_COUNT) return factoryPresets[index];
    return factoryPresets[0];
}

int PresetManager::getFactoryPresetCount() { return PRESET_COUNT; }

const char* PresetManager::getFactoryPresetName(int index) {
    if (index >= 0 && index < PRESET_COUNT) return factoryPresets[index].name.c_str();
    return "";
}
