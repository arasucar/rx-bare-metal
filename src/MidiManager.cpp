#include "MidiManager.hpp"
#include <iostream>

MidiManager::MidiManager(SynthEngine& s) : synth(s), midiClient(0), inputPort(0) {}

MidiManager::~MidiManager() {
    if (inputPort) MIDIPortDispose(inputPort);
    if (midiClient) MIDIClientDispose(midiClient);
}

bool MidiManager::initialize() {
    OSStatus status;
    
    status = MIDIClientCreate(CFSTR("BareMetalSynth MIDI Client"), NULL, NULL, &midiClient);
    if (status != noErr) return false;
    
    status = MIDIInputPortCreate(midiClient, CFSTR("Input Port"), MidiCallback, this, &inputPort);
    if (status != noErr) return false;
    
    // Connect to all available sources
    ItemCount sourceCount = MIDIGetNumberOfSources();
    for (ItemCount i = 0; i < sourceCount; ++i) {
        MIDIEndpointRef source = MIDIGetSource(i);
        MIDIPortConnectSource(inputPort, source, NULL);
    }
    
    return true;
}

void MidiManager::MidiCallback(const MIDIPacketList *pktlist, void *readProcRefCon, void *srcRefCon) {
    MidiManager* manager = static_cast<MidiManager*>(readProcRefCon);
    MIDIPacket *packet = const_cast<MIDIPacket*>(&pktlist->packet[0]);
    
    for (UInt32 i = 0; i < pktlist->numPackets; ++i) {
        manager->handleMidiMessage(packet->data, packet->length);
        packet = MIDIPacketNext(packet);
    }
}

void MidiManager::handleMidiMessage(const uint8_t* data, size_t length) {
    if (length < 3) return;
    
    uint8_t status = data[0] & 0xF0;
    uint8_t note = data[1];
    uint8_t velocity = data[2];
    
    if (status == 0x90) { // Note On
        if (velocity > 0) {
            synth.noteOn(note, velocity);
        } else {
            synth.noteOff(note); // Velocity 0 is often Note Off
        }
    } else if (status == 0x80) { // Note Off
        synth.noteOff(note);
    }
}
