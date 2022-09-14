//
//  TimeDelta.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 13/09/2022.
//

import Foundation
import HealthKit
import LoopKit

class TimeDelta {
    
    var startDate: Date
    var endDate: Date
    var glucoseValue: Double
    var deltaGlucose: Double
    var IOB: Double?
    var absorbedInsulin: Double?
    var injectedInsulin: Double?
    var absorbedCarbohydrates: Double?
    
    let insulinModel = ExponentialInsulinModel(actionDuration: 360*60, peakActivityTime: 75*60)
    
    init(startDate: Date, endDate: Date, glucoseValue: Double, deltaGlucose: Double) {
        self.startDate = startDate
        self.endDate = endDate
        self.glucoseValue = glucoseValue
        self.deltaGlucose = deltaGlucose
    }
    
    var baselineInsulin: Double? { // percentage of baseline insulin demands
        guard let absorbedInsulin = absorbedInsulin,
              absorbedInsulin > 0 else {
                return nil
            }
        // TODO: Calculate baseline insulin compared to settings!
        // TODO: Add carbohydrates
        return (deltaGlucose + absorbedInsulin)
    }
    
    var deltaTime: TimeInterval? {
        return endDate.distance(to: startDate)
    }
    
    func setIOB(samples: [HKQuantitySample]) {
        var res = 0.0
        
        for sample in samples {
            // TODO: Calculate remaining insulin
            // Add to res
            // TODO: WHAT IS THE UNIT FOR INSULIN?
            
            // TODO: FILTER OUT THE IRELLEVANT DOSES!
            // It is possible now the doses that have not yet started are impacting
            var insulinDoseQuantity = sample.quantity.doubleValue(for: .internationalUnit())
            let n = Int(round(sample.startDate.distance(to: sample.endDate).rawValue/60 / 5))
            
            // TODO: Split the doses into five minute intervals when added to results
            if (n > 1) {
                insulinDoseQuantity = insulinDoseQuantity / Double(n)
                for i in 1...n {
                    let currentEffectRemaining = insulinModel.percentEffectRemaining(at: sample.startDate.addingTimeInterval(TimeInterval(5*60*i)).distance(to: self.endDate))
                    res = res + insulinDoseQuantity * currentEffectRemaining
                }
            } else {
                let effectRemaining = insulinModel.percentEffectRemaining(at: sample.startDate.distance(to: self.endDate))
                res = res + insulinDoseQuantity * effectRemaining
            }
        }
        self.IOB = res
    }
    /*
    func setAbsorbedInsulin(samples: [HKQuantitySample]) {
        var res = 0
        
        for sample in samples {
            
        }
    }*/
    
    // TODO: error metrics, or score, do research on that
    
    
    // TODO: Add carbohydrates in the calculation
    func getBaselineInsulin(basal: Double, ISF: Double, carb_ratio: Double) -> Double? {
        guard let absorbedInsulin = absorbedInsulin else {
            return nil
        }
        // Solving for the derivative of the second degree polynomial
        // TODO: ADD ABSORBED CARBOHYDRATES INSTEAD OF 0 HERE
        let res = (absorbedInsulin - (0/carb_ratio))/(2*basal)
        
        // Result can never be less than one percent
        if res < 0.01 {
            return 0.01
        } else {
            return res
        }
    }
    
    
    
    // read about setters and getters
    // The get and set values should have the settings as input
    
    
    
    // func getAbsorbedInsulin(insulinDoses: [InsulinDose]) {
    
    
    
}
