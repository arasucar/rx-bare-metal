#pragma once
#include <vector>
#include <atomic>

// A simple lock-free ring buffer for passing audio samples to the UI.
// Single Producer (Audio Thread) -> Single Consumer (UI Thread)
class ScopeBuffer {
public:
    ScopeBuffer(size_t size = 4096) : buffer(size), size(size) {
        writeIndex.store(0);
        readIndex.store(0);
    }

    void write(const float* data, size_t count) {
        size_t currentWrite = writeIndex.load(std::memory_order_relaxed);
        for (size_t i = 0; i < count; ++i) {
            buffer[currentWrite] = data[i];
            currentWrite = (currentWrite + 1) % size;
        }
        writeIndex.store(currentWrite, std::memory_order_release);
    }

    // Read latest N samples for visualization
    // We don't strictly "consume" them (advance read pointer) in a queue sense,
    // we just want a snapshot of the most recent data.
    void getSnapshot(std::vector<float>& outSnapshot, size_t count) {
        size_t currentWrite = writeIndex.load(std::memory_order_acquire);
        
        // We want the 'count' samples ending at 'currentWrite'
        // If buffer is 1000, currentWrite is 100, and we want 200 samples:
        // We need indices: 900..999, then 0..99
        
        outSnapshot.resize(count);
        
        // Start index (wrapping around backwards)
        size_t start = (currentWrite + size - count) % size;
        
        for (size_t i = 0; i < count; ++i) {
            outSnapshot[i] = buffer[(start + i) % size];
        }
    }

private:
    std::vector<float> buffer;
    size_t size;
    std::atomic<size_t> writeIndex;
    std::atomic<size_t> readIndex; // Not strictly needed for snapshotting but good practice
};
