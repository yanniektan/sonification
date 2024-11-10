import AVFoundation
import AudioKit

class AudioManager {
    // Create an instance of AudioKit's AudioEngine
    var engine: AudioEngine
    var oscillator: PlaygroundOscillator
    var isEngineRunning = false

    // Custom initializer to initialize the oscillator and AudioEngine
    init() {
        // Initialize the AudioEngine and PlaygroundOscillator
        engine = AudioEngine()
        oscillator = PlaygroundOscillator()

        // Attach the oscillator to the audio engine
        engine.output = oscillator
    }
    
    func startAudio() {
        if !isEngineRunning {
            do {
                // Start the audio engine and the oscillator
                try engine.start()
                isEngineRunning = true
                oscillator.start()  // Start the oscillator once the engine is running
            } catch {
                print("Audio Engine couldn't start: \(error)")
            }
        }
    }

    func stopAudio() {
        if isEngineRunning {
            engine.stop()
            isEngineRunning = false  // Set the flag to false after the engine stops
        }
        oscillator.stop()  // Stop the oscillator
    }

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
        oscillator.frequency = Float(pitch)  // Convert Double to Float
    }
}

