//
//  ViewController.swift
//  AudioARMindfulness2
//
//  Created by Andrew Zhang on 6/3/24.
//

import UIKit
import AVFoundation
import Charts



private var lastInteractionTime: TimeInterval = 0

class ViewController: UIViewController {
    //Rifat: This array will store two points selected
    var selectedPoints: [ChartDataEntry] = []

    
    
    var audioManager: AudioManager!
    var lineChartView: LineChartView!
    var isDragging = false // track if the user is dragging
    var coordinateLabel: PaddedLabel! // for showing data label
    var splitTapAlertLabel: PaddedLabel! // for showing split-tap detections
    
    // For split-tapping gesture
    var prevNumberOfTouches: Int = 0
    var prevCoordinate: ChartDataEntry!

    //Rifat: Function will set up double tap gesture.
    func setupDoubleTapGesture() {
        // Create a double-tap gesture recognizer
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        //Needs two taps for the gesture
        doubleTapGesture.numberOfTapsRequired = 2
        //This puts the gesture to the chart review
        lineChartView.addGestureRecognizer(doubleTapGesture) // Attach the gesture to the chart view
    }
    
    func setupSingleTapGesture() {
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        lineChartView.addGestureRecognizer(singleTapGesture)
    }
    
    
    @objc func handleSingleTap(_ sender: UITapGestureRecognizer) {
        let location = sender.location(in: lineChartView)
        let xValue = lineChartView.valueForTouchPoint(point: location, axis: .left).x

        if let dataSet = lineChartView.data?.dataSets.first,
           let entry = dataSet.entryForXValue(xValue, closestToY: Double.nan) {
            
            // Add the selected point
            selectedPoints.append(entry)
            print("Tapped point: X: \(entry.x), Y: \(entry.y)")

            // Keep only the last two points
            if selectedPoints.count > 2 {
                selectedPoints.removeFirst()
            }
        }
    }


    
    //Rifat Handledouble tap gesture
    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        // Check if there are exactly two points selected
        guard selectedPoints.count == 2 else {
            print("Double-tap requires two selected points.")
            return
        }

        // Sort the points by their y-values (highest to lowest)
        let sortedPoints = selectedPoints.sorted { $0.y > $1.y }
        let higherPoint = sortedPoints[0]
        let lowerPoint = sortedPoints[1]

        print("Higher point: X: \(higherPoint.x), Y: \(higherPoint.y)")
        print("Lower point: X: \(lowerPoint.x), Y: \(lowerPoint.y)")

        // Play the sloping sound from higher to lower
        audioManager.playSlope(from: higherPoint.y, to: lowerPoint.y)

        // Clear selected points after playing the slope
        selectedPoints.removeAll()
    }

    
    //Rifat
    func calculateAndSonifyDifference() {
        guard selectedPoints.count == 2 else { return }
        let sortedPoints = selectedPoints.sorted { $0.y > $1.y } // Sort descending
        let higherPoint = sortedPoints[0]
        let lowerPoint = sortedPoints[1]
        print("Higher point: X: \(higherPoint.x), Y: \(higherPoint.y)")
        print("Lower point: X: \(lowerPoint.x), Y: \(lowerPoint.y)")
        selectedPoints.removeAll() // Clear for next input
        playSlopingSound(from: higherPoint.y, to: lowerPoint.y)
    }
    
    func playSlopingSound(from higherValue: Double, to lowerValue: Double) {
        // Map y-values to frequencies
        let minFrequency = 220.0 // Base frequency for the lowest point
        let maxFrequency = 880.0 // Maximum frequency for the highest point

        let higherFrequency = minFrequency + (higherValue / 40.0) * (maxFrequency - minFrequency)
        let lowerFrequency = minFrequency + (lowerValue / 40.0) * (maxFrequency - minFrequency)

        print("Playing slope from \(higherFrequency) Hz to \(lowerFrequency) Hz")
        

        // Start playing the higher frequency
        //audioManager.oscillator.frequency = Float(higherFrequency)
        audioManager.startAudio()

        // Animate the slope to the lower frequency over 1 second
        let slopeDuration: TimeInterval = 1.0
        let stepInterval: TimeInterval = 0.1
        let totalSteps = Int(slopeDuration / stepInterval)
        let frequencyStep = (lowerFrequency - higherFrequency) / Double(totalSteps)

        var currentFrequency = higherFrequency
        for step in 0...totalSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepInterval * Double(step))) {
                guard self.audioManager.isOscillatorRunning else {
                    print("⚠️ Oscillator stopped unexpectedly, stopping slope")
                    return
                }
                currentFrequency += frequencyStep
                self.audioManager.oscillator.frequency = Float(currentFrequency)
            }
        }
        // Stop the sound after the slope duration
        DispatchQueue.main.asyncAfter(deadline: .now() + slopeDuration) {
            self.audioManager.stopAudio()
        }
        
        //scheduleStep()
    }
    
