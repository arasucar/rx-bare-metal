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
    cb.inputProcRefCon = &synth; // Pass the synth engine
    AudioUnitSetProperty(audioUnit, kAudioUnitProperty_SetRenderCallback, 
                         kAudioUnitScope_Input, 0, &cb, sizeof(cb));
    
    synth.setSampleRate(44100.0);
}

OSStatus AudioEngine::RenderCallback(void *inRefCon, AudioUnitRenderActionFlags*, 
    const AudioTimeStamp*, UInt32, UInt32 nFrames, AudioBufferList *ioData) {
    
    SynthEngine* synth = (SynthEngine*)inRefCon;
    Float32 *outL = (Float32 *)ioData->mBuffers[0].mData;
    Float32 *outR = (Float32 *)ioData->mBuffers[1].mData;

    synth->render(outL, outR, nFrames);
    return noErr;
}

bool AudioEngine::start() { return AudioOutputUnitStart(audioUnit) == noErr; }
void AudioEngine::stop() { AudioOutputUnitStop(audioUnit); }
AudioEngine::~AudioEngine() { AudioComponentInstanceDispose(audioUnit); }