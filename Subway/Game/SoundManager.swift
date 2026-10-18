import Foundation
import AVFoundation
import UIKit

@MainActor
public final class SoundManager: ObservableObject {
    public static let shared = SoundManager()

    @Published public var isSoundEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isSoundEnabled, forKey: "subway_sound_enabled")
        }
    }

    @Published public var isHapticsEnabled: Bool {
        didSet {
            UserDefaults.standard.set(isHapticsEnabled, forKey: "subway_haptics_enabled")
        }
    }

    private let engine = AVAudioEngine()
    private let playerNode = AVAudioPlayerNode()
    private var isAudioSetup = false

    // Pre-synthesized PCM buffers for low latency
    private var coinBuffers: [AVAudioPCMBuffer] = []
    private var jumpBuffer: AVAudioPCMBuffer?
    private var slideBuffer: AVAudioPCMBuffer?
    private var powerupBuffer: AVAudioPCMBuffer?
    private var crashBuffer: AVAudioPCMBuffer?
    private var shieldBreakBuffer: AVAudioPCMBuffer?

    // Haptic generators
    private let lightImpact = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpact = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpact = UIImpactFeedbackGenerator(style: .heavy)
    private let rigidImpact = UIImpactFeedbackGenerator(style: .rigid)
    private let notificationHaptic = UINotificationFeedbackGenerator()

    private init() {
        self.isSoundEnabled = UserDefaults.standard.object(forKey: "subway_sound_enabled") as? Bool ?? true
        self.isHapticsEnabled = UserDefaults.standard.object(forKey: "subway_haptics_enabled") as? Bool ?? true
        setupAudio()
    }

    private func setupAudio() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)

            engine.attach(playerNode)
            engine.connect(playerNode, to: engine.mainMixerNode, format: nil)
            try engine.start()
            isAudioSetup = true

            // Generate procedural sounds
            generateProceduralBuffers()
        } catch {
            print("SoundManager: Audio engine init error: \(error.localizedDescription)")
        }
    }

    // MARK: - Procedural Waveform Synthesis
    private func generateProceduralBuffers() {
        let sampleRate: Double = 44100.0
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) else { return }

        // 1. Coin pickups (pentatonic sequence C, D, E, G, A)
        let coinFreqs: [Double] = [987.77, 1174.66, 1318.51, 1567.98, 1760.0, 2093.0]
        for freq in coinFreqs {
            let duration = 0.09
            let frameCount = AVAudioFrameCount(sampleRate * duration)
            if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) {
                buffer.frameLength = frameCount
                let channels = buffer.floatChannelData!
                let channel = channels[0]

                for frame in 0..<Int(frameCount) {
                    let t = Double(frame) / sampleRate
                    let envelope = exp(-t * 30.0) // Quick decay
                    let sample = sin(2.0 * .pi * freq * t) * envelope * 0.35
                    channel[frame] = Float(sample)
                }
                coinBuffers.append(buffer)
            }
        }

        // 2. Jump (rising chirp)
        let jumpDuration = 0.16
        let jumpFrames = AVAudioFrameCount(sampleRate * jumpDuration)
        if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: jumpFrames) {
            buffer.frameLength = jumpFrames
            let channels = buffer.floatChannelData!
            let channel = channels[0]
            for frame in 0..<Int(jumpFrames) {
                let t = Double(frame) / sampleRate
                let progress = t / jumpDuration
                let freq = 320.0 + (progress * 520.0)
                let envelope = sin(progress * .pi) * 0.4
                let sample = sin(2.0 * .pi * freq * t) * envelope
                channel[frame] = Float(sample)
            }
            jumpBuffer = buffer
        }

        // 3. Slide / Roll (whoosh)
        let slideDuration = 0.22
        let slideFrames = AVAudioFrameCount(sampleRate * slideDuration)
        if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: slideFrames) {
            buffer.frameLength = slideFrames
            let channels = buffer.floatChannelData!
            let channel = channels[0]
            var filterState: Double = 0.0
            for frame in 0..<Int(slideFrames) {
                let t = Double(frame) / sampleRate
                let progress = t / slideDuration
                let noise = Double.random(in: -1.0...1.0)
                // Low pass noise filter for whoosh friction sound
                filterState += (noise - filterState) * 0.12
                let envelope = sin(progress * .pi) * 0.3
                channel[frame] = Float(filterState * envelope)
            }
            slideBuffer = buffer
        }

        // 4. Power-up collected (sparkling arpeggio)
        let puDuration = 0.35
        let puFrames = AVAudioFrameCount(sampleRate * puDuration)
        if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: puFrames) {
            buffer.frameLength = puFrames
            let channels = buffer.floatChannelData!
            let channel = channels[0]
            let notes: [Double] = [523.25, 659.25, 783.99, 1046.50]
            for frame in 0..<Int(puFrames) {
                let t = Double(frame) / sampleRate
                let noteIndex = min(notes.count - 1, Int(t / (puDuration / Double(notes.count))))
                let freq = notes[noteIndex]
                let noteLocalT = t.truncatingRemainder(dividingBy: puDuration / Double(notes.count))
                let env = exp(-noteLocalT * 22.0)
                let sample = sin(2.0 * .pi * freq * t) * env * 0.3
                channel[frame] = Float(sample)
            }
            powerupBuffer = buffer
        }

        // 5. Crash (impact thud + crunch)
        let crashDuration = 0.45
        let crashFrames = AVAudioFrameCount(sampleRate * crashDuration)
        if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: crashFrames) {
            buffer.frameLength = crashFrames
            let channels = buffer.floatChannelData!
            let channel = channels[0]
            for frame in 0..<Int(crashFrames) {
                let t = Double(frame) / sampleRate
                let lowThud = sin(2.0 * .pi * 65.0 * t) * exp(-t * 9.0)
                let noise = Double.random(in: -1.0...1.0) * exp(-t * 18.0)
                let sample = (lowThud * 0.7 + noise * 0.4) * 0.65
                channel[frame] = Float(sample)
            }
            crashBuffer = buffer
        }

        // 6. Shield Break
        let shieldDuration = 0.3
        let shieldFrames = AVAudioFrameCount(sampleRate * shieldDuration)
        if let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: shieldFrames) {
            buffer.frameLength = shieldFrames
            let channels = buffer.floatChannelData!
            let channel = channels[0]
            for frame in 0..<Int(shieldFrames) {
                let t = Double(frame) / sampleRate
                let sample = sin(2.0 * .pi * (880.0 - t * 1400.0) * t) * exp(-t * 12.0) * 0.4
                channel[frame] = Float(sample)
            }
            shieldBreakBuffer = buffer
        }
    }

    private func playBuffer(_ buffer: AVAudioPCMBuffer?) {
        guard isSoundEnabled, isAudioSetup, let buffer = buffer else { return }
        if !engine.isRunning {
            try? engine.start()
        }
        playerNode.scheduleBuffer(buffer, at: nil, options: [], completionHandler: nil)
        if !playerNode.isPlaying {
            playerNode.play()
        }
    }

    // MARK: - Game Sound Triggers
    private var coinStreak: Int = 0

    public func playCoin() {
        guard !coinBuffers.isEmpty else { return }
        let index = coinStreak % coinBuffers.count
        coinStreak += 1
        playBuffer(coinBuffers[index])

        if isHapticsEnabled {
            lightImpact.impactOccurred(intensity: 0.7)
        }
    }

    public func resetCoinStreak() {
        coinStreak = 0
    }

    public func playJump() {
        playBuffer(jumpBuffer)
        if isHapticsEnabled {
            mediumImpact.impactOccurred(intensity: 0.8)
        }
    }

    public func playSlide() {
        playBuffer(slideBuffer)
        if isHapticsEnabled {
            rigidImpact.impactOccurred(intensity: 0.75)
        }
    }

    public func playLaneChange() {
        if isHapticsEnabled {
            lightImpact.impactOccurred(intensity: 0.5)
        }
    }

    public func playPowerUp() {
        playBuffer(powerupBuffer)
        if isHapticsEnabled {
            notificationHaptic.notificationOccurred(.success)
        }
    }

    public func playCrash() {
        playBuffer(crashBuffer)
        if isHapticsEnabled {
            heavyImpact.impactOccurred(intensity: 1.0)
            notificationHaptic.notificationOccurred(.error)
        }
    }

    public func playShieldBreak() {
        playBuffer(shieldBreakBuffer)
        if isHapticsEnabled {
            heavyImpact.impactOccurred(intensity: 0.9)
        }
    }

    public func playTap() {
        if isHapticsEnabled {
            lightImpact.impactOccurred(intensity: 0.4)
        }
    }
}
