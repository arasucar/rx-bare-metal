#include <iostream>
#include "AudioEngine.hpp"

int main() {
    AudioEngine engine;
    if (engine.start()) {
        std::cout << "Synth active. Press Enter to stop..." << std::endl;
        std::cin.get();
        engine.stop();
    }
    return 0;
}