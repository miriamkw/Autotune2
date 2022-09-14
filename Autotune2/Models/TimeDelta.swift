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
    var COB: Double?
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
    
    
    // IOB at the endDate of this object, which is the date of the glucose dose sample
    func setIOB(samples: [HKQuantitySample]) {
        var res = 0.0
        for sample in samples {
            var insulinDoseQuantity = sample.quantity.doubleValue(for: .internationalUnit())
            let timeSinceInsulinDose = sample.startDate.distance(to: self.endDate).rawValue/60 // In minutes, positive when it happened in the past
            let insulinDoseTimeSpan = sample.startDate.distance(to: sample.endDate).rawValue/60
            let n = Int(round(insulinDoseTimeSpan / 5))
            
            // Skip current iteration of for loop for doses that will happen in the future
            if (timeSinceInsulinDose < 0) {
                continue
            }
            
            // If the insulin dose happened for over 7 minutes, the dose will be split into five minute intervals
            if (n > 1) {
                insulinDoseQuantity = insulinDoseQuantity / Double(n)
                for i in 1...n {
                    // If the splitting creates dose in the future, break the for loop
                    let currentStartDate = sample.startDate.addingTimeInterval(TimeInterval(5*60*i))
                    if (currentStartDate.distance(to: self.endDate).rawValue < 0) {
                        break
                    }
                    let currentEffectRemaining = insulinModel.percentEffectRemaining(at: currentStartDate.distance(to: self.endDate))
                    res = res + insulinDoseQuantity * currentEffectRemaining
                }
            } else {
                let effectRemaining = insulinModel.percentEffectRemaining(at: sample.startDate.distance(to: self.endDate))
                res = res + insulinDoseQuantity * effectRemaining
            }
        }
        self.IOB = res
        print("IOB")
        print(res)
    }
    
    func setAbsorbedInsulin(samples: [HKQuantitySample]) {
        var res = 0.0
        for sample in samples {
            var insulinDoseQuantity = sample.quantity.doubleValue(for: .internationalUnit())
            let timeSinceInsulinDose = sample.startDate.distance(to: self.startDate).rawValue/60 // In minutes, positive when it happened in the past
            let insulinDoseTimeSpan = sample.startDate.distance(to: sample.endDate).rawValue/60
            let n = Int(round(insulinDoseTimeSpan / 5))
            
            // Skip current iteration of for loop for doses that will happen in the future (from startDate)
            if (timeSinceInsulinDose < 0) {
                continue
            }
            
            // If the insulin dose happened for over 7 minutes, the dose will be split into five minute intervals
            if (n > 1) {
                insulinDoseQuantity = insulinDoseQuantity / Double(n)
                for i in 1...n {
                    let currentEffectRemainingStart = insulinModel.percentEffectRemaining(at: sample.startDate.addingTimeInterval(TimeInterval(5*60*i)).distance(to: self.startDate))
                    let currentEffectRemainingEnd = insulinModel.percentEffectRemaining(at: sample.startDate.addingTimeInterval(TimeInterval(5*60*i)).distance(to: self.endDate))
                    res = res + insulinDoseQuantity * (currentEffectRemainingStart - currentEffectRemainingEnd)
                }
            } else {
                let effectRemainingStart = insulinModel.percentEffectRemaining(at: sample.startDate.distance(to: self.startDate))
                let effectRemainingEnd = insulinModel.percentEffectRemaining(at: sample.startDate.distance(to: self.endDate))
                res = res + insulinDoseQuantity * (effectRemainingStart - effectRemainingEnd)
            }
        }
        self.absorbedInsulin = res
        print("ABSORBED INSULIN")
        print(res)
    }
    
    func setInjectedInsulin(samples: [HKQuantitySample]) {
        var res = 0.0
        for sample in samples {
            var insulinDoseQuantity = sample.quantity.doubleValue(for: .internationalUnit())
            let timeSinceInsulinDoseStart = sample.startDate.distance(to: self.endDate).rawValue/60 // In minutes, positive when it happened in the past
            let timeSinceInsulinDoseEnd = sample.endDate.distance(to: self.startDate).rawValue/60 // In minutes, positive when it happened in the past
            let insulinDoseTimeSpan = sample.startDate.distance(to: sample.endDate).rawValue/60

            let n = Int(round(insulinDoseTimeSpan / 5))
            
            // Skip current iteration of for loop for doses that will start in the future or ended before this time interval
            if ((timeSinceInsulinDoseStart < 0) || (timeSinceInsulinDoseEnd > 0)) {
                continue
            }
            
            // If the insulin dose happened for over 7 minutes, the dose will be split into five minute intervals
            if (n > 1) {
                insulinDoseQuantity = insulinDoseQuantity / Double(n)
                res = res + insulinDoseQuantity
            } else {
                res = res + insulinDoseQuantity
            }
        }
        self.injectedInsulin = res
        print("INJECTED INSULIN")
        print(res)
        print("DATE")
        print(self.endDate)
    }
    
    // TODO: error metrics, or score, do research on that
    
    
    // TODO: Add carbohydrates in the calculation
    func getBaselineInsulin(basal: Double, carb_ratio: Double) -> Double? {
        guard let absorbedInsulin = absorbedInsulin else {
            return nil
        }
        // Solving for the derivative of the second degree polynomial
        // TODO: ADD ABSORBED CARBOHYDRATES INSTEAD OF 0 HERE
        // TODO: Here we are assuming that the time interval for this sample is 5 minutes (--> basal/12)
        let res = (absorbedInsulin - (0/carb_ratio))/(2*basal/12)
        
        // Result can never be less than one percent
        if res < 0.01 {
            return 0.01
        } else {
            return res
        }
    }
    
    // TODO: Implement this to check that the baseline insulin calculation actually works
    func getExpectedDeltaGlucose() -> Double? {
        return 0
    }
    
    
    // read about setters and getters
    // The get and set values should have the settings as input
    
    // func getAbsorbedInsulin(insulinDoses: [InsulinDose]) {
    
}
