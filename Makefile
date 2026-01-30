CXX = clang++
CXXFLAGS = -std=c++17 -Wall -I./include -I./lib -I./vendor/imgui -I./vendor/sokol -fobjc-arc
LDFLAGS = -framework AudioToolbox -framework CoreAudio -framework CoreFoundation -framework CoreMIDI -framework Cocoa -framework Metal -framework MetalKit -framework QuartzCore -framework IOKit -framework GameController

# Project Sources
SRC = src/main.mm src/AudioEngine.cpp src/Voice.cpp src/SynthEngine.cpp src/Envelope.cpp src/MidiManager.cpp src/PresetManager.cpp \
      vendor/imgui/imgui.cpp vendor/imgui/imgui_draw.cpp vendor/imgui/imgui_tables.cpp vendor/imgui/imgui_widgets.cpp

OBJ = $(SRC:.cpp=.o)
OBJ := $(OBJ:.mm=.o)

TARGET = bin/BareMetalSynth

all: deps $(TARGET)

deps:
	mkdir -p lib vendor/imgui vendor/sokol
	@[ -f lib/miniaudio.h ] || curl -L -o lib/miniaudio.h https://raw.githubusercontent.com/mackron/miniaudio/master/miniaudio.h
	@[ -f vendor/sokol/sokol_app.h ] || curl -L -o vendor/sokol/sokol_app.h https://raw.githubusercontent.com/floooh/sokol/master/sokol_app.h
	@[ -f vendor/sokol/sokol_gfx.h ] || curl -L -o vendor/sokol/sokol_gfx.h https://raw.githubusercontent.com/floooh/sokol/master/sokol_gfx.h
	@[ -f vendor/sokol/sokol_glue.h ] || curl -L -o vendor/sokol/sokol_glue.h https://raw.githubusercontent.com/floooh/sokol/master/sokol_glue.h
	@[ -f vendor/sokol/sokol_imgui.h ] || curl -L -o vendor/sokol/sokol_imgui.h https://raw.githubusercontent.com/floooh/sokol/master/util/sokol_imgui.h
	@[ -f vendor/imgui/imgui.h ] || curl -L -o vendor/imgui/imgui.h https://raw.githubusercontent.com/ocornut/imgui/master/imgui.h
	@[ -f vendor/imgui/imgui.cpp ] || curl -L -o vendor/imgui/imgui.cpp https://raw.githubusercontent.com/ocornut/imgui/master/imgui.cpp
	@[ -f vendor/imgui/imgui_draw.cpp ] || curl -L -o vendor/imgui/imgui_draw.cpp https://raw.githubusercontent.com/ocornut/imgui/master/imgui_draw.cpp
	@[ -f vendor/imgui/imgui_tables.cpp ] || curl -L -o vendor/imgui/imgui_tables.cpp https://raw.githubusercontent.com/ocornut/imgui/master/imgui_tables.cpp
	@[ -f vendor/imgui/imgui_widgets.cpp ] || curl -L -o vendor/imgui/imgui_widgets.cpp https://raw.githubusercontent.com/ocornut/imgui/master/imgui_widgets.cpp
	@[ -f vendor/imgui/imconfig.h ] || curl -L -o vendor/imgui/imconfig.h https://raw.githubusercontent.com/ocornut/imgui/master/imconfig.h
	@[ -f vendor/imgui/imgui_internal.h ] || curl -L -o vendor/imgui/imgui_internal.h https://raw.githubusercontent.com/ocornut/imgui/master/imgui_internal.h
	@[ -f vendor/imgui/imstb_rectpack.h ] || curl -L -o vendor/imgui/imstb_rectpack.h https://raw.githubusercontent.com/ocornut/imgui/master/imstb_rectpack.h
	@[ -f vendor/imgui/imstb_textedit.h ] || curl -L -o vendor/imgui/imstb_textedit.h https://raw.githubusercontent.com/ocornut/imgui/master/imstb_textedit.h
	@[ -f vendor/imgui/imstb_truetype.h ] || curl -L -o vendor/imgui/imstb_truetype.h https://raw.githubusercontent.com/ocornut/imgui/master/imstb_truetype.h

$(TARGET): $(OBJ)
	mkdir -p bin
	$(CXX) $(OBJ) -o $(TARGET) $(LDFLAGS)

%.o: %.cpp
	$(CXX) $(CXXFLAGS) -c $< -o $@

%.o: %.mm
	$(CXX) $(CXXFLAGS) -x objective-c++ -c $< -o $@

clean:
	rm -f src/*.o vendor/imgui/*.o $(TARGET)