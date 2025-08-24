#include <iostream>
#include "AudioEngine.hpp"

int main() {
    AudioEngine engine;
    if (engine.start()) {
        std::cout << "Synth active. Playing C Major chord..." << std::endl;
        
        // Trigger a chord to test polyphony and envelope
        engine.getSynth().noteOn(60, 100); // C4
        engine.getSynth().noteOn(64, 100); // E4
        engine.getSynth().noteOn(67, 100); // G4
        
        std::cout << "Press Enter to release the notes (hear the release tail)..." << std::endl;
        std::cin.get();

        engine.getSynth().noteOff(60);
        engine.getSynth().noteOff(64);
        engine.getSynth().noteOff(67);

        std::cout << "Notes released. Press Enter again to stop the engine..." << std::endl;
        std::cin.get();
        
        engine.stop();
    }
    return 0;
}