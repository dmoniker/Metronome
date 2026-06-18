import SwiftUI

struct TempoDialView: View {
    @Binding var bpm: Int
    let isRunning: Bool

    @State private var dragStartBPM: Int?
    @State private var dragStartAngle: Double?

    private let minBPM = MetronomeViewModel.minBPM
    private let maxBPM = MetronomeViewModel.maxBPM
    private let dialRange: ClosedRange<Double> = 0.15 ... 0.85

    var body: some View {
        GeometryReader { geometry in
            let size = min(geometry.size.width, geometry.size.height)
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = size / 2 - 12

            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 14)

                Circle()
                    .trim(from: dialRange.lowerBound, to: dialProgress)
                    .stroke(
                        AngularGradient(
                            colors: [
                                Color(red: 0.98, green: 0.45, blue: 0.42),
                                Color(red: 0.72, green: 0.38, blue: 0.95),
                                Color(red: 0.98, green: 0.45, blue: 0.42),
                            ],
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 14, lineCap: .round)
                    )
                    .rotationEffect(.degrees(126))

                ForEach(Array(stride(from: minBPM, through: maxBPM, by: 20)), id: \.self) { tick in
                    let angle = angleForBPM(tick)
                    TickMark(isMajor: tick % 40 == 0)
                        .offset(y: -radius + 6)
                        .rotationEffect(.degrees(angle))
                }

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 1.0, green: 0.55, blue: 0.48),
                                Color(red: 0.78, green: 0.42, blue: 0.98),
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 6, height: radius * 0.55)
                    .offset(y: -radius * 0.28)
                    .rotationEffect(.degrees(angleForBPM(bpm)))
                    .shadow(color: Color(red: 0.9, green: 0.4, blue: 0.5).opacity(0.45), radius: 8)

                Circle()
                    .fill(Color(red: 0.14, green: 0.12, blue: 0.22))
                    .frame(width: 28, height: 28)
                    .overlay {
                        Circle()
                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                    }
            }
            .frame(width: size, height: size)
            .position(center)
            .contentShape(Circle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        handleDrag(at: value.location, center: center)
                    }
                    .onEnded { _ in
                        dragStartBPM = nil
                        dragStartAngle = nil
                    }
            )
        }
        .aspectRatio(1, contentMode: .fit)
        .animation(.spring(response: 0.25, dampingFraction: 0.82), value: bpm)
    }

    private var dialProgress: Double {
        let normalized = Double(bpm - minBPM) / Double(maxBPM - minBPM)
        return dialRange.lowerBound + normalized * (dialRange.upperBound - dialRange.lowerBound)
    }

    private func angleForBPM(_ value: Int) -> Double {
        let normalized = Double(value - minBPM) / Double(maxBPM - minBPM)
        return -234 + normalized * 288
    }

    private func bpmForAngle(_ degrees: Double) -> Int {
        let clamped = min(54, max(-234, degrees))
        let normalized = (clamped + 234) / 288
        return MetronomeViewModel.clamp(minBPM + Int(round(normalized * Double(maxBPM - minBPM))))
    }

    private func handleDrag(at location: CGPoint, center: CGPoint) {
        let dx = location.x - center.x
        let dy = location.y - center.y
        var angle = atan2(dy, dx) * 180 / .pi + 90
        if angle > 180 { angle -= 360 }

        if dragStartBPM == nil {
            dragStartBPM = bpm
            dragStartAngle = angle
        }

        if let startAngle = dragStartAngle, let startBPM = dragStartBPM {
            var delta = angle - startAngle
            if delta > 180 { delta -= 360 }
            if delta < -180 { delta += 360 }
            let bpmDelta = Int(round(delta / 2.4))
            bpm = MetronomeViewModel.clamp(startBPM + bpmDelta)
        } else {
            bpm = bpmForAngle(angle)
        }
    }
}

private struct TickMark: View {
    let isMajor: Bool

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(Color.white.opacity(isMajor ? 0.45 : 0.2))
            .frame(width: isMajor ? 3 : 2, height: isMajor ? 14 : 8)
    }
}
