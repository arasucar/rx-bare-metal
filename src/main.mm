#define SOKOL_IMPL
#define SOKOL_METAL
#include <sokol_app.h>
#include <sokol_gfx.h>
#include <sokol_glue.h>
#include <imgui.h>
#define SOKOL_IMGUI_IMPL
#include "sokol_imgui.h"

#include "AudioEngine.hpp"
#include "MidiManager.hpp"
#include "PresetManager.hpp"
#include <iostream>
#include <cmath>
#include <vector>
#include <string>

// Global State
static struct {
    sg_pass_action pass_action;
} state;

// Audio & Synth State
std::shared_ptr<AudioEngine> g_audioEngine;
std::shared_ptr<MidiManager> g_midiManager;

// --- THEME CONSTANTS ---
const ImU32 COL_BG_DARK       = IM_COL32(20, 20, 22, 255);
const ImU32 COL_PANEL_BG      = IM_COL32(30, 32, 35, 255);
const ImU32 COL_PANEL_HEADER  = IM_COL32(40, 44, 48, 255);
const ImU32 COL_BORDER        = IM_COL32(60, 60, 65, 255);
const ImU32 COL_ACCENT        = IM_COL32(0, 225, 255, 255); // Neon Cyan
const ImU32 COL_ACCENT_DIM    = IM_COL32(0, 100, 120, 255);
const ImU32 COL_TEXT_LIGHT    = IM_COL32(220, 220, 220, 255);
const ImU32 COL_TEXT_DIM      = IM_COL32(140, 140, 140, 255);
const ImU32 COL_KEY_WHITE     = IM_COL32(200, 200, 200, 255);
const ImU32 COL_KEY_BLACK     = IM_COL32(10, 10, 10, 255);
const ImU32 COL_KEY_ACTIVE    = COL_ACCENT;

// --- WIDGETS ---

// Knob style
// A ring with a value indicator.
bool Knob(const char* label, float* p_value, float v_min, float v_max, const char* format = "%.2f") {
    ImGuiIO& io = ImGui::GetIO();
    ImGuiStyle& style = ImGui::GetStyle();

    float radius = 22.0f;
    float thickness = 4.0f;
    ImVec2 pos = ImGui::GetCursorScreenPos();
    ImVec2 center = ImVec2(pos.x + radius, pos.y + radius);
    float line_height = ImGui::GetTextLineHeight();
    
    // Layout
    ImGui::InvisibleButton(label, ImVec2(radius * 2, radius * 2 + line_height + 5));
    bool is_active = ImGui::IsItemActive();
    bool is_hovered = ImGui::IsItemHovered();
    bool value_changed = false;

    // Input
    if (is_active && io.MouseDelta.y != 0.0f) {
        float step = (v_max - v_min) / 200.0f;
        *p_value -= io.MouseDelta.y * step;
        if (*p_value < v_min) *p_value = v_min;
        if (*p_value > v_max) *p_value = v_max;
        value_changed = true;
    }

    // Draw
    ImDrawList* draw_list = ImGui::GetWindowDrawList();
    
    // Angles
    float angle_min = 3.141592f * 0.75f;
    float angle_max = 3.141592f * 2.25f;
    float t = (*p_value - v_min) / (v_max - v_min);
    float angle = angle_min + (angle_max - angle_min) * t;

    // Background Ring
    draw_list->PathArcTo(center, radius - thickness/2, angle_min, angle_max, 32);
    draw_list->PathStroke(IM_COL32(50, 50, 55, 255), 0, thickness);

    // Active Ring
    if (t > 0.0f) {
        draw_list->PathArcTo(center, radius - thickness/2, angle_min, angle, 32);
        draw_list->PathStroke(is_active ? COL_ACCENT : COL_ACCENT_DIM, 0, thickness);
    }

    // Value/Label Text
    // Draw Value inside
    char val_buf[32];
    sprintf(val_buf, format, *p_value);
    ImVec2 val_size = ImGui::CalcTextSize(val_buf);
    // draw_list->AddText(ImVec2(center.x - val_size.x * 0.5f, center.y - val_size.y * 0.5f), COL_TEXT_LIGHT, val_buf);
    
    // Draw Label below
    ImVec2 text_size = ImGui::CalcTextSize(label);
    draw_list->AddText(ImVec2(center.x - text_size.x * 0.5f, pos.y + radius * 2 + 2), COL_TEXT_DIM, label);

    return value_changed;
}

