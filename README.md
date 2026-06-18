# Metronome

A clean, modern iOS metronome with precise timing, a pleasant synthesized click, and flexible visual and audio modes.

## Features

- **Tempo control** — drag the dial, tap ±1 steppers, or type BPM directly (20–300)
- **Time signatures** — 4/4 and 3/4 with accented downbeats
- **Visual pulse** — animated ring and beat dots (toggle on/off)
- **Audio pulse** — warm synthesized click with accent on beat 1 (toggle on/off)
- **Modes** — visual only, audio only, or both together

## Requirements

- Xcode 16+
- iOS 17+

## Getting Started

1. Open `Metronome/Metronome.xcodeproj` in Xcode
2. Select a simulator or connected device
3. Run (⌘R)

## Project Structure

```
Metronome/
├── MetronomeApp.swift       App entry point
├── ContentView.swift        Main UI
├── Engine/
│   └── MetronomeEngine.swift   Timing and audio
├── ViewModels/
│   └── MetronomeViewModel.swift
├── Views/
│   ├── TempoDialView.swift
│   └── PulseRingView.swift
└── Models/
    └── TimeSignature.swift
```

## License

MIT
