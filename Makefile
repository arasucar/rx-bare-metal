CXX = clang++
CXXFLAGS = -std=c++17 -Wall -I./include -I./lib -I./vendor/imgui -I./vendor/sokol -fobjc-arc
LDFLAGS = -framework AudioToolbox -framework CoreAudio -framework CoreFoundation -framework CoreMIDI -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore -framework IOKit -framework GameController

# Project Sources
SRC = src/main.mm src/AudioEngine.cpp src/Voice.cpp src/SynthEngine.cpp src/Envelope.cpp src/MidiManager.cpp src/PresetManager.cpp \
      vendor/imgui/imgui.cpp vendor/imgui/imgui_draw.cpp vendor/imgui/imgui_tables.cpp vendor/imgui/imgui_widgets.cpp

OBJ = $(SRC:.cpp=.o)
OBJ := $(OBJ:.mm=.o)

TARGET = bin/BareMetalSynth

all: $(TARGET)

$(TARGET): $(OBJ)
	mkdir -p bin
	$(CXX) $(OBJ) -o $(TARGET) $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.mm
	$(CXX) $(CXXFLAGS) -x objective-c++ -c $< -o $@

clean:
	rm -f src/*.o vendor/imgui/*.o $(TARGET)