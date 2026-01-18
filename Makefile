CXX = clang++
CXXFLAGS = -std=c++17 -Wall -I./src -fobjc-arc
LDFLAGS = -framework AudioToolbox -framework CoreAudio -framework CoreFoundation -framework CoreMIDI -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore -framework IOKit -framework GameController

# Project Sources
SRC = src/main.mm src/AudioEngine.cpp src/Voice.cpp src/SynthEngine.cpp src/Envelope.cpp src/MidiManager.cpp src/PresetManager.cpp src/Renderer.mm
OBJ = $(SRC:.cpp=.o)
OBJ := $(OBJ:.mm=.o)

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
	rm -f src/*.o $(TARGET)