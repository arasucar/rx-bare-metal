#include <iostream>
#include "AudioEngine.hpp"

int main() {
    AudioEngine engine;
    if (engine.start()) {
        std::cout << "Synth active. Press Enter to stop..." << std::endl;
        
        // Trigger a chord to test polyphony
        engine.getSynth().noteOn(60, 100); // C4
        engine.getSynth().noteOn(64, 100); // E4
        engine.getSynth().noteOn(67, 100); // G4
        
        std::cin.get();
        engine.stop();
    }
    return 0;
}