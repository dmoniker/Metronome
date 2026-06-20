import Foundation

struct TapTempoTracker {
    private static let minBPM = 20
    private static let maxBPM = 300

    private var tapTimes: [TimeInterval] = []
    private let maxIdleInterval: TimeInterval = 3.0

    mutating func reset() {
        tapTimes.removeAll()
    }

    mutating func registerTap(
        windowSize: Int,
        at time: TimeInterval = CFAbsoluteTimeGetCurrent()
    ) -> (bpm: Int?, tapIndex: Int) {
        if let last = tapTimes.last, time - last > maxIdleInterval {
            tapTimes.removeAll()
        }

        tapTimes.append(time)
        while tapTimes.count > windowSize {
            tapTimes.removeFirst()
        }

        let tapIndex = (tapTimes.count - 1) % windowSize

        guard tapTimes.count >= 2 else {
            return (nil, tapIndex)
        }

        var intervals: [TimeInterval] = []
        intervals.reserveCapacity(tapTimes.count - 1)
        for index in 1..<tapTimes.count {
            intervals.append(tapTimes[index] - tapTimes[index - 1])
        }

        let average = intervals.reduce(0, +) / Double(intervals.count)
        let minInterval = 60.0 / Double(Self.maxBPM)
        let maxInterval = 60.0 / Double(Self.minBPM)
        guard average >= minInterval, average <= maxInterval else {
            return (nil, tapIndex)
        }

        let bpm = Self.clamp(Int(round(60.0 / average)))
        return (bpm, tapIndex)
    }

    private static func clamp(_ value: Int) -> Int {
        max(minBPM, min(maxBPM, value))
    }
}