//    func sonifyDifference(_ difference: Double) {
//        // Map the difference to a frequency range (e.g., 220 Hz to 880 Hz)
//        let frequency = 220.0 + (difference * 10) // Adjust scaling as needed
//        audioManager.oscillator.frequency = Float(frequency) // Set the oscillator frequency
//        audioManager.startAudio()
//
//        // Stop the sound after 1 second
//        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
//            self.audioManager.stopAudio()
//        }
//    }

    


    override func viewDidLoad() {
        super.viewDidLoad()
        print("🚀 viewDidLoad started!") // ✅ Debugging print
        audioManager = AudioManager()
        setupLineChart()
        
        // Ensure gestures are added AFTER the chart is created
        setupDoubleTapGesture()
        setupSingleTapGesture()
        
        // Initialize splitTapAlertLabel properly
        setupSplitTap()

        // Add single-tap gesture
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        lineChartView.addGestureRecognizer(singleTapGesture)

        // Add double-tap gesture
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        lineChartView.addGestureRecognizer(doubleTapGesture)

        // Ensure single-tap and double-tap gestures can coexist
        singleTapGesture.require(toFail: doubleTapGesture)
        
        setupSplitTapGesture() // ✅ Make sure this function is called
        
        
        
        print("🚀 viewDidLoad completed!")
        
    }
    
    func setupSplitTapGesture() {
    
        print("🚀 setupSplitTapGesture() called") // ✅ Debugging print
        
        let splitTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSplitTap))
        splitTapGesture.numberOfTouchesRequired = 2 // ✅ Requires two fingers
        splitTapGesture.numberOfTapsRequired = 1 // ✅ Requires only a single tap
        
        view.addGestureRecognizer(splitTapGesture)
        
        print("✅ Split tap gesture recognizer added.") // 🚀 Debugging print
    }
    
    func setupLineChart() {
        lineChartView = ChartManager.getDefaultLineChartView(for: self)
        view.addSubview(lineChartView)
        
        // Initialize the PaddedLabel
        coordinateLabel = PaddedLabel()
        coordinateLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        coordinateLabel.textColor = .white
        coordinateLabel.font = UIFont.systemFont(ofSize: 16)
        coordinateLabel.textAlignment = .left
        coordinateLabel.numberOfLines = 2
        coordinateLabel.textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        coordinateLabel.layer.cornerRadius = 8
        coordinateLabel.layer.masksToBounds = true
        view.addSubview(coordinateLabel)
        
        // Handle dragging
        let panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        lineChartView.addGestureRecognizer(panGestureRecognizer)
    }
    
    func speakText(_ text: String) {
        let speechSynthesizer = AVSpeechSynthesizer()
        let utterance = AVSpeechUtterance(string: text)
        utterance.rate = 0.5 // Adjust speed
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")

        speechSynthesizer.speak(utterance)
    }

    
    func setupSplitTap() {
        // Initialize the PaddedLabel
        splitTapAlertLabel = PaddedLabel()
        splitTapAlertLabel.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        splitTapAlertLabel.textColor = .white
        splitTapAlertLabel.font = UIFont.systemFont(ofSize: 16)
        splitTapAlertLabel.textAlignment = .left
        splitTapAlertLabel.numberOfLines = 2
        splitTapAlertLabel.textInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8)
        splitTapAlertLabel.layer.cornerRadius = 8
        splitTapAlertLabel.layer.masksToBounds = true
        view.addSubview(splitTapAlertLabel)
    }
    
    @objc func handlePan(_ recognizer: UIPanGestureRecognizer) {
        //let location = recognizer.location(in: lineChartView)
        let location = recognizer.location(in: lineChartView)
        let xValue = lineChartView.valueForTouchPoint(point: location, axis: .left).x
        let touchCount = recognizer.numberOfTouches // 👀 Get the number of fingers touching
        print("🔍 Gesture state: \(recognizer.state.rawValue), Touch count: \(touchCount)")
        
        // 🚨 Remove early return so stopAudio() can always run
        if touchCount == 0 {
            print("🛑 No fingers detected! Manually stopping audio.")
            isDragging = false
            audioManager.stopAudio()
            return  // Ensure we exit immediately after stopping the sound
        }
        
        
        guard recognizer.numberOfTouches > 0 else {
            let currentTime = Date().timeIntervalSince1970
            let timeSinceLastDrag = currentTime - lastInteractionTime
            
            if timeSinceLastDrag < 0.3 { // ✅ If user lifts and drags again quickly, don’t stop
                print("⚠️ Ignoring stop request: User resumed dragging quickly.")
                return
            }
            
            // ✅ Delay stop request (Adaptive Timing)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                if !self.isDragging {
                    self.audioManager.stopAudio()
                }
            }
            return
        }
        
        
        switch recognizer.state {
            // Begin dragging
            case .began:
                lastInteractionTime = Date().timeIntervalSince1970 // ✅ Track user interaction time
                if !isDragging {
                    isDragging = true
                    print("🎵 Dragging started. Calling startAudio()...")
                    audioManager.startAudio()
                }
            
            case .changed:
                let location = recognizer.location(ofTouch: 0, in: lineChartView)
                let xValue = lineChartView.valueForTouchPoint(point: location, axis: .left).x
                
            if isDragging {
                if let dataSet = lineChartView.data?.dataSets.first,
                   let entry = dataSet.entryForXValue(xValue, closestToY: Double.nan) {
                    audioManager.sonifyDataPoint(entry.y)
                    
                    // ✅ Store the latest touched data point for split tap
                    prevCoordinate = entry
                    print("📌 Stored prevCoordinate: X: \(entry.x), Y: \(entry.y)")
                }
            }
            
            // ✅ NEW: Detect two fingers while dragging
//            if touchCount == 2 {
//                print("🎯 Two fingers detected during drag - Triggering split tap!")
//                handleSplitTap()
//            }

            case .ended, .cancelled:
                print("🛑 Dragging stopped! Stopping audio immediately.")
                isDragging = false
                audioManager.stopAudio() // ✅ Stop the sound immediately.
                // 🚨 NEW: Log if `.ended` is actually being detected
                print("✅ Dragging detected as ended.")

//                lastInteractionTime = Date().timeIntervalSince1970 // ✅ Update when touch ends
//                DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
//                    if !self.isDragging {
//                        self.audioManager.stopAudio()
//                    }
//                }
            default:
                print("🔍 Gesture state: \(recognizer.state.rawValue), Touch count: \(touchCount)")
               

//            default:
//                break
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        if touches.count == 2 {
            print("✅ Split tap detected! Reading max value...")
            audioManager.announceMaxValue()
        }
    }

    
    @objc func handleSplitTap() {
        print("🎯 handleSplitTap() triggered!")
        guard let entry = prevCoordinate else {
                print("No data point available for split tap.")
                return
            }

        print("Split-tap detected at X: \(entry.x), Y: \(entry.y), now we will announce the highest Y-value.")

        // Stop current sonification before speaking
        audioManager.stopAudio()
        
        // ✅ Call AudioManager to announce the highest Y-value
        audioManager.announceMaxValue()

        // Update UI to show detected split tap
        splitTapAlertLabel.text = "Value: \(entry.y)"
        splitTapAlertLabel.isHidden = false

        // Call text-to-speech function
        speakText("X: \(Int(entry.x)), Y: \(Int(entry.y))")
    }
}
