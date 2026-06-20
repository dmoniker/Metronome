import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct ContentView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var viewModel = MetronomeViewModel()
    @FocusState private var tempoFieldFocused: Bool
    @State private var tempoText = "120"

    var body: some View {
        ZStack {
            background

            VStack(spacing: 28) {
                header
                pulseSection
                tempoSection
                stepperRow
                signaturePicker
                toggleSection
                playButton
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
        }
        .onChange(of: viewModel.bpm) { _, newValue in
            if !tempoFieldFocused {
                tempoText = "\(newValue)"
            }
        }
        .onAppear {
            tempoText = "\(viewModel.bpm)"
        }
        .onChange(of: scenePhase) { _, phase in
            #if canImport(UIKit)
            switch phase {
            case .active:
                UIApplication.shared.isIdleTimerDisabled = viewModel.isRunning
            default:
                UIApplication.shared.isIdleTimerDisabled = false
            }
            #endif
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                Color(red: 0.07, green: 0.06, blue: 0.14),
                Color(red: 0.12, green: 0.09, blue: 0.22),
                Color(red: 0.08, green: 0.07, blue: 0.16),
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
        .overlay {
            RadialGradient(
                colors: [
                    Color(red: 0.55, green: 0.28, blue: 0.72).opacity(0.18),
                    Color.clear,
                ],
                center: .top,
                startRadius: 40,
                endRadius: 420
            )
            .ignoresSafeArea()
        }
    }

    private var header: some View {
        VStack(spacing: 4) {
            Text("Metronome")
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.55))
                .textCase(.uppercase)
                .tracking(2.5)

            Text(viewModel.isRunning ? "Playing" : "Ready")
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(viewModel.isRunning ? Color(red: 0.98, green: 0.55, blue: 0.48) : Color.white.opacity(0.35))
        }
    }

    private var pulseSection: some View {
        PulseRingView(
            beatsPerMeasure: viewModel.timeSignature.beatsPerMeasure,
            currentBeat: viewModel.currentBeat,
            isRunning: viewModel.isRunning,
            pulseTrigger: viewModel.pulseTrigger,
            visualEnabled: viewModel.visualEnabled
        )
        .frame(height: 230)
    }

    private var tempoSection: some View {
        VStack(spacing: 16) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                TextField("120", text: $tempoText)
                    .keyboardType(.numberPad)
                    .multilineTextAlignment(.center)
                    .font(.system(size: 72, weight: .thin, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 180)
                    .focused($tempoFieldFocused)
                    .onSubmit { commitTempoText() }
                    .onChange(of: tempoFieldFocused) { _, focused in
                        if !focused { commitTempoText() }
                    }

                Text("BPM")
                    .font(.system(size: 22, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.white.opacity(0.4))
                    .padding(.bottom, 10)
            }

            TempoDialView(bpm: $viewModel.bpm, isRunning: viewModel.isRunning)
                .frame(height: 220)
                .padding(.horizontal, 8)
        }
    }

    private var stepperRow: some View {
        HStack(spacing: 20) {
            StepperButton(symbol: "minus") {
                viewModel.decrementBPM()
                tempoText = "\(viewModel.bpm)"
            }

            Text("Adjust tempo")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(Color.white.opacity(0.35))

            StepperButton(symbol: "plus") {
                viewModel.incrementBPM()
                tempoText = "\(viewModel.bpm)"
            }
        }
    }

    private var signaturePicker: some View {
        HStack(spacing: 0) {
            ForEach(TimeSignature.allCases) { signature in
                Button {
                    viewModel.timeSignature = signature
                } label: {
                    Text(signature.rawValue)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background {
                            if viewModel.timeSignature == signature {
                                Capsule()
                                    .fill(Color.white.opacity(0.12))
                            }
                        }
                }
                .buttonStyle(.plain)
                .foregroundStyle(
                    viewModel.timeSignature == signature
                        ? Color.white
                        : Color.white.opacity(0.45)
                )
            }
        }
        .padding(4)
        .background {
            Capsule()
                .fill(Color.white.opacity(0.06))
                .overlay {
                    Capsule()
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                }
        }
    }

    private var toggleSection: some View {
        HStack(spacing: 12) {
            ToggleChip(
                title: "Visual",
                icon: "circle.dotted",
                isOn: $viewModel.visualEnabled
            )
            ToggleChip(
                title: "Audio",
                icon: "speaker.wave.2.fill",
                isOn: $viewModel.audioEnabled
            )
        }
    }

    private var playButton: some View {
        Button(action: viewModel.togglePlayback) {
            HStack(spacing: 10) {
                Image(systemName: viewModel.isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text(viewModel.isRunning ? "Stop" : "Start")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background {
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: viewModel.isRunning
                                ? [Color(red: 0.55, green: 0.28, blue: 0.38), Color(red: 0.42, green: 0.18, blue: 0.32)]
                                : [Color(red: 0.98, green: 0.45, blue: 0.42), Color(red: 0.72, green: 0.38, blue: 0.95)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(
                        color: (viewModel.isRunning ? Color.red : Color(red: 0.9, green: 0.4, blue: 0.5)).opacity(0.35),
                        radius: 16,
                        y: 6
                    )
            }
        }
        .buttonStyle(.plain)
        .padding(.top, 4)
    }

    private func commitTempoText() {
        viewModel.setBPMFromText(tempoText)
        tempoText = "\(viewModel.bpm)"
    }
}

private struct StepperButton: View {
    let symbol: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: symbol)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .overlay {
                            Circle()
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        }
                }
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleChip: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                Text(title)
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
            }
            .foregroundStyle(isOn ? Color.white : Color.white.opacity(0.4))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(isOn ? Color.white.opacity(0.12) : Color.white.opacity(0.05))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(Color.white.opacity(isOn ? 0.18 : 0.08), lineWidth: 1)
                    }
            }
        }
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.18), value: isOn)
    }
}

#Preview {
    ContentView()
}
