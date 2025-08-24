#include "Oscillator.hpp"

float Oscillator::getNextSample() {
    float sample = 0.0f;
    
    switch (waveform) {
        case Waveform::Sine:
            sample = std::sin(phase);
            break;
        case Waveform::Triangle:
            // Map 0..2PI to -1..1..-1
            // 0..PI -> -1..1, PI..2PI -> 1..-1
            {
                double t = -1.0 + (2.0 * phase / (2.0 * M_PI));
                sample = 2.0f * (std::abs(2.0f * t) - 1.0f); // Standard Triangle mapping
                // Simpler version:
                // value = 2/PI * asin(sin(phase)) - actually that's accurate but slow
                // Linear mapping:
                double value = phase / (2.0 * M_PI); // 0..1
                if (value < 0.5) {
                    sample = -1.0 + 4.0 * value;
                } else {
                    sample = 3.0 - 4.0 * value;
                }
            }
            break;
        case Waveform::Saw:
            // Map 0..2PI to -1..1
            sample = -1.0 + 2.0 * (phase / (2.0 * M_PI));
            break;
        case Waveform::Square:
            sample = (phase < M_PI) ? 1.0f : -1.0f;
            break;
    }

    double phaseIncrement = (2.0 * M_PI * frequency) / sampleRate;
    phase += phaseIncrement;
    if (phase >= 2.0 * M_PI) phase -= 2.0 * M_PI;
    
    return sample * 0.2f; // Volume safety
}