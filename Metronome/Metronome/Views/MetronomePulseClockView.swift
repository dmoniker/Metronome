import SwiftUI

struct MetronomePulseClockView: View {
    let beatsPerMeasure: Int
    let currentBeat: Int
    let tapTempoBeat: Int?
    let isRunning: Bool
    let pulseTrigger: UUID
    let onTapTempo: () -> Void

    @State private var pulseScale: CGFloat = 1
    @State private var glowOpacity: Double = 0
    @State private var manualPulseTrigger = UUID()

    private var displayedBeat: Int? {
        if isRunning { return currentBeat }
        return tapTempoBeat
    }

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let borderRadius = (size - 8) / 2
            let dotRadius = borderRadius - 18

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.12), lineWidth: 3)
                    .frame(width: size - 8, height: size - 8)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                accentColor.opacity(0.35 + glowOpacity * 0.25),
                                accentColor.opacity(0.05),
                                Color.clear,
                            ],
                            center: .center,
                            startRadius: size * 0.1,
                            endRadius: size * 0.48
                        )
                    )
                    .frame(width: size - 16, height: size - 16)
                    .scaleEffect(pulseScale)

                ForEach(0..<beatsPerMeasure, id: \.self) { index in
                    BeatDot(
                        isActive: displayedBeat == index,
                        isDownbeat: index == 0
                    )
                    .offset(y: -dotRadius)
                    .rotationEffect(.degrees(Double(index) / Double(beatsPerMeasure) * 360))
                }
            }
            .frame(width: size, height: size)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Circle())
            .onTapGesture {
                onTapTempo()
                manualPulseTrigger = UUID()
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onChange(of: pulseTrigger) { _, _ in
            guard isRunning else { return }
            triggerPulse(downbeat: currentBeat == 0)
        }
        .onChange(of: manualPulseTrigger) { _, _ in
            triggerPulse(downbeat: tapTempoBeat == 0)
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
        let beat = displayedBeat ?? 0
        return beat == 0
            ? Color(red: 1.0, green: 0.52, blue: 0.45)
            : Color(red: 0.72, green: 0.48, blue: 0.98)
    }

    private func triggerPulse(downbeat: Bool) {
        pulseScale = 1
        glowOpacity = 0
        withAnimation(.easeOut(duration: 0.12)) {
            pulseScale = downbeat ? 1.12 : 1.06
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
            .fill(isActive ? activeColor : Color.white.opacity(0.35))
            .frame(width: isDownbeat ? 14 : 11, height: isDownbeat ? 14 : 11)
            .overlay {
                Circle()
                    .stroke(Color.white.opacity(isActive ? 0.5 : 0.2), lineWidth: 1)
            }
            .shadow(color: isActive ? activeColor.opacity(0.75) : .clear, radius: 10)
            .animation(.easeOut(duration: 0.1), value: isActive)
    }

    private var activeColor: Color {
        isDownbeat
            ? Color(red: 1.0, green: 0.52, blue: 0.45)
            : Color(red: 0.72, green: 0.48, blue: 0.98)
    }
}
