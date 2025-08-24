#include "Voice.hpp"
#include <cmath>

void Voice::setSampleRate(double sr) {
    osc.setSampleRate(sr);
    env.setSampleRate(sr);
}

void Voice::noteOn(int note, int vel) {
    noteNumber = note;
    velocity = vel / 127.0f;
    osc.setFrequency(mtof(note));
    env.enterStage(EnvelopeStage::Attack);
}

void Voice::noteOff() {
    env.enterStage(EnvelopeStage::Release);
}

bool Voice::isActive() const {
    return env.isActive();
}

int Voice::getNoteNumber() const {
    return noteNumber;
}

float Voice::render() {
    if (!env.isActive()) return 0.0f;
    return osc.getNextSample() * velocity * env.getNextLevel();
}

double Voice::mtof(int note) {
    return 440.0 * std::pow(2.0, (note - 69) / 12.0);
}
