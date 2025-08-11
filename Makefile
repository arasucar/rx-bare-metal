CXX = clang++
CXXFLAGS = -std=c++17 -Wall -I./src
LDFLAGS = -framework AudioToolbox -framework CoreAudio -framework CoreFoundation

SRC = src/main.cpp src/AudioEngine.cpp src/Oscillator.cpp src/Voice.cpp src/SynthEngine.cpp
OBJ = $(SRC:.cpp=.o)
TARGET = build/BareMetalSynth

all: $(TARGET)

$(TARGET): $(OBJ)
	mkdir -p build
	$(CXX) $(OBJ) -o $(TARGET) $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

clean:
	rm -f src/*.o $(TARGET)