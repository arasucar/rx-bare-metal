#pragma once
#include "DspNode.hpp"
#include <cmath>

enum class Waveform { Sine, Triangle, Saw, Square };

class OscillatorNode : public DspNode {
public:
    void setFrequency(float freq) { frequency = freq; }
    void setWaveform(Waveform w) { waveform = w; }
    
    void process(DspBuffer& outputBuffer) override {
        float* channel0 = outputBuffer.getChannel(0);
        float* channel1 = outputBuffer.getNumChannels() > 1 ? outputBuffer.getChannel(1) : nullptr;
        int frames = outputBuffer.getNumFrames();
        
        // Simple PolyBLEP implementation inline or calling a helper
        for (int i = 0; i < frames; ++i) {
            phaseIncrement = (2.0 * M_PI * frequency) / sampleRate;
            
            float sample = 0.0f;
            double t = phase / (2.0 * M_PI);
            
            // Re-using the logic from the old Oscillator.cpp for simplicity but modularized
            switch (waveform) {
                case Waveform::Sine: sample = std::sin(phase); break;
                case Waveform::Saw: 
                    // Naive Saw for now to verify graph, restore PolyBLEP later if needed or copy it
                    sample = -1.0 + 2.0 * t; 
                    sample -= polyBLEP(t); // Anti-aliased
                    sample *= -1.0;
                    break;
                case Waveform::Square:
                {
                    double naive = (t < 0.5) ? 1.0 : -1.0;
                    double pb = polyBLEP(t);
                    pb -= polyBLEP(fmod(t + 0.5, 1.0));
                    sample = naive + pb;
                    break;
                }
                case Waveform::Triangle:
                     double value = phase / (2.0 * M_PI);
                     if (value < 0.5) sample = -1.0 + 4.0 * value;
                     else sample = 3.0 - 4.0 * value;
                    break;
            }
            
            phase += phaseIncrement;
            if (phase >= 2.0 * M_PI) phase -= 2.0 * M_PI;
            
            // Write to all channels (mono source)
            channel0[i] = sample * 0.5f; // Headroom
            if (channel1) channel1[i] = sample * 0.5f;
        }
    }
    
private:
    double phase = 0.0;
    double frequency = 440.0;
    double phaseIncrement = 0.0;
    Waveform waveform = Waveform::Saw;
    
    double polyBLEP(double t) {
        double dt = phaseIncrement / (2.0 * M_PI);
        if (t < dt) {
            t /= dt;
            return t+t - t*t - 1.0;
        } else if (t > 1.0 - dt) {
            t = (t - 1.0) / dt;
            return t*t + t+t + 1.0;
        }
        return 0.0;
    }
};
