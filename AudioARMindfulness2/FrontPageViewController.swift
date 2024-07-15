//
//  FrontPageViewController.swift
//  AudioARMindfulness2
//
//  Created by Yannie Tan on 7/14/24.
//

import UIKit
import Charts

class FrontPageViewController: UIViewController {
    
    @IBOutlet weak var graphView: LineChartView!
    @IBOutlet weak var playButton: UIButton!
    
    var dataPoints: [ChartDataEntry] = []
    var sounds: [String] = [] // Array to store sound file names
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupGraph()
        setupPlayButton()
    }
    
    func setupGraph() {
        // Sample data - replace with your actual data
        for i in 0..<10 {
            let value = Double.random(in: 0...100)
            let entry = ChartDataEntry(x: Double(i), y: value)
            dataPoints.append(entry)
            sounds.append("sound\(i).mp3") // Assuming you have sound files named sound0.mp3, sound1.mp3, etc.
        }
        
        let dataSet = LineChartDataSet(entries: dataPoints, label: "Data")
        dataSet.drawCirclesEnabled = true
        dataSet.circleRadius = 4
        dataSet.circleHoleRadius = 2
        dataSet.setColor(.blue)
        dataSet.setCircleColor(.blue)
        
        let data = LineChartData(dataSet: dataSet)
        graphView.data = data
        graphView.xAxis.labelPosition = .bottom
        graphView.rightAxis.enabled = false
        graphView.legend.enabled = false
        graphView.animate(xAxisDuration: 1.5)
    }
    
    func setupPlayButton() {
        playButton.setTitle("Play", for: .normal)
        playButton.addTarget(self, action: #selector(playButtonTapped), for: .touchUpInside)
    }
    
    @objc func playButtonTapped() {
        // Navigate to the audio view controller
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if let audioVC = storyboard.instantiateViewController(withIdentifier: "AudioViewController") as? ViewController {
            audioVC.dataPoints = self.dataPoints
            audioVC.sounds = self.sounds
            navigationController?.pushViewController(audioVC, animated: true)
        }
    }
}