// Waveform Visualizer
void WaveformVisualizer(const std::vector<float>& buffer, float width, float height) {
    ImGui::BeginChild("Waveform", ImVec2(width, height), false);
    ImDrawList* draw_list = ImGui::GetWindowDrawList();
    ImVec2 p = ImGui::GetCursorScreenPos();
    
    // Background
    draw_list->AddRectFilled(p, ImVec2(p.x + width, p.y + height), IM_COL32(10, 12, 14, 255));
    draw_list->AddRect(p, ImVec2(p.x + width, p.y + height), COL_BORDER);
    
    // Grid
    draw_list->AddLine(ImVec2(p.x, p.y + height/2), ImVec2(p.x + width, p.y + height/2), IM_COL32(40, 40, 40, 255));

    // Waveform
    if (!buffer.empty()) {
        float scale_x = width / (float)buffer.size();
        float scale_y = height / 2.0f; // Amplitude scaling
        
        for (size_t i = 0; i < buffer.size() - 1; ++i) {
            float x1 = p.x + i * scale_x;
            float y1 = p.y + height/2 - buffer[i] * scale_y;
            float x2 = p.x + (i+1) * scale_x;
            float y2 = p.y + height/2 - buffer[i+1] * scale_y;
            
            // Clip to box
            if (y1 < p.y) y1 = p.y; if (y1 > p.y + height) y1 = p.y + height;
            if (y2 < p.y) y2 = p.y; if (y2 > p.y + height) y2 = p.y + height;

            draw_list->AddLine(ImVec2(x1, y1), ImVec2(x2, y2), COL_ACCENT, 1.5f);
        }
    }
    
    ImGui::EndChild();
}

// Envelope Graph (ADSR Visualizer)
void EnvelopeGraph(float a, float d, float s, float r, float width, float height) {
    ImGui::BeginChild("EnvGraph", ImVec2(width, height), false);
    ImDrawList* draw_list = ImGui::GetWindowDrawList();
    ImVec2 p = ImGui::GetCursorScreenPos();
    
    // Background
    draw_list->AddRectFilled(p, ImVec2(p.x + width, p.y + height), IM_COL32(10, 12, 14, 255));
    draw_list->AddRect(p, ImVec2(p.x + width, p.y + height), COL_BORDER);

    // Calculate Points
    // Normalize total time to width (arbitrary scaling)
    float total_w = width * 0.9f;
    float h = height * 0.8f;
    float base_y = p.y + height - 5;
    
    // A, D, R are times. S is level.
    // Assume max time displayed is 2.0s? simpler: just proportional
    float total_time = a + d + r + 0.5f; // +0.5 for hold/sustain view
    float scale_x = total_w / total_time;
    if (scale_x > total_w / 0.5f) scale_x = total_w / 0.5f; // limit max width

    float x_start = p.x + 5;
    ImVec2 pt_start(x_start, base_y);
    ImVec2 pt_attack(x_start + a * scale_x, base_y - h);
    ImVec2 pt_decay(pt_attack.x + d * scale_x, base_y - h * s);
    ImVec2 pt_sustain(pt_decay.x + 0.3f * scale_x, base_y - h * s); // Sustain hold
    ImVec2 pt_release(pt_sustain.x + r * scale_x, base_y);

    // Draw Lines
    draw_list->AddLine(pt_start, pt_attack, COL_ACCENT, 2.0f);
    draw_list->AddLine(pt_attack, pt_decay, COL_ACCENT, 2.0f);
    draw_list->AddLine(pt_decay, pt_sustain, COL_ACCENT, 2.0f);
    draw_list->AddLine(pt_sustain, pt_release, COL_ACCENT, 2.0f);
    
    // Fill
    // (Optional: transparent fill)
    
    ImGui::EndChild();
}

