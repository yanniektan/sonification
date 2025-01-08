import AVFoundation
import AudioKit

class AudioManager {
    // Create an instance of AudioKit's AudioEngine
    var engine: AudioEngine
    var oscillator: PlaygroundOscillator
    var isEngineRunning = false

    // Custom initializer to initialize the oscillator and AudioEngine
    init() {
        engine = AudioEngine()
        oscillator = PlaygroundOscillator()
        engine.output = oscillator

        // Configure the audio session
        setupAudioSession()
    }

    // MARK: - Audio Session Setup
    private func setupAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.playback, mode: .default, options: [])
            try audioSession.setActive(true)
        } catch {
            print("Audio session setup failed: \(error.localizedDescription)")
        }
    }

    // MARK: - Start Audio
    func startAudio() {
        guard !isEngineRunning else { return } // Prevent duplicate starts

        do {
            try engine.start()
            oscillator.start() // Start the oscillator after the engine
            isEngineRunning = true
        } catch {
            print("Error starting AudioEngine: \(error.localizedDescription)")
        }
    }

    // MARK: - Stop Audio
    func stopAudio() {
        guard isEngineRunning else { return } // Prevent stopping if not running

        oscillator.stop() // Stop the oscillator before the engine
        engine.stop()     // Then stop the engine
        isEngineRunning = false
    }

    // MARK: - Sonify a Single Data Point
    func sonifyDataPoint(_ value: Double) {
        // Range for data values
        let minValue = 0.0
        let maxValue = 40.0

        // Range for corresponding pitch
        let minPitch = 220.0
        let maxPitch = 880.0

        // Normalize the data values to 0-1 range
        let normalizedValue = (value - minValue) / (maxValue - minValue)

        // Map the normalized value to the pitch range
        let pitch = minPitch + normalizedValue * (maxPitch - minPitch)

        // Update the oscillator's frequency
        oscillator.frequency = Float(pitch)
        startAudio()

        // Stop the sound after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.stopAudio()
        }
    }

    func playSlope(from higherValue: Double, to lowerValue: Double, duration: Double = 2.0) {
        stopAudio() // Ensure audio is stopped before starting the slope
        startAudio() // Restart the engine for the slope playback

        // Calculate frequencies
        let minPitch = 220.0
        let maxPitch = 880.0
        let higherFrequency = minPitch + ((higherValue / 40.0) * (maxPitch - minPitch))
        let lowerFrequency = minPitch + ((lowerValue / 40.0) * (maxPitch - minPitch))

        // Slope playback logic
        let stepCount = 100
        let stepDuration = duration / Double(stepCount)
        let frequencyStep = (lowerFrequency - higherFrequency) / Double(stepCount)

        DispatchQueue.global().async {
            for i in 0...stepCount {
                let currentFrequency = higherFrequency + (frequencyStep * Double(i))
                DispatchQueue.main.async {
                    self.oscillator.frequency = Float(currentFrequency)
                }
                Thread.sleep(forTimeInterval: stepDuration)
            }

            DispatchQueue.main.async {
                self.stopAudio() // Stop after slope playback
            }
        }
    }
}

