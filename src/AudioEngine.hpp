#pragma once
#include <AudioToolbox/AudioToolbox.h>
#include "SynthEngine.hpp"

class AudioEngine {
public:
    AudioEngine();
    ~AudioEngine();
    bool start();
    void stop();
    
    SynthEngine& getSynth() { return synth; }

private:
    AudioComponentInstance audioUnit;
    SynthEngine synth;
    
    static OSStatus RenderCallback(void *inRefCon, 
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp, 
                                 UInt32 inBusNumber, 
                                 UInt32 inNumberFrames, 
                                 AudioBufferList *ioData);
};