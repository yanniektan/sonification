//
//  ChartManager.swift
//  AudioARMindfulness2
//
//  Created by Katherine Chen on 9/3/24.
//

import UIKit
import Charts

class ChartManager {
    
    static func getDefaultLineChartView(for viewController: UIViewController) -> LineChartView {
        // Initialize the LineChartView
        let lineChartView = LineChartView()
        let chartHeight: CGFloat = viewController.view.bounds.height / 2
        let topPadding: CGFloat = 100
        lineChartView.frame = CGRect(x: 0, y: topPadding, width: viewController.view.bounds.width, height: chartHeight - topPadding)
        lineChartView.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        viewController.view.backgroundColor = .white
        
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
        dataSet.colors = [NSUIColor.blue]
        dataSet.circleColors = [NSUIColor.red]
        dataSet.mode = .cubicBezier
        dataSet.lineWidth = 2.0
        dataSet.circleRadius = 4.0
        dataSet.drawValuesEnabled = false
        
        // Set the data for the LineChartView
        let data = LineChartData(dataSet: dataSet)
        lineChartView.data = data
        
        // Set axes and legend text color
        lineChartView.xAxis.labelTextColor = .black
        lineChartView.leftAxis.labelTextColor = .black
        lineChartView.rightAxis.labelTextColor = .black
        lineChartView.legend.textColor = .black
        
        return lineChartView
    }
}
