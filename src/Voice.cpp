#include "Voice.hpp"
#include <cmath>

Voice::Voice() {
    graph.addNode(&oscNode);
    graph.addNode(&filterNode);
    graph.addNode(&envNode);
}

void Voice::setSampleRate(double sr) {
    graph.prepare(sr, 512); // Default block size
}

void Voice::noteOn(int note, int vel) {
    noteNumber = note;
    velocity = vel / 127.0f;
    oscNode.setFrequency(mtof(note));
    envNode.enterStage(EnvelopeStage::Attack);
}

void Voice::noteOff() {
    envNode.enterStage(EnvelopeStage::Release);
}

bool Voice::isActive() const {
    return envNode.isActive();
}

int Voice::getNoteNumber() const {
    return noteNumber;
}

void Voice::render(DspBuffer& buffer) {
    graph.process(buffer);
    
    // Apply velocity
    int frames = buffer.getNumFrames();
    int channels = buffer.getNumChannels();
    for (int c = 0; c < channels; ++c) {
        float* data = buffer.getChannel(c);
        for (int i = 0; i < frames; ++i) {
            data[i] *= velocity;
        }
    }
}

double Voice::mtof(int note) {
    return 440.0 * std::pow(2.0, (note - 69) / 12.0);
}