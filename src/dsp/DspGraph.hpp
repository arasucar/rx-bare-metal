#pragma once
#include "DspNode.hpp"
#include <vector>

// Simple graph that owns nodes and calls them in order
class DspGraph : public DspNode {
public:
    void addNode(DspNode* node) {
        nodes.push_back(node);
    }
    
    void prepare(double sr, int bs) override {
        DspNode::prepare(sr, bs);
        for (auto* n : nodes) n->prepare(sr, bs);
    }
    
    // In this simple graph, we assume nodes modify the buffer in sequence
    // (Oscillator writes to it, Filter modifies it)
    void process(DspBuffer& buffer) override {
        for (auto* n : nodes) {
            n->process(buffer);
        }
    }
    
private:
    std::vector<DspNode*> nodes;
};
