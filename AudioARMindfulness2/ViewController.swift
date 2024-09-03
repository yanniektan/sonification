//
//  ViewController.swift
//  AudioARMindfulness2
//
//  Created by Andrew Zhang on 6/3/24.
//

import UIKit
import AVFoundation
import Charts

class ViewController: UIViewController {
    var audioEngine: AVAudioEngine!
    var lineChartView: LineChartView!
    var oscillator: AVAudioSourceNode?
    var currentFrequency: Double = 440.0 // default frequency 440 Hz
    var isDragging = false // track if the user is dragging
    
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
        setupLineChart()
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
    
    func setupLineChart() {
        let chartHeight: CGFloat = view.bounds.height / 2
        let topPadding: CGFloat = 100
        
        // Initialize the LineChartView
        lineChartView = LineChartView(frame: CGRect(x: 0, y: topPadding, width: view.bounds.width, height: chartHeight - topPadding))
        lineChartView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        view.backgroundColor = .white
        view.addSubview(lineChartView)
        
        // Hardcoded sample data entries
        let entries = [
            ChartDataEntry(x: 0, y: 10),
            ChartDataEntry(x: 1, y: 11),
            ChartDataEntry(x: 2, y: 12),
            ChartDataEntry(x: 3, y: 13),
            ChartDataEntry(x: 4, y: 14),
            ChartDataEntry(x: 5, y: 15),
            ChartDataEntry(x: 6, y: 16),
            ChartDataEntry(x: 7, y: 17),
            ChartDataEntry(x: 8, y: 18),
            ChartDataEntry(x: 9, y: 19),
            ChartDataEntry(x: 10, y: 20),
            ChartDataEntry(x: 11, y: 21),
            ChartDataEntry(x: 12, y: 22),
            ChartDataEntry(x: 13, y: 23),
            ChartDataEntry(x: 14, y: 24),
            ChartDataEntry(x: 15, y: 25),
            ChartDataEntry(x: 16, y: 26),
            ChartDataEntry(x: 17, y: 27),
            ChartDataEntry(x: 18, y: 28),
            ChartDataEntry(x: 19, y: 29),
            ChartDataEntry(x: 20, y: 30),
            ChartDataEntry(x: 21, y: 31),
            ChartDataEntry(x: 22, y: 32),
            ChartDataEntry(x: 23, y: 33),
            ChartDataEntry(x: 24, y: 34)
        ]
        
        // Configure the dataset for the line chart
        let dataSet = LineChartDataSet(entries: entries, label: "Sample Data")
        dataSet.colors = [NSUIColor.blue] // Line color
        dataSet.circleColors = [NSUIColor.red] // Circle color
        dataSet.mode = .cubicBezier // Smooth lines like a wave
        dataSet.lineWidth = 2.0 // Line width
        dataSet.circleRadius = 4.0 // Circle radius (if circles are used)
        dataSet.drawValuesEnabled = false // Hide values
        
        // Set the data for the LineChartView
        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        
        // Handle dragging
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        lineChartView.addGestureRecognizer(panGestureRecognizer)
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        // Get the current touch location within the chart view
        let location = recognizer.location(in: lineChartView)
        
        switch recognizer.state {
            
            // Begin dragging
            case .began:
                isDragging = true
                startAudio()
            
            // While dragging
            case .changed:
                // Get the x-value corresponding to the touch location
                let xValue = lineChartView.valueForTouchPoint(point: location, axis: .left).x
            
                // Get the data point closest to the x-value
                if let dataSet = lineChartView.data?.dataSets.first,
                   let entry = dataSet.entryForXValue(xValue, closestToY: Double.nan) {
                    // Convert the data point's y-value to a pitch and play the tone
                    sonifyDataPoint(entry.y)
                }
            
            // Stop dragging
            case .ended, .cancelled:
                isDragging = false
                stopAudio()
            
            default:
                break
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
}


