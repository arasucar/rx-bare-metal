#pragma once
#include "DspNode.hpp"
#include <algorithm>

enum class FilterType { LowPass, HighPass, BandPass };

class FilterNode : public DspNode {
public:
    void setCutoff(float c) { cutoff = c; calculateCoefficients(); }
    void setResonance(float r) { resonance = std::max(0.0f, std::min(r, 0.99f)); calculateCoefficients(); }
    
    // In a modular graph, a filter processes an input. 
    // We could accept an input buffer or just process in-place.
    // Let's assume in-place for this simple chain.
    void process(DspBuffer& buffer) override {
        int frames = buffer.getNumFrames();
        int channels = buffer.getNumChannels();
        
        for (int c = 0; c < channels; ++c) {
            float* data = buffer.getChannel(c);
            
            // We need separate state per channel
            if (state.size() < (size_t)channels) state.resize(channels);
            
            for (int i = 0; i < frames; ++i) {
                float input = data[i];
                float low = state[c].buf1 + f * state[c].buf0;
                float high = input - low - q * state[c].buf0;
                float band = f * high + state[c].buf0;
                
                state[c].buf0 = band;
                state[c].buf1 = low;
                
                data[i] = low; // LowPass only for now
            }
        }
    }
    
private:
    float cutoff = 2000.0f;
    float resonance = 0.5f;
    float f = 0.0f, q = 0.0f;
    
    struct FilterState { float buf0 = 0; float buf1 = 0; };
    std::vector<FilterState> state;

    void calculateCoefficients() {
        f = 2.0f * std::sin(M_PI * cutoff / sampleRate);
        q = 1.0f - resonance;
    }
};
