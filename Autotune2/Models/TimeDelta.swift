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
    var consumedCarbohydrates: Double?

    var baselineInsulin: Double?
    
    let insulinModel: ExponentialInsulinModel
    let carbMath: CarbMath
    
    init(startDate: Date, endDate: Date, glucoseValue: Double, deltaGlucose: Double, insulinModel: ExponentialInsulinModel, carbMath: CarbMath) {
        self.startDate = startDate
        self.endDate = endDate
        self.glucoseValue = glucoseValue
        self.deltaGlucose = deltaGlucose
        
        self.insulinModel = insulinModel
        self.carbMath = carbMath
    }
    
    var deltaTime: TimeInterval {
        return startDate.distance(to: endDate)
    }
    
    var deltaTimeRaw: Double {
        // Return in minutes
        return startDate.distance(to: endDate).rawValue/60
    }
    
    // IOB at the endDate of this object, which is the date of the glucose dose sample
    func setIOB(samples: [HKQuantitySample]) {
        // After debugging I am pretty confident that this is correct, but it is very different from in Loop
        
        var res = 0.0
        for sample in samples {
            var insulinDoseQuantity = sample.quantity.doubleValue(for: .internationalUnit())
            let timeSinceInsulinDose = sample.startDate.distance(to: self.endDate).rawValue/60 // In minutes, positive when it happened in the past
            let insulinDoseTimeSpan = sample.startDate.distance(to: sample.endDate).rawValue/60
            let n = Int(round(insulinDoseTimeSpan / 5))

            // Skip current iteration of for loop for doses that will happen in the future
            if ((timeSinceInsulinDose < 0) || (timeSinceInsulinDose > insulinModel.actionDuration)) {
                continue
            }
            
            // If the insulin dose happened for over 7 minutes, the dose will be split into five minute intervals
            if (n > 1) {
                insulinDoseQuantity = insulinDoseQuantity / Double(n)
                for i in 0...n-1 {
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
        //print("IOB")
        //print(res)
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
                for i in 0...n-1 {
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
        //print("ABSORBED INSULIN")
        //print(res)
    }
    
    func setCOB(samples: [HKQuantitySample]) {
        // TODO: Use the duration for the carb entry
        var res = 0.0
        for sample in samples {
            let carbQuantity = sample.quantity.doubleValue(for: .gram())
            let timeSinceCarbIntake = sample.startDate.distance(to: self.endDate).rawValue/60 // In minutes, positive when it happened in the past

            // Skip current iteration of for loop for doses that will happen in the future
            if (timeSinceCarbIntake < 0) {
                continue
            }
            
            let effectRemaining = carbMath.percentEffectRemaining(at: sample.startDate.distance(to: self.endDate), actionDuration: 3*60*60)
            res = res + carbQuantity * effectRemaining
        }
        self.COB = res
    }
    
    func setAbsorbedCarbohydrates(samples: [HKQuantitySample]) {
        var res = 0.0
        for sample in samples {
            let carbQuantity = sample.quantity.doubleValue(for: .gram())
            let timeSinceCarbIntake = sample.startDate.distance(to: self.startDate).rawValue/60 // In minutes, positive when it happened in the past

            // Skip current iteration of for loop for doses that will happen in the future
            if (timeSinceCarbIntake < 0) {
                continue
            }
            
            let startEffectRemaining = carbMath.percentEffectRemaining(at: sample.startDate.distance(to: self.startDate), actionDuration: 3*60*60)
            let endEffectRemaining = carbMath.percentEffectRemaining(at: sample.startDate.distance(to: self.endDate), actionDuration: 3*60*60)
            res = res + carbQuantity * (startEffectRemaining - endEffectRemaining)
        }
        self.absorbedCarbohydrates = res
        //print("IT HAPPENS COME UN")
        //print(res)
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
        //print("INJECTED INSULIN")
        //print(res)
        //print("DATE")
        //print(self.endDate)
    }
    
    // TODO: error metrics, or score, do research on that
    // TODO: Add other features that might impact future levels, like rate of glucose change the last 15 minutes, or rate of carb absorption
    
    // Calculates the percentage of basal and ISF needed to minimize the error between actual and expected delta glucose
    // Can not be lower than 0 percent
    func calculateBaselineInsulin(basal: Float, ISF: Float, carb_ratio: Float) {
        //print("TEST")
        //print(absorbedCarbohydrates)
        //print("TEST2")
        //print(absorbedInsulin)
        
        if let absorbedInsulin = absorbedInsulin, let absorbedCarbohydrates = absorbedCarbohydrates {
            let min_error = ((absorbedCarbohydrates)/(Double(carb_ratio)) - absorbedInsulin)/(deltaGlucose/Double(ISF) - Double(basal)/(60/deltaTimeRaw))
            baselineInsulin = max(0, min_error)
        } else {
            print("Absorbed insulin and/or absorbed carbohydrates not available")
        }        
    }
    
    // To check that the baseline insulin calculation actually works
    /*
    func getExpectedDeltaGlucose(basal: Double, ISF: Double, carb_ratio: Double) -> Double? {
        guard let absorbedInsulin = absorbedInsulin, let absorbedCarbohydrates = absorbedCarbohydrates else {
            return nil
        }
        return ((absorbedCarbohydrates/carb_ratio) + basal/(60/deltaTimeRaw) - absorbedInsulin)*ISF
    }
    */
}
