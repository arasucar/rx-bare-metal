#include "Envelope.hpp"
#include <algorithm>

Envelope::Envelope() {}

void Envelope::setSampleRate(double sr) {
    sampleRate = sr;
}

void Envelope::setParameters(float attack, float decay, float sustain, float release) {
    attackTime = attack;
    decayTime = decay;
    sustainLevel = sustain;
    releaseTime = release;
}

void Envelope::enterStage(EnvelopeStage newStage) {
    stage = newStage;
    if (stage == EnvelopeStage::Off) {
        currentLevel = 0.0f;
    }
}

float Envelope::getNextLevel() {
    switch (stage) {
        case EnvelopeStage::Attack: {
            float increment = 1.0f / (attackTime * sampleRate);
            currentLevel += increment;
            if (currentLevel >= 1.0f) {
                currentLevel = 1.0f;
                enterStage(EnvelopeStage::Decay);
            }
            break;
        }
        case EnvelopeStage::Decay: {
            float decrement = (1.0f - sustainLevel) / (decayTime * sampleRate);
            currentLevel -= decrement;
            if (currentLevel <= sustainLevel) {
                currentLevel = sustainLevel;
                enterStage(EnvelopeStage::Sustain);
            }
            break;
        }
        case EnvelopeStage::Sustain:
            currentLevel = sustainLevel;
            break;
        case EnvelopeStage::Release: {
            float decrement = sustainLevel / (releaseTime * sampleRate);
            currentLevel -= decrement;
            if (currentLevel <= 0.0f) {
                currentLevel = 0.0f;
                enterStage(EnvelopeStage::Off);
            }
            break;
        }
        case EnvelopeStage::Off:
            currentLevel = 0.0f;
            break;
    }
    return currentLevel;
}
