import Combine
import Foundation
import SwiftUI

@MainActor
final class MetronomeViewModel: ObservableObject {
    static let minBPM = 20
    static let maxBPM = 300

    @Published var bpm: Int = 120 {
        didSet {
            let clamped = Self.clamp(bpm)
            if clamped != bpm {
                bpm = clamped
                return
            }
            engine.configure(bpm: bpm, beatsPerMeasure: timeSignature.beatsPerMeasure)
        }
    }

    @Published var timeSignature: TimeSignature = .fourFour {
        didSet {
            tapTempoTracker.reset()
            tapTempoBeat = nil
            engine.configure(bpm: bpm, beatsPerMeasure: timeSignature.beatsPerMeasure)
        }
    }

    @Published var audioEnabled = true {
        didSet { engine.audioEnabled = audioEnabled }
    }

    @Published private(set) var isRunning = false
    @Published private(set) var currentBeat = 0
    @Published private(set) var tapTempoBeat: Int?
    @Published var pulseTrigger = UUID()

    let engine = MetronomeEngine()
    private var tapTempoTracker = TapTempoTracker()
    private var cancellables = Set<AnyCancellable>()

    init() {
        engine.configure(bpm: bpm, beatsPerMeasure: timeSignature.beatsPerMeasure)
        engine.audioEnabled = audioEnabled

        engine.$isRunning
            .receive(on: DispatchQueue.main)
            .assign(to: &$isRunning)

        engine.$currentBeat
            .receive(on: DispatchQueue.main)
            .assign(to: &$currentBeat)

        engine.$pulseTrigger
            .receive(on: DispatchQueue.main)
            .assign(to: &$pulseTrigger)
    }

    func togglePlayback() {
        engine.toggle()
    }

    func incrementBPM() {
        bpm = Self.clamp(bpm + 1)
    }

    func decrementBPM() {
        bpm = Self.clamp(bpm - 1)
    }

    func setBPMFromText(_ text: String) {
        guard let value = Int(text.filter(\.isNumber)), value > 0 else { return }
        bpm = Self.clamp(value)
    }

    func registerTapTempo() {
        let windowSize = timeSignature.beatsPerMeasure
        let result = tapTempoTracker.registerTap(windowSize: windowSize)
        tapTempoBeat = result.tapIndex
        if let newBPM = result.bpm {
            bpm = newBPM
        }
    }

    static func clamp(_ value: Int) -> Int {
        max(minBPM, min(maxBPM, value))
    }
}
