//
//  ViewController.swift
//  AudioARMindfulness2
//
//  Created by Andrew Zhang on 6/3/24.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    var audioEngine: AVAudioEngine!
    var inputNode: AVAudioInputNode!
    var outputNode: AVAudioOutputNode!
    var mixerNode: AVAudioMixerNode!
    
    func setupAudioSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try audioSession.setActive(true)
        } catch {
            print("Audio Session couldn't be set: \(error)")
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupAudioSession()
        setupAudioEngine()
    }


    func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        inputNode = audioEngine.inputNode
        outputNode = audioEngine.outputNode
        mixerNode = AVAudioMixerNode()
        
        audioEngine.attach(mixerNode)
        audioEngine.connect(inputNode, to: mixerNode, format: inputNode.inputFormat(forBus: 0))
        audioEngine.connect(mixerNode, to: outputNode, format: inputNode.inputFormat(forBus: 0))
        
        mixerNode.installTap(onBus: 0, bufferSize: 1024, format: inputNode.inputFormat(forBus: 0)) { (buffer, time) in
            self.setOutputVolume(1.0)
            self.outputNode.outputFormat(forBus: 0)
        }

        do {
            try audioEngine.start()
        } catch {
            print("Audio Engine couldn't start: \(error)")
        }
    }
    
    @IBAction func startAudio(_ sender: UIButton) {
        if !audioEngine.isRunning {
            do {
                try audioEngine.start()
            } catch {
                print("Audio Engine couldn't start: \(error)")
            }
        }
    }

    @IBAction func stopAudio(_ sender: UIButton) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
    }
    
    func setOutputVolume(_ volume: Float) {
        mixerNode.outputVolume = volume
    }


}


