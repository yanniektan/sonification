import AVFoundation
import AudioKit
import UIKit



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
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers, .duckOthers])
            try audioSession.setActive(true)
            print("✅ Audio session successfully initialized.")
        } catch {
            print("⚠️ Audio session setup failed: \(error.localizedDescription)")
        }
    }
    
    var isOscillatorRunning = false // Add a flag

    private var lastStartTime: TimeInterval = 0
    private let throttleInterval: TimeInterval = 0.5 // 500ms
    // MARK: - Start Audio
    func startAudio() {
        let currentTime = Date().timeIntervalSince1970
        // ✅ Only start if enough time has passed & engine is not already running
        guard !isEngineRunning, currentTime - lastStartTime > throttleInterval else {
            print("⚠️ Skipping start: Already running or throttled.")
            return
        }

        lastStartTime = currentTime // Update last start time
        print("🎵 Attempting to start Audio Engine...")
      
        DispatchQueue.main.async {
            do {
                try self.engine.start()
                self.isEngineRunning = true
                print("✅ Audio Engine started successfully")
            } catch {
                print("❌ Error starting AudioEngine: \(error.localizedDescription)")
            }
        }
        
    
    }
    
    private var stopScheduled = false
    // MARK: - Stop Audio
    func stopAudio() {
        let currentTime = Date().timeIntervalSince1970
        // ✅ Prevent stopping too soon after last sound played
        guard isEngineRunning else {
            print("⚠️ Skipping stop: Already stopped or throttled.")
            return
        }
        
        if stopScheduled {
            print("⚠️ Stop already scheduled. Skipping.")
            return
        }
        
        stopScheduled = true
        print("🛑 Dragging ended. Scheduling stop in 1.5s...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if !self.isEngineRunning {
                print("⚠️ Skipping stop: Engine already stopped.")
                self.stopScheduled = false
                return
            }

            print("🛑 Stopping Audio Engine safely...")
            self.engine.stop()
            self.isEngineRunning = false
            self.stopScheduled = false
            print("🛑 Audio Engine stopped successfully")
        }
    }
    
    // MARK: - Sonify a Single Data Point
    private var maxEncounteredValue: Double = 0.0
    private var lastSonifyTime: TimeInterval = 0
    func sonifyDataPoint(_ value: Double) {
        let currentTime = Date().timeIntervalSince1970
        
        // ✅ Prevent calling too often (only allow every 300ms)
        if currentTime - lastSonifyTime < throttleInterval {
            return
        }
        lastSonifyTime = currentTime
        if !isEngineRunning { // ✅ Only start if needed
            startAudio()
        }
        
        
        // ✅ Ensure the oscillator is running
        if !isOscillatorRunning {
            oscillator.start()
            isOscillatorRunning = true
        }
        
        // Update max encountered value
        maxEncounteredValue = max(maxEncounteredValue, value)
        
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
        
        print("🎵 Frequency changed to: \(pitch) Hz") // ✅ Log frequency updates
    }
    
    func announceMaxValue() {
        guard isEngineRunning else { return }

        print("📢 Announcing max value: \(maxEncounteredValue)")
        
    // ✅ Convert max Y-value to a frequency
        let minFrequency = 220.0
        let maxFrequency = 880.0
        let normalizedValue = (maxEncounteredValue / 40.0) // Normalize assuming max Y = 40
        let frequency = minFrequency + (normalizedValue * (maxFrequency - minFrequency))
        
        // ✅ Stop current audio before playing new sound
        stopAudio()
        
        // ✅ Play the max value frequency
        oscillator.frequency = Float(frequency)
        startAudio()

        // ✅ Speak the max value
        let utterance = AVSpeechUtterance(string: "The maximum value is \(maxEncounteredValue)")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        utterance.rate = 0.5 // Adjust speed for clarity

        let synthesizer = AVSpeechSynthesizer()
        synthesizer.speak(utterance)

        // ✅ Optional: Haptic feedback for better UX
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }


    func playSlope(from higherValue: Double, to lowerValue: Double, duration: Double = 2.0) {
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
                DispatchQueue.main.asyncAfter(deadline: .now() + (stepDuration * Double(i))) {
                    self.oscillator.frequency = Float(currentFrequency)
                }
            }

            DispatchQueue.main.async {
                self.stopAudio() // Stop after slope playback
            }
        }
    }
}

