#pragma once
#include <vector>
#include <cstring>
#include <algorithm>

// Efficient Audio Buffer for DSP processing
class DspBuffer {
public:
    DspBuffer(int channels, int frames) 
        : numChannels(channels), numFrames(frames) {
        data.resize(channels * frames, 0.0f);
        pointers.resize(channels);
        updatePointers();
    }
    
    void resize(int channels, int frames) {
        if (numChannels == channels && numFrames == frames) return;
        numChannels = channels;
        numFrames = frames;
        data.resize(channels * frames, 0.0f);
        pointers.resize(channels);
        updatePointers();
    }
    
    void clear() {
        std::fill(data.begin(), data.end(), 0.0f);
    }
    
    float* getChannel(int channel) {
        if (channel < 0 || channel >= numChannels) return nullptr;
        return pointers[channel];
    }
    
    void copyFrom(const DspBuffer& source) {
        if (source.numChannels != numChannels || source.numFrames != numFrames) {
            resize(source.numChannels, source.numFrames);
        }
        std::copy(source.data.begin(), source.data.end(), data.begin());
    }

    void add(const DspBuffer& source) {
        int frames = std::min(numFrames, source.numFrames);
        int channels = std::min(numChannels, source.numChannels);
        
        for (int c = 0; c < channels; ++c) {
            float* dst = getChannel(c);
            float* src = ((DspBuffer&)source).getChannel(c);
            for (int i = 0; i < frames; ++i) {
                dst[i] += src[i];
            }
        }
    }
    
    int getNumChannels() const { return numChannels; }
    int getNumFrames() const { return numFrames; }

private:
    int numChannels;
    int numFrames;
    std::vector<float> data; 
    std::vector<float*> pointers; 
    
    void updatePointers() {
        for (int i = 0; i < numChannels; ++i) {
            pointers[i] = &data[i * numFrames];
        }
    }
};