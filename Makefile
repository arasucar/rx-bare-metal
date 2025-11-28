CXX = clang++
CXXFLAGS = -std=c++17 -Wall -I./src -I./vendor/imgui -I./vendor/imgui/backends -fobjc-arc
LDFLAGS = -framework AudioToolbox -framework CoreAudio -framework CoreFoundation -framework CoreMIDI -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore -framework IOKit -framework GameController

# ImGui Sources
IMGUI_DIR = vendor/imgui
IMGUI_SRC = $(IMGUI_DIR)/imgui.cpp $(IMGUI_DIR)/imgui_draw.cpp $(IMGUI_DIR)/imgui_tables.cpp $(IMGUI_DIR)/imgui_widgets.cpp
IMGUI_BACKENDS = $(IMGUI_DIR)/backends/imgui_impl_osx.mm $(IMGUI_DIR)/backends/imgui_impl_metal.mm

# Project Sources
SRC = src/main.mm src/AudioEngine.cpp src/Oscillator.cpp src/Voice.cpp src/SynthEngine.cpp src/Envelope.cpp src/Filter.cpp src/MidiManager.cpp src/PresetManager.cpp
OBJ = $(SRC:.cpp=.o)
OBJ := $(OBJ:.mm=.o)
OBJ += $(IMGUI_SRC:.cpp=.o) $(IMGUI_BACKENDS:.mm=.o)

TARGET = build/BareMetalSynth

all: $(TARGET)

$(TARGET): $(OBJ)
	mkdir -p build
	$(CXX) $(OBJ) -o $(TARGET) $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.mm
	$(CXX) $(CXXFLAGS) -x objective-c++ -c $< -o $@

clean:
	rm -f src/*.o vendor/imgui/*.o vendor/imgui/backends/*.o $(TARGET) test_runner

test: src/Oscillator.o src/Envelope.o src/Filter.o
	$(CXX) $(CXXFLAGS) tests/TestRunner.cpp src/Oscillator.o src/Envelope.o src/Filter.o -o test_runner
	./test_runner