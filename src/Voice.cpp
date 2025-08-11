#include "Voice.hpp"
#include <cmath>

void Voice::setSampleRate(double sr) {
    osc.setSampleRate(sr);
}

void Voice::noteOn(int note, int vel) {
    noteNumber = note;
    velocity = vel / 127.0f;
    osc.setFrequency(mtof(note));
    active = true;
}

void Voice::noteOff() {
    active = false;
    // noteNumber = -1; // Keep last note for release phase in future
}

bool Voice::isActive() const {
    return active;
}

int Voice::getNoteNumber() const {
    return noteNumber;
}

float Voice::render() {
    if (!active) return 0.0f;
    return osc.getNextSample() * velocity;
}

double Voice::mtof(int note) {
    return 440.0 * std::pow(2.0, (note - 69) / 12.0);
}
