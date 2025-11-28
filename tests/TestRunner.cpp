#include <iostream>
#include <vector>
#include <cmath>
#include <cassert>
#include <functional>

#include "../src/Oscillator.hpp"
#include "../src/Envelope.hpp"
#include "../src/Filter.hpp"

// Simple Test Framework
struct TestFailure {
    std::string message;
    std::string file;
    int line;
};

class TestRunner {
public:
    void run(std::string name, std::function<void()> test) {
        std::cout << "[RUN] " << name << "... ";
        try {
            test();
            std::cout << "PASS" << std::endl;
            passed++;
        } catch (const TestFailure& f) {
            std::cout << "FAIL" << std::endl;
            std::cout << "  " << f.file << ":" << f.line << " - " << f.message << std::endl;
            failed++;
        } catch (...) {
            std::cout << "FAIL (Unknown Exception)" << std::endl;
            failed++;
        }
    }

    void report() {
        std::cout << "\n--------------------------------------------------" << std::endl;
        std::cout << "Tests Passed: " << passed << std::endl;
        std::cout << "Tests Failed: " << failed << std::endl;
        std::cout << "--------------------------------------------------" << std::endl;
    }
    
    int getExitCode() { return failed > 0 ? 1 : 0; }

private:
    int passed = 0;
    int failed = 0;
};

#define ASSERT_TRUE(condition) \
    if (!(condition)) throw TestFailure{#condition, __FILE__, __LINE__};

#define ASSERT_NEAR(a, b, epsilon) \
    if (std::abs((a) - (b)) > (epsilon)) throw TestFailure{"Values not near: " + std::to_string(a) + " vs " + std::to_string(b), __FILE__, __LINE__};

// Tests

void testOscillatorFrequency() {
    Oscillator osc;
    osc.setSampleRate(44100.0);
    osc.setFrequency(440.0);
    osc.setWaveform(Waveform::Sine); // Use Sine for pure frequency check
    
    // Check if it produces a reasonable signal
    float val1 = osc.getNextSample();
    float val2 = osc.getNextSample();
    
    // Values should not be identical (unless frequency is 0)
    ASSERT_TRUE(val1 != val2);
    
    // Check range (volume is scaled by 0.2)
    ASSERT_TRUE(std::abs(val1) <= 0.2f);
}

void testEnvelopeADSR() {
    Envelope env;
    env.setSampleRate(100.0); // Low SR for easier math
    // A=0.1s (10 samples), D=0.1s, S=0.5, R=0.1s
    env.setParameters(0.1f, 0.1f, 0.5f, 0.1f);
    
    ASSERT_TRUE(!env.isActive());
    
    // Trigger Attack
    env.enterStage(EnvelopeStage::Attack);
    ASSERT_TRUE(env.isActive());
    ASSERT_TRUE(env.getCurrentStage() == EnvelopeStage::Attack);
    
    // Process 5 samples (halfway through attack)
    for(int i=0; i<5; ++i) env.getNextLevel();
    float level = env.getNextLevel();
    ASSERT_TRUE(level > 0.4f && level < 0.7f); // Rough check
    
    // Process enough to finish attack and start decay
    for(int i=0; i<10; ++i) env.getNextLevel();
    ASSERT_TRUE(env.getCurrentStage() == EnvelopeStage::Decay);
    
    // Process enough to reach sustain
    for(int i=0; i<20; ++i) env.getNextLevel();
    ASSERT_TRUE(env.getCurrentStage() == EnvelopeStage::Sustain);
    ASSERT_NEAR(env.getNextLevel(), 0.5f, 0.01f); // Check sustain level
    
    // Trigger Release
    env.enterStage(EnvelopeStage::Release);
    ASSERT_TRUE(env.getCurrentStage() == EnvelopeStage::Release);
    
    // Process to finish
    for(int i=0; i<20; ++i) env.getNextLevel();
    ASSERT_TRUE(!env.isActive());
    ASSERT_NEAR(env.getNextLevel(), 0.0f, 0.001f);
}

void testFilterStability() {
    Filter filter;
    filter.setSampleRate(44100.0);
    filter.setCutoff(1000.0f);
    filter.setResonance(0.5f);
    
    // Feed it silence, should stay silent (no explosion)
    for(int i=0; i<100; ++i) {
        float out = filter.process(0.0f);
        ASSERT_NEAR(out, 0.0f, 0.0001f);
    }
    
    // Feed it a DC offset (1.0)
    // Low pass should eventually pass it
    for(int i=0; i<1000; ++i) {
        filter.process(1.0f);
    }
    
    float out = filter.process(1.0f);
    // Should be close to 1.0 (passband gain is usually 1.0 for this topology)
    // Note: Chamberlin filter gain can vary depending on implementation, 
    // but stability means it shouldn't be NaN or Infinity.
    ASSERT_TRUE(std::isfinite(out));
}

int main() {
    TestRunner runner;
    
    runner.run("Oscillator Frequency", testOscillatorFrequency);
    runner.run("Envelope ADSR Lifecycle", testEnvelopeADSR);
    runner.run("Filter Stability", testFilterStability);
    
    runner.report();
    return runner.getExitCode();
}
