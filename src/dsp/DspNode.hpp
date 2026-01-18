#pragma once
#include "DspBuffer.hpp"
#include <vector>
#include <string>

class DspNode {
public:
    virtual ~DspNode() = default;
    
    virtual void prepare(double sampleRate, int blockSize) {
        this->sampleRate = sampleRate;
        this->blockSize = blockSize;
    }
    
    virtual void process(DspBuffer& outputBuffer) = 0;
    
    virtual void reset() {}
    
protected:
    double sampleRate = 44100.0;
    int blockSize = 512;
};