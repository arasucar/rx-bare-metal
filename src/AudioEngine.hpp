#pragma once
#include <AudioToolbox/AudioToolbox.h>
#include "Oscillator.hpp"

class AudioEngine {
public:
    AudioEngine();
    ~AudioEngine();
    bool start();
    void stop();

private:
    AudioComponentInstance audioUnit;
    Oscillator osc;
    
    static OSStatus RenderCallback(void *inRefCon, 
                                 AudioUnitRenderActionFlags *ioActionFlags,
                                 const AudioTimeStamp *inTimeStamp, 
                                 UInt32 inBusNumber, 
                                 UInt32 inNumberFrames, 
                                 AudioBufferList *ioData);
};