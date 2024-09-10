//
//  AudioManager.swift
//  AudioARMindfulness2
//
//  Created by Katherine Chen on 9/3/24.
//

import AVFoundation

class AudioManager {
    var audioEngine: AVAudioEngine!
    var oscillator: AVAudioSourceNode?
    var currentFrequency: Double = 440.0 // default frequency 440 Hz

    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Audio Session couldn't be set: \(error)")
        }
    }

    func setupAudioEngine() {
        // Create instance of AVAudioEngine
        audioEngine = AVAudioEngine()
        let mainMixer = audioEngine.mainMixerNode
        let format = mainMixer.outputFormat(forBus: 0)
        
        // This is the oscillator responsible for generating audio signals
        oscillator = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let sampleRate = format.sampleRate
            
            // Calculate the angular frequency based on the current frequency
            let theta = 2.0 * Double.pi * self.currentFrequency / sampleRate
            var currentSample = 0.0
            
            // For each frame in the audio buffer
            for frame in 0..<Int(frameCount) {
                // Calculate audio sample value for the current frame
                let sampleValue = sin(currentSample * theta)
                
                // Set the sample value for each buffer in the audio buffer list
                for buffer in ablPointer {
                    let bufferPointer = buffer.mData?.assumingMemoryBound(to: Float.self)
                    bufferPointer?[frame] = Float(sampleValue)
                }
                
                // Increment the sample position for next frame
                currentSample += 1.0
            }
            
            return noErr
        }
        
        // Attach the oscillator node to the audio engine and connect it to the main mixer node
        if let oscillator = oscillator {
            audioEngine.attach(oscillator)
            audioEngine.connect(oscillator, to: mainMixer, format: format)
        }
    }
    
    func startAudio() {
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("Audio Engine couldn't start: \(error)")
            }
        }
    }
    
    func stopAudio() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
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
        
        // Play the tone by setting the current frequency of the audio engine
        currentFrequency = pitch
    }
}
