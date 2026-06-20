import AVFoundation
import Foundation
#if canImport(UIKit)
import UIKit
#endif

@MainActor
final class MetronomeEngine: ObservableObject {
    @Published private(set) var currentBeat = 0
    @Published private(set) var isRunning = false
    @Published var pulseTrigger = UUID()

    var audioEnabled = true {
        didSet { if !audioEnabled { stopAudioIfNeeded() } }
    }

    private let audioEngine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var accentBuffer: AVAudioPCMBuffer?
    private var regularBuffer: AVAudioPCMBuffer?

    private var timer: DispatchSourceTimer?
    private var timerQueue = DispatchQueue(label: "com.metronome.timer", qos: .userInteractive)
    private var beatIndex = 0
    private var beatsPerMeasure = 4
    private var bpm: Int = 120
    private var anchorTime: CFAbsoluteTime = 0
    private var tickCount: Int = 0

    init() {
        setupAudio()
    }

    deinit {
        timer?.cancel()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        #if canImport(UIKit)
        DispatchQueue.main.async {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        #endif
    }

    func configure(bpm: Int, beatsPerMeasure: Int) {
        let clamped = max(20, min(300, bpm))
        let signatureChanged = self.beatsPerMeasure != beatsPerMeasure
        self.bpm = clamped
        self.beatsPerMeasure = beatsPerMeasure

        if isRunning {
            if signatureChanged {
                restart()
            } else {
                rescheduleTimer()
            }
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        setIdleTimerDisabled(true)
        beatIndex = 0
        currentBeat = 0
        tickCount = 0
        anchorTime = CFAbsoluteTimeGetCurrent()
        startAudioIfNeeded()
        fireBeat(accent: true)
        scheduleTimer()
    }

    func stop() {
        guard isRunning else { return }
        isRunning = false
        setIdleTimerDisabled(false)
        timer?.cancel()
        timer = nil
        beatIndex = 0
        currentBeat = 0
        stopAudioIfNeeded()
    }

    func toggle() {
        isRunning ? stop() : start()
    }

    private func restart() {
        stop()
        start()
    }

    private func scheduleTimer() {
        timer?.cancel()

        let interval = 60.0 / Double(bpm)
        let source = DispatchSource.makeTimerSource(queue: timerQueue)
        source.schedule(deadline: .now() + interval, repeating: interval, leeway: .milliseconds(1))
        source.setEventHandler { [weak self] in
            Task { @MainActor in
                self?.handleTick()
            }
        }
        source.resume()
        timer = source
    }

    private func rescheduleTimer() {
        guard isRunning else { return }
        tickCount = 0
        anchorTime = CFAbsoluteTimeGetCurrent()
        scheduleTimer()
    }

    private func handleTick() {
        tickCount += 1
        let expected = anchorTime + (60.0 / Double(bpm)) * Double(tickCount)
        let drift = CFAbsoluteTimeGetCurrent() - expected
        if abs(drift) > 0.05 {
            rescheduleTimer()
            return
        }

        beatIndex = (beatIndex + 1) % beatsPerMeasure
        fireBeat(accent: beatIndex == 0)
    }

    private func fireBeat(accent: Bool) {
        currentBeat = beatIndex
        pulseTrigger = UUID()
        if audioEnabled {
            playClick(accent: accent)
        }
    }

    // MARK: - Audio

    private func setupAudio() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)

        audioEngine.attach(playerNode)
        let mainMixer = audioEngine.mainMixerNode
        audioEngine.connect(playerNode, to: mainMixer, format: nil)

        let sampleRate: Double = 44_100
        accentBuffer = makeClickBuffer(
            sampleRate: sampleRate,
            frequency: 880,
            duration: 0.04,
            volume: 0.55
        )
        regularBuffer = makeClickBuffer(
            sampleRate: sampleRate,
            frequency: 660,
            duration: 0.035,
            volume: 0.38
        )
    }

    private func startAudioIfNeeded() {
        guard audioEnabled, !audioEngine.isRunning else { return }
        try? audioEngine.start()
        playerNode.play()
    }

    private func stopAudioIfNeeded() {
        playerNode.stop()
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }

    private func playClick(accent: Bool) {
        guard let buffer = accent ? accentBuffer : regularBuffer else { return }
        if !audioEngine.isRunning {
            try? audioEngine.start()
            playerNode.play()
        }
        playerNode.scheduleBuffer(buffer, completionHandler: nil)
    }

    private func setIdleTimerDisabled(_ disabled: Bool) {
        #if canImport(UIKit)
        UIApplication.shared.isIdleTimerDisabled = disabled
        #endif
    }

    private func makeClickBuffer(
        sampleRate: Double,
        frequency: Double,
        duration: Double,
        volume: Float
    ) -> AVAudioPCMBuffer? {
        let frameCount = AVAudioFrameCount(sampleRate * duration)
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount)
        else { return nil }

        buffer.frameLength = frameCount
        guard let samples = buffer.floatChannelData?[0] else { return nil }

        for frame in 0..<Int(frameCount) {
            let t = Double(frame) / sampleRate
            let envelope = exp(-t * 90)
            let tone = sin(2 * .pi * frequency * t)
            let overtone = sin(2 * .pi * frequency * 2.2 * t) * 0.15
            samples[frame] = Float((tone + overtone) * envelope) * volume
        }

        return buffer
    }
}