// Piano (re-used but styled)
static int g_lastNote = -1;
void PianoKeyboard(AudioEngine* audio, float width, float height) {
    ImDrawList* draw_list = ImGui::GetWindowDrawList();
    ImVec2 p = ImGui::GetCursorScreenPos();
    
    int startOctave = 3;
    int octaves = 2;
    int numWhiteKeys = octaves * 7;
    float whiteKeyWidth = width / numWhiteKeys;
    float blackKeyWidth = whiteKeyWidth * 0.6f;
    float blackKeyHeight = height * 0.6f;
    
    ImGui::InvisibleButton("keyboard", ImVec2(width, height));
    bool is_active = ImGui::IsItemActive();
    ImVec2 mouse_pos = ImGui::GetMousePos();
    int hoveredNote = -1;

    // Draw White
    for (int i = 0; i < numWhiteKeys; ++i) {
        float x = p.x + i * whiteKeyWidth;
        int octave = startOctave + (i / 7);
        int noteInOctave = i % 7;
        const int map[] = {0, 2, 4, 5, 7, 9, 11};
        int midiNote = 12 * (octave + 1) + map[noteInOctave];
        
        if (ImGui::IsItemHovered() && mouse_pos.x >= x && mouse_pos.x < x + whiteKeyWidth && mouse_pos.y >= p.y && mouse_pos.y < p.y + height) {
            hoveredNote = midiNote;
        }
        
        ImU32 col = (hoveredNote == midiNote && is_active) ? COL_KEY_ACTIVE : COL_KEY_WHITE;
        draw_list->AddRectFilled(ImVec2(x, p.y), ImVec2(x + whiteKeyWidth - 1, p.y + height), col);
    }
    
    // Draw Black
    for (int i = 0; i < numWhiteKeys; ++i) {
        int noteInOctave = i % 7;
        if (noteInOctave == 2 || noteInOctave == 6) continue;
        
        float x = p.x + i * whiteKeyWidth + (whiteKeyWidth * 0.7f);
        int octave = startOctave + (i / 7);
        const int map[] = {0, 2, 4, 5, 7, 9, 11};
        int midiNote = 12 * (octave + 1) + map[noteInOctave] + 1;
        
        if (ImGui::IsItemHovered() && mouse_pos.x >= x && mouse_pos.x < x + blackKeyWidth && mouse_pos.y >= p.y && mouse_pos.y < p.y + blackKeyHeight) {
            hoveredNote = midiNote; // Override
        }
        
        ImU32 col = (hoveredNote == midiNote && is_active) ? COL_KEY_ACTIVE : COL_KEY_BLACK;
        draw_list->AddRectFilled(ImVec2(x, p.y), ImVec2(x + blackKeyWidth, p.y + blackKeyHeight), col);
    }
    
    // Trigger
    if (is_active && hoveredNote != -1) {
        if (hoveredNote != g_lastNote) {
            if (g_lastNote != -1) audio->noteOff(g_lastNote);
            audio->noteOn(hoveredNote, 127);
            g_lastNote = hoveredNote;
        }
    } else if (g_lastNote != -1) {
        audio->noteOff(g_lastNote);
        g_lastNote = -1;
    }
}


void init(void) {
    sg_desc desc = {};
    desc.environment = sglue_environment();
    sg_setup(&desc);

    simgui_desc_t simgui_desc = {};
    simgui_setup(&simgui_desc);

    g_audioEngine = std::make_shared<AudioEngine>();
    g_audioEngine->initialize();
    
    g_midiManager = std::make_shared<MidiManager>(*g_audioEngine->getSynthEngine());
    g_midiManager->initialize();

    state.pass_action.colors[0].load_action = SG_LOADACTION_CLEAR;
    state.pass_action.colors[0].clear_value = { 0.1f, 0.1f, 0.12f, 1.0f }; // Dark Blue/Grey
    
    // Theme
    ImGuiStyle& style = ImGui::GetStyle();
    style.WindowPadding = ImVec2(0,0);
    style.WindowRounding = 0.0f;
    style.Colors[ImGuiCol_WindowBg] = ImVec4(20.0f/255.0f, 20.0f/255.0f, 22.0f/255.0f, 1.0f);
    style.Colors[ImGuiCol_Text] = ImVec4(0.9f, 0.9f, 0.9f, 1.0f);
}

