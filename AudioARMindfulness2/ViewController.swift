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
    
    //Rifat Handledouble tap gesture
    @objc func handleDoubleTap(_ sender: UITapGestureRecognizer) {
        // Get the location of the double-tap on the line chart
        let location = sender.location(in: lineChartView)

        // Get the x-value of the tap location
        let xValue = lineChartView.valueForTouchPoint(point: location, axis: .left).x
        if let dataSet = lineChartView.data?.dataSets.first,
           let entry = dataSet.entryForXValue(xValue, closestToY: Double.nan) {
            
            // Add the selected point to the array
            selectedPoints.append(entry)
            print("Double-tapped point: X: \(entry.x), Y: \(entry.y)")

            // If two points have been selected, calculate the difference
            if selectedPoints.count == 2 {
                calculateAndSonifyDifference()
            }
        }
    }

    
    //Rifat
    func calculateAndSonifyDifference() {
        // Ensure there are two points to calculate the difference
        guard selectedPoints.count == 2 else { return }

        let point1 = selectedPoints[0]
        let point2 = selectedPoints[1]

        // Calculate the absolute difference in the y-values
        let difference = abs(point2.y - point1.y)
        print("Difference between points: \(difference)")

        // Clear the selected points for the next interaction
        selectedPoints.removeAll()

        // Pass the difference to the audio manager for sonification
        sonifyDifference(difference)
    }
    
    func sonifyDifference(_ difference: Double) {
        // Map the difference to a frequency range (e.g., 220 Hz to 880 Hz)
        let frequency = 220.0 + (difference * 10) // Adjust scaling as needed
        audioManager.oscillator.frequency = Float(frequency) // Set the oscillator frequency
        audioManager.startAudio()

        // Stop the sound after 1 second
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.audioManager.stopAudio()
        }
    }

    


    override func viewDidLoad() {
        super.viewDidLoad()
        audioManager = AudioManager()
        //audioManager.setupAudioSession()
        //audioManager.setupAudioEngine()
        setupLineChart()
        setupSplitTap()
        
        //Rifat: function for double-tap
        setupDoubleTapGesture()
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
