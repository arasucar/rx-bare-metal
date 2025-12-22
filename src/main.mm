#import <Cocoa/Cocoa.h>
#import <Metal/Metal.h>
#import <MetalKit/MetalKit.h>
#include <vector>
#include <string>
#include <cmath>

#include "AudioEngine.hpp"
#include "MidiManager.hpp"
#include "PresetManager.hpp"
#include "Renderer.hpp"

// Global Audio/Synth State
AudioEngine* g_AudioEngine = nullptr;
MidiManager* g_MidiManager = nullptr;

// Synth Parameters
float p_cutoff = 2000.0f;
float p_resonance = 0.3f;
float p_attack = 0.01f;
float p_decay = 0.1f;
float p_sustain = 0.7f;
float p_release = 0.5f;
int p_waveform = 2; // Saw

// UI Interaction State
struct UIState {
    float mouseX = 0;
    float mouseY = 0;
    bool mouseDown = false;
    bool mouseClicked = false;
    
    // Knob Dragging
    int activeKnobId = -1;
    float dragStartY = 0;
    float dragStartValue = 0;
    
    // Keyboard
    int activeNote = -1; // -1 if none
};
UIState g_uiState;

// Colors
const vector_float4 kColorPanel = {0.2f, 0.2f, 0.25f, 1.0f};
const vector_float4 kColorKnobBody = {0.1f, 0.1f, 0.1f, 1.0f};
const vector_float4 kColorKnobLine = {0.9f, 0.9f, 0.9f, 1.0f};
const vector_float4 kColorText = {0.8f, 0.8f, 0.8f, 1.0f}; // We don't have text rendering yet, using colored boxes for labels? No, let's just use layout.

@interface AppViewController : NSViewController <MTKViewDelegate>
@property (nonatomic, strong) MTKView *mtkView;
@property (nonatomic, strong) id <MTLDevice> device;
@property (nonatomic, strong) id <MTLCommandQueue> commandQueue;
@property (nonatomic, assign) Renderer* renderer;
@end

@implementation AppViewController

- (instancetype)initWithNibName:(NSNibName)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.device = MTLCreateSystemDefaultDevice();
        self.commandQueue = [self.device newCommandQueue];
        self.renderer = new Renderer(self.device);
    }
    return self;
}

- (void)dealloc {
    delete self.renderer;
}

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 800, 600)];
    self.mtkView = [[MTKView alloc] initWithFrame:self.view.bounds device:self.device];
    self.mtkView.delegate = self;
    self.mtkView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    [self.view addSubview:self.mtkView];
    
    // Mouse Tracking
    NSTrackingArea* trackingArea = [[NSTrackingArea alloc] initWithRect:self.view.bounds
                                                                options:NSTrackingMouseMoved | NSTrackingActiveInKeyWindow | NSTrackingInVisibleRect
                                                                  owner:self
                                                               userInfo:nil];
    [self.view addTrackingArea:trackingArea];
}

- (void)mouseDown:(NSEvent *)event {
    NSPoint p = [self.view convertPoint:event.locationInWindow fromView:nil];
    g_uiState.mouseX = p.x;
    g_uiState.mouseY = self.view.bounds.size.height - p.y; // Flip Y
    g_uiState.mouseDown = true;
    g_uiState.mouseClicked = true;
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint p = [self.view convertPoint:event.locationInWindow fromView:nil];
    g_uiState.mouseX = p.x;
    g_uiState.mouseY = self.view.bounds.size.height - p.y;
}

- (void)mouseUp:(NSEvent *)event {
    g_uiState.mouseDown = false;
    g_uiState.activeKnobId = -1;
    
    // Release keyboard note if active
    if (g_uiState.activeNote != -1) {
        g_AudioEngine->getSynth().noteOff(g_uiState.activeNote);
        g_uiState.activeNote = -1;
    }
}

- (void)mouseMoved:(NSEvent *)event {
    NSPoint p = [self.view convertPoint:event.locationInWindow fromView:nil];
    g_uiState.mouseX = p.x;
    g_uiState.mouseY = self.view.bounds.size.height - p.y;
}

// -----------------------------------------------------------------------------
// UI WIDGETS
// -----------------------------------------------------------------------------

