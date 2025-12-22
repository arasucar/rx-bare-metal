#include "Renderer.hpp"
#include <iostream>

static const char* kShaderSource = R"(
#include <metal_stdlib>
using namespace metal;

struct VertexIn {
    float2 position [[attribute(0)]];
    float4 color [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float4 color;
};

struct Uniforms {
    float2 screenSize;
};

vertex VertexOut vertex_main(VertexIn in [[stage_in]], constant Uniforms &uniforms [[buffer(1)]]) {
    VertexOut out;
    // Map pixel coordinates (0..W, 0..H) to clip space (-1..1, 1..-1)
    float x = (in.position.x / uniforms.screenSize.x) * 2.0 - 1.0;
    float y = (1.0 - (in.position.y / uniforms.screenSize.y)) * 2.0 - 1.0;
    out.position = float4(x, y, 0.0, 1.0);
    out.color = in.color;
    return out;
}

fragment float4 fragment_main(VertexOut in [[stage_in]]) {
    return in.color;
}
)";

Renderer::Renderer(id<MTLDevice> device) : device(device) {
    buildPipeline();
}

Renderer::~Renderer() {}

void Renderer::buildPipeline() {
    NSError* error = nil;
    id<MTLLibrary> library = [device newLibraryWithSource:@(kShaderSource) options:nil error:&error];
    if (!library) {
        std::cerr << "Failed to compile shaders: " << [[error localizedDescription] UTF8String] << std::endl;
        return;
    }

    MTLRenderPipelineDescriptor* desc = [[MTLRenderPipelineDescriptor alloc] init];
    desc.vertexFunction = [library newFunctionWithName:@"vertex_main"];
    desc.fragmentFunction = [library newFunctionWithName:@"fragment_main"];
    desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
    
    // Enable Alpha Blending
    desc.colorAttachments[0].blendingEnabled = YES;
    desc.colorAttachments[0].rgbBlendOperation = MTLBlendOperationAdd;
    desc.colorAttachments[0].alphaBlendOperation = MTLBlendOperationAdd;
    desc.colorAttachments[0].sourceRGBBlendFactor = MTLBlendFactorSourceAlpha;
    desc.colorAttachments[0].destinationRGBBlendFactor = MTLBlendFactorOneMinusSourceAlpha;
    desc.colorAttachments[0].sourceAlphaBlendFactor = MTLBlendFactorSourceAlpha;
    desc.colorAttachments[0].destinationAlphaBlendFactor = MTLBlendFactorOneMinusSourceAlpha;

    MTLVertexDescriptor* vertexDesc = [[MTLVertexDescriptor alloc] init];
    vertexDesc.attributes[0].format = MTLVertexFormatFloat2;
    vertexDesc.attributes[0].offset = 0;
    vertexDesc.attributes[0].bufferIndex = 0;
    vertexDesc.attributes[1].format = MTLVertexFormatFloat4;
    vertexDesc.attributes[1].offset = sizeof(float) * 2;
    vertexDesc.attributes[1].bufferIndex = 0;
    vertexDesc.layouts[0].stride = sizeof(Vertex);

    desc.vertexDescriptor = vertexDesc;

    pipelineState = [device newRenderPipelineStateWithDescriptor:desc error:&error];
    if (!pipelineState) {
        std::cerr << "Failed to create pipeline state: " << [[error localizedDescription] UTF8String] << std::endl;
    }
}

void Renderer::setScreenSize(float width, float height) {
    screenWidth = width;
    screenHeight = height;
}

void Renderer::beginFrame(id<MTLCommandBuffer> commandBuffer, MTLRenderPassDescriptor* rpd) {
    currentCommandBuffer = commandBuffer;
    currentEncoder = [currentCommandBuffer renderCommandEncoderWithDescriptor:rpd];
    [currentEncoder setRenderPipelineState:pipelineState];
    vertices.clear();
}

void Renderer::drawRect(float x, float y, float w, float h, vector_float4 color) {
    // Triangle 1
    vertices.push_back({ {x, y}, color });
    vertices.push_back({ {x + w, y}, color });
    vertices.push_back({ {x, y + h}, color });
    
    // Triangle 2
    vertices.push_back({ {x + w, y}, color });
    vertices.push_back({ {x + w, y + h}, color });
    vertices.push_back({ {x, y + h}, color });
}

void Renderer::drawCircle(float cx, float cy, float radius, vector_float4 color) {
    // Fan approximation
    int segments = 32;
    float step = 2.0f * M_PI / segments;
    
    for (int i = 0; i < segments; ++i) {
        float angle1 = i * step;
        float angle2 = (i + 1) * step;
        
        vector_float2 p1 = { cx + radius * cosf(angle1), cy + radius * sinf(angle1) };
        vector_float2 p2 = { cx + radius * cosf(angle2), cy + radius * sinf(angle2) };
        
        // Triangle fan center at cx,cy
        vertices.push_back({ {cx, cy}, color });
        vertices.push_back({ p1, color });
        vertices.push_back({ p2, color });
    }
}

void Renderer::drawLine(float x1, float y1, float x2, float y2, float thickness, vector_float4 color) {
    // Simple thick line using a rectangle rotated
    float dx = x2 - x1;
    float dy = y2 - y1;
    float len = sqrtf(dx*dx + dy*dy);
    if (len == 0) return;
    
    float nx = -dy / len; // Normal
    float ny = dx / len;
    
    float halfW = thickness * 0.5f;
    
    vector_float2 p1 = { x1 + nx * halfW, y1 + ny * halfW };
    vector_float2 p2 = { x1 - nx * halfW, y1 - ny * halfW };
    vector_float2 p3 = { x2 + nx * halfW, y2 + ny * halfW };
    vector_float2 p4 = { x2 - nx * halfW, y2 - ny * halfW };
    
    vertices.push_back({ p1, color });
    vertices.push_back({ p3, color });
    vertices.push_back({ p2, color });
    
    vertices.push_back({ p3, color });
    vertices.push_back({ p4, color });
    vertices.push_back({ p2, color });
}

void Renderer::endFrame() {
    if (vertices.empty()) {
        [currentEncoder endEncoding];
        return;
    }
    
    // Set Uniforms
    struct Uniforms {
        vector_float2 screenSize;
    } uniforms;
    uniforms.screenSize = { screenWidth, screenHeight };
    
    [currentEncoder setVertexBytes:&uniforms length:sizeof(Uniforms) atIndex:1];
    
    // Send vertices
    // Note: setVertexBytes has a limit (4KB usually). For larger UI, we need a buffer.
    // Given the simplicity, let's use a temporary buffer.
    id<MTLBuffer> vertexBuffer = [device newBufferWithBytes:vertices.data()
                                                     length:vertices.size() * sizeof(Vertex)
                                                    options:MTLResourceStorageModeShared];
    
    [currentEncoder setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    [currentEncoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:vertices.size()];
    
    [currentEncoder endEncoding];
    currentEncoder = nil;
    currentCommandBuffer = nil;
}
