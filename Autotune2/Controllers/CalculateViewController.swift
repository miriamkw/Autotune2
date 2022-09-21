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
        
        //DispatchQueue.main.async {
            let timeSpan = round(self.timeSpanSlider.value)
            let basalRate = round(self.basalRateSlider.value * 20)/20
            let insulinSensitivity = round(self.insulinSensitivitySlider.value * 10)/10
            let carbohydrateRatio = round(self.carbohydrateRatioSlider.value * 10)/10
            // TODO: This function should probably be a closure function
            // Maybe you should fetch the calculated value immediately and perform segue after
            // Make this function RETURN the value you need! Set the value in the calculatorbrain for example
        
        
        // TODO: Add error handling on the completion
        self.calculatorBrain.calculateInsulinDemand(timeSpan: timeSpan, basalRate: basalRate, insulinSensitivity: insulinSensitivity, carbohydrateRatio: carbohydrateRatio) {
            self.performSegue(withIdentifier: "goToResults", sender: self)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "goToResults" {
            let destinationVC = segue.destination as! ResultViewController
            destinationVC.percentageInsulinDemandValue = calculatorBrain.getInsulinDemandValue() // "100 %"
            destinationVC.advice = calculatorBrain.getAdvice()
        }
    }
}
