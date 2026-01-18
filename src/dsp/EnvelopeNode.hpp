#pragma once
#include "DspNode.hpp"
#include "../Envelope.hpp"

class EnvelopeNode : public DspNode {
public:
    void setParameters(float a, float d, float s, float r) {
        env.setParameters(a, d, s, r);
    }
    
    void prepare(double sr, int bs) override {
        DspNode::prepare(sr, bs);
        env.setSampleRate(sr);
    }
    
    void enterStage(EnvelopeStage stage) {
        env.enterStage(stage);
    }
    
    bool isActive() const {
        return env.isActive();
    }
    
    void process(DspBuffer& buffer) override {
        int frames = buffer.getNumFrames();
        int channels = buffer.getNumChannels();
        
        for (int i = 0; i < frames; ++i) {
            float level = env.getNextLevel();
            for (int c = 0; c < channels; ++c) {
                buffer.getChannel(c)[i] *= level;
            }
        }
    }
    
private:
    Envelope env;
};