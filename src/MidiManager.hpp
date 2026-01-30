#pragma once
#include <CoreMIDI/CoreMIDI.h>
#include "SynthEngine.hpp"

class MidiManager {
public:
    MidiManager(SynthEngine& synth);
    ~MidiManager();
    
    bool initialize();
    
private:
    MIDIClientRef midiClient;
    MIDIPortRef inputPort;
    SynthEngine& synth;
    
    static void MidiCallback(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcRefCon);
    void handleMidiMessage(const uint8_t* data, size_t length);
};
