import SwiftUI

struct PulseRingView: View {
    let beatsPerMeasure: Int
    let currentBeat: Int
    let isRunning: Bool
    let pulseTrigger: UUID
    let visualEnabled: Bool

    @State private var pulseScale: CGFloat = 1
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            if visualEnabled {
                Circle()
                    .stroke(Color.white.opacity(0.06), lineWidth: 2)
                    .frame(width: 200, height: 200)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.35 + glowOpacity * 0.25),
                                accentColor.opacity(0.05),
                                Color.clear,
                            ],
                            center: .center,
                            startRadius: 20,
                            endRadius: 110
                        )
                    )
                    .frame(width: 220, height: 220)
                    .scaleEffect(pulseScale)

                ForEach(0..<beatsPerMeasure, id: \.self) { index in
                    BeatDot(
                        isActive: isRunning && currentBeat == index,
                        isDownbeat: index == 0
                    )
                    .offset(y: -92)
                    .rotationEffect(.degrees(Double(index) / Double(beatsPerMeasure) * 360))
                }
            } else {
                Circle()
                    .stroke(Color.white.opacity(0.04), lineWidth: 1)
                    .frame(width: 200, height: 200)
            }
        }
        .onChange(of: pulseTrigger) { _, _ in
            guard visualEnabled, isRunning else { return }
            triggerPulse()
        }
        .onChange(of: isRunning) { _, running in
            if !running {
                withAnimation(.easeOut(duration: 0.3)) {
                    pulseScale = 1
                    glowOpacity = 0
                }
            }
        }
    }

    private var accentColor: Color {
        currentBeat == 0
            ? Color(red: 1.0, green: 0.52, blue: 0.45)
            : Color(red: 0.72, green: 0.48, blue: 0.98)
    }

    private func triggerPulse() {
        pulseScale = 1
        glowOpacity = 0
        withAnimation(.easeOut(duration: 0.12)) {
            pulseScale = currentBeat == 0 ? 1.14 : 1.08
            glowOpacity = 1
        }
        withAnimation(.easeOut(duration: 0.35).delay(0.08)) {
            pulseScale = 1
            glowOpacity = 0
        }
    }
}

private struct BeatDot: View {
    let isActive: Bool
    let isDownbeat: Bool

    var body: some View {
        Circle()
            .fill(isActive ? activeColor : Color.white.opacity(0.18))
            .frame(width: isDownbeat ? 12 : 9, height: isDownbeat ? 12 : 9)
            .shadow(color: isActive ? activeColor.opacity(0.6) : .clear, radius: 8)
            .animation(.easeOut(duration: 0.1), value: isActive)
    }

    private var activeColor: Color {
        isDownbeat
            ? Color(red: 1.0, green: 0.52, blue: 0.45)
            : Color(red: 0.72, green: 0.48, blue: 0.98)
    }
}