bool DrawKnob(Renderer* r, int id, float x, float y, float radius, float* value, float minV, float maxV) {
    bool changed = false;
    
    // Interaction
    float dx = g_uiState.mouseX - x;
    float dy = g_uiState.mouseY - y;
    float dist = sqrtf(dx*dx + dy*dy);
    
    if (g_uiState.mouseDown && g_uiState.activeKnobId == -1 && dist < radius) {
        g_uiState.activeKnobId = id;
        g_uiState.dragStartY = g_uiState.mouseY;
        g_uiState.dragStartValue = *value;
    }
    
    if (g_uiState.activeKnobId == id) {
        float dragDy = g_uiState.dragStartY - g_uiState.mouseY;
        float range = maxV - minV;
        float sensitivity = 0.005f * (g_uiState.activeKnobId == id ? 1.0f : 0.0f); // sensitivity
        // Actually, let's map pixels to range
        float change = dragDy * (range / 200.0f); // 200 pixels = full range
        *value = std::max(minV, std::min(maxV, g_uiState.dragStartValue + change));
        changed = true;
    }
    
    // Render
    r->drawCircle(x, y, radius, kColorKnobBody);
    
    // Indicator Line
    float normalized = (*value - minV) / (maxV - minV); // 0..1
    float angle = (0.75f + normalized * 0.75f) * 2.0f * M_PI; // Start at 270 deg (bottom) ??? No.
    // Standard synth knob: 7 o'clock to 5 o'clock
    // 0 = 225 deg (5PI/4), 1 = -45 deg (-PI/4)
    float startAngle = 3.0f * M_PI / 4.0f; // 135 deg?
    float endAngle = 9.0f * M_PI / 4.0f;
    // Let's say 0..1 maps to angleMin..angleMax
    float angleMin = M_PI * 0.75f; // Bottom left
    float angleMax = M_PI * 2.25f; // Bottom right
    
    float currentAngle = angleMin + normalized * (angleMax - angleMin);
    
    float lx = x + radius * 0.8f * cosf(currentAngle);
    float ly = y + radius * 0.8f * sinf(currentAngle); // Correct Y direction?
    // In our coord system (0 top), Y increases down.
    // cos/sin standard math assumes Y up.
    // So actually:
    // angle 0 = Right. angle PI/2 = Down.
    // We want 0 value = Bottom Left. That is roughly 135 deg (3PI/4).
    
    // Let's re-calc math
    lx = x + radius * 0.8f * cosf(currentAngle);
    ly = y + radius * 0.8f * sinf(currentAngle);

    r->drawLine(x, y, lx, ly, 3.0f, kColorKnobLine);
    
    return changed;
}

void DrawKeyboard(Renderer* r, float x, float y, float w, float h) {
    int startNote = 48; // C3
    int numKeys = 14; // C3 to C4+
    float keyWidth = w / numKeys;
    
    // White Keys
    for (int i = 0; i < numKeys; ++i) {
        float kx = x + i * keyWidth;
        vector_float4 color = {0.9f, 0.9f, 0.9f, 1.0f};
        
        // Interaction
        if (g_uiState.mouseDown && 
            g_uiState.mouseX >= kx && g_uiState.mouseX < kx + keyWidth &&
            g_uiState.mouseY >= y && g_uiState.mouseY < y + h) {
            
            color = {0.7f, 0.7f, 0.7f, 1.0f}; // Pressed
            
            // Map index to note (White keys only logic for simplicity first, then add black)
            // C, D, E, F, G, A, B
            int octave = i / 7;
            int noteInOctave = i % 7;
            int semitoneOffsets[] = {0, 2, 4, 5, 7, 9, 11};
            int note = startNote + octave * 12 + semitoneOffsets[noteInOctave];
            
            if (g_uiState.activeNote != note) {
                if (g_uiState.activeNote != -1) g_AudioEngine->getSynth().noteOff(g_uiState.activeNote);
                g_AudioEngine->getSynth().noteOn(note, 100);
                g_uiState.activeNote = note;
            }
        }
        
        r->drawRect(kx + 1, y, keyWidth - 2, h, color);
    }
    
    // Black keys would go on top... omitting for bare metal simplicity for now or add them?
    // Let's add them for "Analog" feel.
    // C# D# F# G# A#
    // Indices: 0, 1, 3, 4, 5 (relative to C)
    // Position: between white keys.
}


