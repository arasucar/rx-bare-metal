#pragma once
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <vector>

struct Vertex {
    vector_float2 position;
    vector_float4 color;
};

class Renderer {
public:
    Renderer(id<MTLDevice> device);
    ~Renderer();

    void beginFrame(id<MTLCommandBuffer> commandBuffer, MTLRenderPassDescriptor* rpd);
    void endFrame();
    
    // Primitive Drawing
    void drawRect(float x, float y, float w, float h, vector_float4 color);
    void drawCircle(float cx, float cy, float radius, vector_float4 color);
    void drawLine(float x1, float y1, float x2, float y2, float thickness, vector_float4 color);

    void setScreenSize(float width, float height);

private:
    id<MTLDevice> device;
    id<MTLRenderPipelineState> pipelineState;
    
    std::vector<Vertex> vertices;
    float screenWidth = 800.0f;
    float screenHeight = 600.0f;
    
    id<MTLCommandBuffer> currentCommandBuffer;
    id<MTLRenderCommandEncoder> currentEncoder;
    
    void buildPipeline();
};