void frame(void) {
    const int width = sapp_width();
    const int height = sapp_height();
    
    // UI State variables (preserved across frames)
    static float masterVol = 0.5f;
    static int wave = 2; // SAW
    static float detune = 0.0f;
    static float blend = 1.0f;
    static float cutoff = 2000.0f;
    static float res = 0.5f;
    static float a = 0.05f, d = 0.2f, s = 0.5f, r = 0.5f;
    static bool firstRun = true;

    simgui_new_frame({ width, height, sapp_frame_duration(), sapp_dpi_scale() });
    
    auto* synth = g_audioEngine->getSynthEngine();

    // Sync engine on first run
    if (firstRun) {
        synth->setWaveform(wave);
        synth->setFilterCutoff(cutoff);
        synth->setFilterResonance(res);
        synth->setEnvelopeParams(a, d, s, r);
        synth->setMasterVolume(masterVol);
        firstRun = false;
    }

    ImGui::SetNextWindowPos(ImVec2(0, 0));
    ImGui::SetNextWindowSize(ImVec2(width, height));
    ImGui::Begin("BareMetalSynth", nullptr, ImGuiWindowFlags_NoTitleBar | ImGuiWindowFlags_NoResize | ImGuiWindowFlags_NoBringToFrontOnFocus);

    // HEADER
    {
        ImGui::BeginChild("Header", ImVec2(width, 40), false);
        ImGui::SameLine(10);
        ImGui::TextColored(ImVec4(0, 0.8f, 1.0f, 1.0f), "BARE METAL SYNTH"); 
        ImGui::SameLine(); ImGui::Text("Created by arasucar");
        
        ImGui::SameLine(width - 150);
        ImGui::SetNextItemWidth(100);
        if (ImGui::SliderFloat("##Master", &masterVol, 0.0f, 1.0f, "Vol %.2f")) {
            synth->setMasterVolume(masterVol);
        }
        ImGui::EndChild();
    }
    
    // MAIN AREA (2 Columns: OSC | FILTER)
    float colWidth = width / 2.0f - 10;
    
    // OSCILLATOR
    ImGui::SetCursorPos(ImVec2(5, 45));
    ImGui::BeginChild("OscA", ImVec2(colWidth, 250), true);
    {
        ImGui::TextColored(ImVec4(0, 1, 1, 1), "OSCILLATOR A");
        ImGui::Separator();
        
        // Visualizer
        static std::vector<float> scopeData;
        g_audioEngine->getScopeBuffer().getSnapshot(scopeData, 512);
        WaveformVisualizer(scopeData, colWidth - 20, 120);
        
        ImGui::Dummy(ImVec2(0, 10));
        
        // Controls
        ImGui::Columns(3, "OscCols", false);
        const char* waves[] = { "SINE", "SQU", "SAW", "TRI" };
        ImGui::SetNextItemWidth(70);
        if (ImGui::Combo("##Wave", &wave, waves, IM_ARRAYSIZE(waves))) {
            synth->setWaveform(wave);
        }
        ImGui::Text("WAVE");
        
        ImGui::NextColumn();
        Knob("DETUNE", &detune, 0.0f, 1.0f);
        
        ImGui::NextColumn();
        Knob("LEVEL", &blend, 0.0f, 1.0f);
        ImGui::Columns(1);
    }
    ImGui::EndChild();
    
    // FILTER
    ImGui::SetCursorPos(ImVec2(15 + colWidth, 45));
    ImGui::BeginChild("Filter", ImVec2(colWidth, 250), true);
    {
        ImGui::TextColored(ImVec4(0, 1, 1, 1), "FILTER");
        ImGui::Separator();
        
        // Fake Response Graph
        ImGui::BeginChild("FilterGraph", ImVec2(colWidth - 20, 120), true);
        ImDrawList* dl = ImGui::GetWindowDrawList();
        ImVec2 p = ImGui::GetCursorScreenPos();
        dl->AddRectFilled(p, ImVec2(p.x + colWidth - 20, p.y + 120), IM_COL32(10, 12, 14, 255));
        
        float x_cutoff = (log10f(cutoff) - log10f(20.0f)) / (log10f(20000.0f) - log10f(20.0f)) * (colWidth - 20);
        dl->AddLine(ImVec2(p.x, p.y + 60), ImVec2(p.x + x_cutoff, p.y + 60), COL_ACCENT, 2.0f);
        dl->AddLine(ImVec2(p.x + x_cutoff, p.y + 60), ImVec2(p.x + colWidth - 20, p.y + 120), COL_ACCENT, 2.0f);
        ImGui::EndChild();
        
        ImGui::Dummy(ImVec2(0, 10));
        
        ImGui::Columns(2, "FiltCols", false);
        if (Knob("CUTOFF", &cutoff, 20.0f, 20000.0f, "%.0f Hz")) {
            synth->setFilterCutoff(cutoff);
        }
        ImGui::NextColumn();
        if (Knob("RES", &res, 0.0f, 1.0f)) {
            synth->setFilterResonance(res);
        }
        ImGui::Columns(1);
    }
    ImGui::EndChild();
    
    // ENVELOPES
    ImGui::SetCursorPos(ImVec2(5, 305));
    ImGui::BeginChild("Env", ImVec2(width - 10, 170), true);
    {
        ImGui::TextColored(ImVec4(0, 1, 1, 1), "ENVELOPE 1");
        ImGui::SameLine(100);
        ImGui::TextDisabled("ENV 2");
        ImGui::SameLine(180);
        ImGui::TextDisabled("ENV 3");
        ImGui::Separator();
        
        ImGui::Columns(2, "EnvLayout", false);
        ImGui::SetColumnWidth(0, 200);
        
        // Graph
        EnvelopeGraph(a, d, s, r, 180, 80);
        
        ImGui::NextColumn();
        
        // Knobs
        ImGui::Columns(4, "EnvKnobs", false);
        bool envChanged = false;
        if (Knob("ATT", &a, 0.01f, 2.0f)) envChanged = true; ImGui::NextColumn();
        if (Knob("DEC", &d, 0.01f, 2.0f)) envChanged = true; ImGui::NextColumn();
        if (Knob("SUS", &s, 0.0f, 1.0f))  envChanged = true; ImGui::NextColumn();
        if (Knob("REL", &r, 0.01f, 5.0f)) envChanged = true;
        
        if (envChanged) {
            synth->setEnvelopeParams(a, d, s, r);
        }

        ImGui::Columns(1);
    }
    ImGui::EndChild();
    
    // PIANO FOOTER
    ImGui::SetCursorPos(ImVec2(0, height - 60));
    PianoKeyboard(g_audioEngine.get(), width, 60);

    ImGui::End();

    sg_pass pass = {};
    pass.action = state.pass_action;
    pass.swapchain = sglue_swapchain();
    sg_begin_pass(&pass);
    simgui_render();
    sg_end_pass();
    sg_commit();
}

void cleanup(void) {
    simgui_shutdown();
    sg_shutdown();
    g_audioEngine->teardown();
}

void event(const sapp_event* ev) {
    simgui_handle_event(ev);
}

sapp_desc sokol_main(int argc, char* argv[]) {
    (void)argc; (void)argv;
    sapp_desc desc = {};
    desc.init_cb = init;
    desc.frame_cb = frame;
    desc.cleanup_cb = cleanup;
    desc.event_cb = event;
    desc.width = 900;
    desc.height = 600;
    desc.window_title = "Bare Metal Synth";
    desc.icon.sokol_default = true;
    return desc;
}