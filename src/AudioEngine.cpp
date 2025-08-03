#include "AudioEngine.hpp"

AudioEngine::AudioEngine() {
    AudioComponentDescription desc = {0};
    desc.componentType = kAudioUnitType_Output;
    desc.componentSubType = kAudioUnitSubType_DefaultOutput;
    desc.componentManufacturer = kAudioUnitManufacturer_Apple;

    AudioComponent comp = AudioComponentFindNext(NULL, &desc);
    AudioComponentInstanceNew(comp, &audioUnit);
    AudioUnitInitialize(audioUnit);

    AURenderCallbackStruct cb;
    cb.inputProc = RenderCallback;
    cb.inputProcRefCon = &osc; // Pass the oscillator directly
    AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, 
                         kAudioUnitScope_Input, 0, &cb, sizeof(cb));
}

OSStatus AudioEngine::RenderCallback(void *inRefCon, AudioUnitRenderActionFlags*, 
    const AudioTimeStamp*, UInt32, UInt32 nFrames, AudioBufferList *ioData) {
    
    Oscillator* osc = (Oscillator*)inRefCon;
    Float32 *outL = (Float32 *)ioData->mBuffers[0].mData;
    Float32 *outR = (Float32 *)ioData->mBuffers[1].mData;

    for (UInt32 i = 0; i < nFrames; ++i) {
        float s = osc->getNextSample();
        outL[i] = outR[i] = s;
    }
    return noErr;
}

bool AudioEngine::start() { return AudioOutputUnitStart(audioUnit) == noErr; }
void AudioEngine::stop() { AudioOutputUnitStop(audioUnit); }
AudioEngine::~AudioEngine() { AudioComponentInstanceDispose(audioUnit); }