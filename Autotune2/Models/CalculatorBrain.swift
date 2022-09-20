//
//  CalculatorBrain.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 20/09/2022.
//

import UIKit

struct CalculatorBrain {

    var percentageInsulinDemand: Double?
    // var error / variance / something to describe how accurate the predictions are
    
    func getPercentageInsulinDemand() -> String {
        return String(format: "%.0f", percentageInsulinDemand ?? 0.0)
    }
    /*
    func getAdvice() -> String {
        return bmi?.advice ?? "No advice"
    }
    
    func getColor() -> UIColor {
        return bmi?.color ?? #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)
    }*/
    
    mutating func calculatePercentageInsulinDemand(timeSpan: Float, basalRate: Float, insulinSensitivity: Float, carbohydrateRatio: Float) {
        percentageInsulinDemand = 100
        
        
/*
        if bmiValue < 18.5 {
            percentageInsulinDemand = BMI(value: bmiValue, advice: "Eat more pies!", color: #colorLiteral(red: 0.4745098054, green: 0.8392156959, blue: 0.9764705896, alpha: 1))
        } else if bmiValue < 24.9 {
            percentageInsulinDemand = BMI(value: bmiValue, advice: "Fit as a fiddle!", color: #colorLiteral(red: 0.721568644, green: 0.8862745166, blue: 0.5921568871, alpha: 1))
        } else {
            percentageInsulinDemand = BMI(value: bmiValue, advice: "Eat less pies!", color: #colorLiteral(red: 0.9098039269, green: 0.4784313738, blue: 0.6431372762, alpha: 1))
        }
    */}
  
    
}
