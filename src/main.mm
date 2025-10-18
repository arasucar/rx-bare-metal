#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include "imgui.h"
#include "imgui_impl_metal.h"
#include "imgui_impl_osx.h"

#include "AudioEngine.hpp"
#include "MidiManager.hpp"
#include <vector>

// Global Audio/Synth State
AudioEngine* g_AudioEngine = nullptr;
MidiManager* g_MidiManager = nullptr;

// Synth Parameters for UI
float p_cutoff = 2000.0f;
float p_resonance = 0.3f;
float p_attack = 0.01f;
float p_decay = 0.1f;
float p_sustain = 0.7f;
float p_release = 0.5f;
int p_waveform = 2; // Saw

// Scope Data
std::vector<float> scopeData(512, 0.0f);

@interface AppViewController : NSViewController <MTKViewDelegate>
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@end

@implementation AppViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.device = MTLCreateSystemDefaultDevice();
        self.commandQueue = [self.device newCommandQueue];
        
        IMGUI_CHECKVERSION();
        ImGui::CreateContext();
        ImGui::StyleColorsDark();
        
        ImGui_ImplOSX_Init(self.view);
        ImGui_ImplMetal_Init(self.device);
    }
    return self;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:self.device];
    self.mtkView.delegate = self;
    self.mtkView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.view addSubview:self.mtkView];
}

- (void)drawInMTKView:(MTKView *)view {
    ImGui_ImplMetal_NewFrame(view.currentRenderPassDescriptor);
    ImGui_ImplOSX_NewFrame(view);
    ImGui::NewFrame();

    // ---------------------------------------------------------
    // UI Logic
    // ---------------------------------------------------------
    ImGui::SetNextWindowPos(ImVec2(10, 10), ImGuiCond_FirstUseEver);
    ImGui::SetNextWindowSize(ImVec2(400, 400), ImGuiCond_FirstUseEver);
    
    ImGui::Begin("Rx Bare Metal Synth");
    
    ImGui::Text("Oscillators");
    const char* items[] = { "Sine", "Triangle", "Saw", "Square" };
    if (ImGui::Combo("Waveform", &p_waveform, items, IM_ARRAYSIZE(items))) {
        g_AudioEngine->getSynth().setWaveform(p_waveform);
    }
    
    ImGui::Separator();
    ImGui::Text("Filter");
    if (ImGui::SliderFloat("Cutoff", &p_cutoff, 20.0f, 10000.0f, "%.1f Hz", ImGuiSliderFlags_Logarithmic)) {
        g_AudioEngine->getSynth().setFilterCutoff(p_cutoff);
    }
    if (ImGui::SliderFloat("Resonance", &p_resonance, 0.0f, 0.95f)) {
        g_AudioEngine->getSynth().setFilterResonance(p_resonance);
    }
    
    ImGui::Separator();
    ImGui::Text("Envelope (ADSR)");
    bool envChanged = false;
    envChanged |= ImGui::SliderFloat("Attack", &p_attack, 0.001f, 2.0f);
    envChanged |= ImGui::SliderFloat("Decay", &p_decay, 0.001f, 2.0f);
    envChanged |= ImGui::SliderFloat("Sustain", &p_sustain, 0.0f, 1.0f);
    envChanged |= ImGui::SliderFloat("Release", &p_release, 0.001f, 5.0f);
    if (envChanged) {
        g_AudioEngine->getSynth().setEnvelopeParams(p_attack, p_decay, p_sustain, p_release);
    }

    ImGui::Separator();
    ImGui::Text("Oscilloscope");
    
    // Fetch latest audio data
    if (g_AudioEngine) {
        g_AudioEngine->getScopeBuffer().getSnapshot(scopeData, scopeData.size());
    }
    
    ImGui::PlotLines("##Scope", scopeData.data(), (int)scopeData.size(), 0, NULL, -1.0f, 1.0f, ImVec2(0, 100));

    ImGui::Separator();
    ImGui::Text("Application Average %.3f ms/frame (%.1f FPS)", 1000.0f / ImGui::GetIO().Framerate, ImGui::GetIO().Framerate);
    ImGui::End();

    // ---------------------------------------------------------
    // Rendering
    // ---------------------------------------------------------
    ImGui::Render();
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    MTLRenderPassDescriptor *renderPassDescriptor = view.currentRenderPassDescriptor;
    if (renderPassDescriptor != nil) {
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.1, 0.1, 0.1, 1);
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadActionClear;
        renderPassDescriptor.colorAttachments[0].storeAction = MTLStoreActionStore;
        
        id <MTLRenderCommandEncoder> renderEncoder = [commandBuffer renderCommandEncoderWithDescriptor:renderPassDescriptor];
        [renderEncoder pushDebugGroup:@"ImGui Mesh"];
        ImGui_ImplMetal_RenderDrawData(ImGui::GetDrawData(), commandBuffer, renderEncoder);
        [renderEncoder popDebugGroup];
        [renderEncoder endEncoding];
        [commandBuffer presentDrawable:view.currentDrawable];
    }
    [commandBuffer commit];
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {}

@end

@interface AppDelegate : NSObject <NSApplicationDelegate>
@property (nonatomic, strong) NSWindow *window;
@property (nonatomic, strong) AppViewController *viewController;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    g_AudioEngine = new AudioEngine();
    g_MidiManager = new MidiManager(g_AudioEngine->getSynth());
    
    g_AudioEngine->start();
    g_MidiManager->initialize();
    
    // Set initial synth state to match UI defaults
    g_AudioEngine->getSynth().setFilterCutoff(p_cutoff);
    g_AudioEngine->getSynth().setFilterResonance(p_resonance);
    g_AudioEngine->getSynth().setEnvelopeParams(p_attack, p_decay, p_sustain, p_release);
    g_AudioEngine->getSynth().setWaveform(p_waveform);

    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 800, 600)
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window setTitle:@"Rx Bare Metal Synth"];
    self.viewController = [[AppViewController alloc] initWithNibName:nil bundle:nil];
    self.window.contentViewController = self.viewController;
    [self.window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    g_AudioEngine->stop();
    delete g_MidiManager;
    delete g_AudioEngine;
    
    ImGui_ImplMetal_Shutdown();
    ImGui_ImplOSX_Shutdown();
    ImGui::DestroyContext();
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        [app setDelegate:delegate];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        [app run];
    }
    return 0;
}
