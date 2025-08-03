#include "Oscillator.hpp"

float Oscillator::getNextSample() {
    float sample = std::sin(phase);
    double phaseIncrement = (2.0 * M_PI * frequency) / sampleRate;
    phase += phaseIncrement;
    if (phase >= 2.0 * M_PI) phase -= 2.0 * M_PI;
    return sample * 0.2f; // Volume safety
}