#include <iostream>
#include "AudioEngine.hpp"
#include "MidiManager.hpp"

int main() {
    AudioEngine engine;
    MidiManager midi(engine.getSynth());

    if (engine.start()) {
        if (midi.initialize()) {
            std::cout << "Synth active and MIDI initialized." << std::endl;
            std::cout << "Connect a MIDI keyboard or use a virtual MIDI bus to play." << std::endl;
        } else {
            std::cout << "Synth active but MIDI failed to initialize." << std::endl;
        }

        std::cout << "Press Enter to stop..." << std::endl;
        std::cin.get();
        
        engine.stop();
    }
    return 0;
}