- (void)drawInMTKView:(MTKView *)view {
    MTLRenderPassDescriptor *rpd = view.currentRenderPassDescriptor;
    if (rpd == nil) return;
    
    rpd.colorAttachments[0].clearColor = MTLClearColorMake(0.15, 0.15, 0.2, 1); // Dark background
    
    id <MTLCommandBuffer> commandBuffer = [self.commandQueue commandBuffer];
    self.renderer->setScreenSize(view.bounds.size.width, view.bounds.size.height);
    self.renderer->beginFrame(commandBuffer, rpd);

    // ---------------------------------------------------------
    // Draw Panel
    // ---------------------------------------------------------
    self.renderer->drawRect(20, 20, 760, 400, kColorPanel);
    
    // Knobs Row 1: Filter
    // ID 1: Cutoff
    if (DrawKnob(self.renderer, 1, 100, 100, 30, &p_cutoff, 20.0f, 10000.0f)) {
        g_AudioEngine->getSynth().setFilterCutoff(p_cutoff);
    }
    // ID 2: Resonance
    if (DrawKnob(self.renderer, 2, 200, 100, 30, &p_resonance, 0.0f, 0.95f)) {
        g_AudioEngine->getSynth().setFilterResonance(p_resonance);
    }
    
    // Knobs Row 2: ADSR
    float adsrY = 250.0f;
    if (DrawKnob(self.renderer, 3, 100, adsrY, 25, &p_attack, 0.001f, 2.0f)) g_AudioEngine->getSynth().setEnvelopeParams(p_attack, p_decay, p_sustain, p_release);
    if (DrawKnob(self.renderer, 4, 180, adsrY, 25, &p_decay, 0.001f, 2.0f)) g_AudioEngine->getSynth().setEnvelopeParams(p_attack, p_decay, p_sustain, p_release);
    if (DrawKnob(self.renderer, 5, 260, adsrY, 25, &p_sustain, 0.0f, 1.0f)) g_AudioEngine->getSynth().setEnvelopeParams(p_attack, p_decay, p_sustain, p_release);
    if (DrawKnob(self.renderer, 6, 340, adsrY, 25, &p_release, 0.001f, 5.0f)) g_AudioEngine->getSynth().setEnvelopeParams(p_attack, p_decay, p_sustain, p_release);
    
    // Waveform Selector (Simple toggle knob for now)
    float waveFloat = (float)p_waveform;
    if (DrawKnob(self.renderer, 7, 500, 100, 40, &waveFloat, 0.0f, 3.0f)) {
        p_waveform = (int)roundf(waveFloat);
        g_AudioEngine->getSynth().setWaveform(p_waveform);
    }

    // ---------------------------------------------------------
    // Draw Keyboard
    // ---------------------------------------------------------
    DrawKeyboard(self.renderer, 20, 450, 760, 120);

    // ---------------------------------------------------------
    // End Frame
    // ---------------------------------------------------------
    self.renderer->endFrame();
    [commandBuffer presentDrawable:view.currentDrawable];
    [commandBuffer commit];
    
    // Reset one-shot clicks
    g_uiState.mouseClicked = false;
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
    
    // Set initial synth state
    g_AudioEngine->getSynth().setFilterCutoff(p_cutoff);
    g_AudioEngine->getSynth().setFilterResonance(p_resonance);
    g_AudioEngine->getSynth().setEnvelopeParams(p_attack, p_decay, p_sustain, p_release);
    g_AudioEngine->getSynth().setWaveform(p_waveform);

    self.window = [[NSWindow alloc] initWithContentRect:NSMakeRect(100, 100, 800, 600)
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskMiniaturizable
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window setTitle:@"Rx Bare Metal Synth (Analog Edition)"];
    self.viewController = [[AppViewController alloc] initWithNibName:nil bundle:nil];
    self.window.contentViewController = self.viewController;
    [self.window makeKeyAndOrderFront:nil];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    g_AudioEngine->stop();
    delete g_MidiManager;
    delete g_AudioEngine;
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