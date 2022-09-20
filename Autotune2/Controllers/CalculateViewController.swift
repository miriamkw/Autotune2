//
//  CalculateViewController.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 20/09/2022.
//

import UIKit

class CalculateViewController: UIViewController {
    
    var calculatorBrain = CalculatorBrain()
    
    @IBOutlet weak var timeSpanLabel: UILabel!
    @IBOutlet weak var basalRateLabel: UILabel!
    @IBOutlet weak var insulinSensitivityLabel: UILabel!
    @IBOutlet weak var carbohydrateRatioLabel: UILabel!
    
    @IBOutlet weak var timeSpanSlider: UISlider!
    @IBOutlet weak var basalRateSlider: UISlider!
    @IBOutlet weak var insulinSensitivitySlider: UISlider!
    @IBOutlet weak var carbohydrateRatioSlider: UISlider!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    @IBAction func timeSpanSliderChanged(_ sender: UISlider) {
        let timeSpan = String(format: "%.0f", sender.value)
        timeSpanLabel.text = "\(timeSpan) hr"
    }
    
    @IBAction func basalRateSliderChanged(_ sender: UISlider) {
        let basalRate = String(format: "%.2f", round(sender.value * 20)/20)
        basalRateLabel.text = "\(basalRate) U/hr"
    }
    
    @IBAction func insulinSensitivitySliderChanged(_ sender: UISlider) {
        let insulinSensitivity = String(format: "%.1f", sender.value)
        insulinSensitivityLabel.text = "\(insulinSensitivity) mmol/L"
    }
    
    @IBAction func carbohydrateRatioSliderChanged(_ sender: UISlider) {
        let carbohydrateRatio = String(format: "%.1f", sender.value)
        carbohydrateRatioLabel.text = "\(carbohydrateRatio) g/U"
    }
    
    @IBAction func calculatePressed(_ sender: UIButton) {
        let timeSpan = round(timeSpanSlider.value)
        let basalRate = round(basalRateSlider.value * 20)/20
        let insulinSensitivity = round(insulinSensitivitySlider.value * 10)/10
        let carbohydrateRatio = round(carbohydrateRatioSlider.value * 10)/10
        
        print(timeSpan)
        print(basalRate)
        print(insulinSensitivity)
        print(carbohydrateRatio)
        
        calculatorBrain.calculatePercentageInsulinDemand(timeSpan: timeSpan, basalRate: basalRate, insulinSensitivity: insulinSensitivity, carbohydrateRatio: carbohydrateRatio)
        self.performSegue(withIdentifier: "goToResults", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResults" {
            let destinationVC = segue.destination as! ResultViewController
            destinationVC.percentageInsulinDemandValue = calculatorBrain.getPercentageInsulinDemand() // "100 %"
            destinationVC.advice = "Your settings are perfect!"
            //destinationVC.color = calculatorBrain.getColor()
        }
    }
}
