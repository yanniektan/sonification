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
        // Ensure there are two points to calculate the difference
        guard selectedPoints.count == 2 else { return }
        let point1 = selectedPoints[0]
        let point2 = selectedPoints[1]
        
        //lets sort the points according to y-values
        let sortedPoints = selectedPoints.sorted { $0.y < $1.y }
        let higherPoint = sortedPoints[0]
        let lowerPoint = sortedPoints[1]
        
        print("Higher point: X: \(higherPoint.x), Y: \(higherPoint.y)")
        print("Lower point: X: \(lowerPoint.x), Y: \(lowerPoint.y)")
        
        // Clear the selected points for the next interaction
        selectedPoints.removeAll()
        
        // Pass the points to the sloping sound method
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
        audioManager.oscillator.frequency = Float(higherFrequency)
        audioManager.startAudio()

        // Animate the slope to the lower frequency over 1 second
        let slopeDuration: TimeInterval = 1.0
        let stepInterval: TimeInterval = 0.05
        let totalSteps = Int(slopeDuration / stepInterval)
        let frequencyStep = (lowerFrequency - higherFrequency) / Double(totalSteps)

        var currentFrequency = higherFrequency

        for step in 0...totalSteps {
            DispatchQueue.main.asyncAfter(deadline: .now() + (stepInterval * Double(step))) {
                currentFrequency += frequencyStep
                self.audioManager.oscillator.frequency = Float(currentFrequency)
            }
        }

        // Stop the sound after the slope duration
        DispatchQueue.main.asyncAfter(deadline: .now() + slopeDuration) {
            self.audioManager.stopAudio()
        }
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
        audioManager = AudioManager()
        setupLineChart()

        // Add single-tap gesture
        let singleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap(_:)))
        lineChartView.addGestureRecognizer(singleTapGesture)

        // Add double-tap gesture
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        lineChartView.addGestureRecognizer(doubleTapGesture)

        // Ensure single-tap and double-tap gestures can coexist
        singleTapGesture.require(toFail: doubleTapGesture)
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
        guard recognizer.numberOfTouches > 0 else {
            isDragging = false
            audioManager.stopAudio()
            coordinateLabel.isHidden = true
            splitTapAlertLabel.isHidden = true
            return
        }
        
        let firstTouchLocation = recognizer.location(ofTouch: 0, in: lineChartView)
        
        switch recognizer.state {
            // Begin dragging
            case .began:
                isDragging = true
                audioManager.startAudio()
            
            // While dragging
            case .changed:
                // Detect split-tap
                if prevNumberOfTouches == 1 && recognizer.numberOfTouches == 2 {
                    handleSplitTap()
                }
            
                // Get the x-value corresponding to the touch location
                let xValue = lineChartView.valueForTouchPoint(point: firstTouchLocation, axis: .left).x
            
            
                // Get the data point closest to the x-value
                if let dataSet = lineChartView.data?.dataSets.first,
                   let entry = dataSet.entryForXValue(xValue, closestToY: Double.nan) {
                    // Convert the data point's y-value to a pitch and play the tone
                    audioManager.sonifyDataPoint(entry.y)
                    
                    // Update label text
                    coordinateLabel.text = String(format: "X: %.2f\nY: %.2f", entry.x, entry.y)
                    
                    // Calculate label size to fit text
                    let labelSize = coordinateLabel.intrinsicContentSize
                    coordinateLabel.frame = CGRect(x: 30, y: 120, width: labelSize.width, height: labelSize.height)
                    coordinateLabel.isHidden = false
                    
                    // Set the coordinate for split-tap detection
                    prevNumberOfTouches = recognizer.numberOfTouches
                    prevCoordinate = entry
                }
            
            // Stop dragging
            case .ended, .cancelled:
                isDragging = false
                audioManager.stopAudio()
                coordinateLabel.isHidden = true
                splitTapAlertLabel.isHidden = true

            
            default:
                break
        }
    }
    
    @objc func handleSplitTap() {
        print("split-tap detected at", prevCoordinate.x, prevCoordinate.y)
        
        // TODO: Remove this and perform the intended split-tap action, e.g. speech synthesis
        splitTapAlertLabel.text = "split-tap detected: \(prevCoordinate.x), \(prevCoordinate.y)"
        let labelSize = splitTapAlertLabel.intrinsicContentSize
        splitTapAlertLabel.frame = CGRect(x: 30, y: 180, width: labelSize.width, height: labelSize.height)
        splitTapAlertLabel.isHidden = false
    }
}
