#pragma once
#include <AudioToolbox/AudioToolbox.h>
#include "SynthEngine.hpp"
#include "ScopeBuffer.hpp"

class AudioEngine {
public:
    AudioEngine();
    ~AudioEngine();
    bool start();
    void stop();
    
    SynthEngine& getSynth() { return synth; }
    ScopeBuffer& getScopeBuffer() { return scopeBuffer; }

private:
    AudioComponentInstance audioUnit;
    SynthEngine synth;
    ScopeBuffer scopeBuffer;
    
    static OSStatus RenderCallback(void *inRefCon, 
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp, 
                                 UInt32 inBusNumber, 
                                 UInt32 inNumberFrames, 
                                 AudioBufferList *ioData);
};