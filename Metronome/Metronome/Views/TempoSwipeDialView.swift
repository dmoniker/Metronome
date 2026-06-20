import SwiftUI

struct TempoSwipeDialView: View {
    @Binding var bpm: Int

    @State private var dragStartBPM: Int?
    @State private var isDragging = false

    private let minBPM = MetronomeViewModel.minBPM
    private let maxBPM = MetronomeViewModel.maxBPM
    private let pointsPerBPM: CGFloat = 1.5
    private let tapThreshold: CGFloat = 8

    var body: some View {
        GeometryReader { geometry in
            let thumbX = thumbOffset(in: geometry.size.width)

            ZStack {
                Capsule()
                    .fill(Color.white.opacity(0.06))
                    .overlay {
                        Capsule()
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    }

                HStack(spacing: 0) {
                    ForEach(0..<9, id: \.self) { index in
                        Spacer(minLength: 0)
                        RoundedRectangle(cornerRadius: 1)
                            .fill(Color.white.opacity(index == 4 ? 0.35 : 0.15))
                            .frame(width: index == 4 ? 2 : 1, height: index == 4 ? 14 : 8)
                        Spacer(minLength: 0)
                    }
                }
                .padding(.horizontal, 16)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.55, blue: 0.48),
                                Color(red: 0.78, green: 0.42, blue: 0.98),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 28, height: 28)
                    .shadow(color: Color(red: 0.9, green: 0.4, blue: 0.5).opacity(0.35), radius: 6, y: 2)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.25), lineWidth: 1)
                    }
                    .offset(x: thumbX)
                    .animation(isDragging ? nil : .spring(response: 0.22, dampingFraction: 0.86), value: thumbX)
            }
            .contentShape(Capsule())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        let distance = hypot(value.translation.width, value.translation.height)
                        if !isDragging {
                            if distance >= tapThreshold {
                                isDragging = true
                                dragStartBPM = bpm
                            } else {
                                return
                            }
                        }
                        let delta = Int(round(value.translation.width / pointsPerBPM))
                        bpm = MetronomeViewModel.clamp((dragStartBPM ?? bpm) + delta)
                    }
                    .onEnded { value in
                        let distance = hypot(value.translation.width, value.translation.height)
                        if distance < tapThreshold {
                            setBPM(at: value.location.x, width: geometry.size.width)
                        }
                        dragStartBPM = nil
                        isDragging = false
                    }
            )
        }
        .frame(height: 52)
        .accessibilityLabel("Tempo dial")
        .accessibilityValue("\(bpm) beats per minute")
        .accessibilityAdjustableAction { direction in
            switch direction {
            case .increment: bpm = MetronomeViewModel.clamp(bpm + 1)
            case .decrement: bpm = MetronomeViewModel.clamp(bpm - 1)
            @unknown default: break
            }
        }
    }

    private func setBPM(at x: CGFloat, width: CGFloat) {
        let normalized = min(1, max(0, x / width))
        let newBPM = MetronomeViewModel.clamp(
            minBPM + Int(round(normalized * Double(maxBPM - minBPM)))
        )
        guard newBPM != bpm else { return }
        bpm = newBPM
    }

    private func thumbOffset(in width: CGFloat) -> CGFloat {
        let normalized = Double(bpm - minBPM) / Double(maxBPM - minBPM)
        let travel = width / 2 - 22
        return CGFloat(normalized * 2 - 1) * travel
    }
}
