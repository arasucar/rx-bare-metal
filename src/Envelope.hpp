#pragma once

enum class EnvelopeStage {
    Off,
    Attack,
    Decay,
    Sustain,
    Release
};

class Envelope {
public:
    Envelope();
    
    void setSampleRate(double sr);
    void setParameters(float attack, float decay, float sustain, float release);
    
    void enterStage(EnvelopeStage newStage);
    float getNextLevel();
    EnvelopeStage getCurrentStage() const { return stage; }
    bool isActive() const { return stage != EnvelopeStage::Off; }

private:
    EnvelopeStage stage = EnvelopeStage::Off;
    double sampleRate = 44100.0;
    
    float attackTime = 0.01f;  // seconds
    float decayTime = 0.1f;    // seconds
    float sustainLevel = 0.7f; // 0.0 to 1.0
    float releaseTime = 0.5f;  // seconds
    
    float currentLevel = 0.0f;
};
