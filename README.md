# rx-bare-metal

A high-performance, standalone C++17 audio synthesizer with a modern, technical UI.

## Features
- **Polyphonic Synthesis**: 8-voice polyphony.
- **Modular DSP Graph**: Flexible signal routing.
- **UI**: Technical dark theme with real-time visualizers.
- **MIDI Support**: CoreMIDI integration.

## Getting Started

### Prerequisites
- macOS (Metal and CoreAudio required)
- clang++ with C++17 support

### Building the Project
The build system will automatically download the necessary dependencies (`miniaudio`, `sokol`, and `Dear ImGui`) during the first build.

```bash
make
```

### Running the Synthesizer
```bash
./bin/BareMetalSynth
```

## License
MIT
