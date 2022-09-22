//
//  CalculatorBrain.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 20/09/2022.
//

import UIKit
import HealthKit
import LoopKit

class CalculatorBrain {
    
    var insulinDemand: InsulinDemand?
    let insulinModel = ExponentialInsulinModel(actionDuration: 21600.0, peakActivityTime: 4500.0)
    let carbMath = CarbMath()
    let healthKitDataStore = HealthKitDataStore.shared
    
    func getMeanError() -> String {
        if let ME = insulinDemand?.ME {
            return String(format: "%.1f mmol/L/h", ME)
        } else {
            return "Not available"
        }
    }
    
    func getRMSE() -> String {
        if let RMSE = insulinDemand?.RMSE {
            return String(format: "%.1f mmol/L/h", RMSE)
        } else {
            return "Not available"
        }
    }
    
    func getAdvice() -> String {
        return insulinDemand?.advice ?? "No advice"
    }
    
    // Is mutating in BMI calculator
    func calculateInsulinDemand(timeSpan: Float, basalRate: Float, insulinSensitivity: Float, carbohydrateRatio: Float, completion: @escaping () -> Void) {
        self.getTimeDeltaList(timeSpan: timeSpan, basalRate: basalRate, insulinSensitivity: insulinSensitivity, carbohydrateRatio: carbohydrateRatio) { timeDeltaList in
            DispatchQueue.main.async {
                var RMSE = 0.0
                var ME = 0.0
                var count = 0.0
                for timeDelta in timeDeltaList {
                    if let expectedDeltaGluose = timeDelta.getExpectedDeltaGlucose(basal: Double(basalRate), ISF: Double(insulinSensitivity), carb_ratio: Double(carbohydrateRatio)) {
                        let error = expectedDeltaGluose - timeDelta.deltaGlucose
                        RMSE = RMSE + pow(error, 2)
                        ME = ME + error
                        count = count + 1
                    } else {
                        print("Expected delta glucose was not available")
                    }
                    
                }
                RMSE = sqrt(RMSE/count)*12
                ME = ME/count*12
                
                if ME < -0.5 {
                    self.insulinDemand = InsulinDemand(RMSE: RMSE, ME: ME, advice: "You need more insulin than you think!")
                } else if ME <= 0.5 {
                    self.insulinDemand = InsulinDemand(RMSE: RMSE, ME: ME, advice: "Your settings are good!")
                } else {
                    self.insulinDemand = InsulinDemand(RMSE: RMSE, ME: ME, advice: "Your need less insulin than you think!")
                }
                completion()
            }
        }
    }
    
    // TODO: Add error closure
    private func getTimeDeltaList(timeSpan: Float, basalRate: Float, insulinSensitivity: Float, carbohydrateRatio: Float, completion: @escaping ([TimeDelta]) -> Void) {
        
        let startDate = Date(timeIntervalSinceNow: -Double(timeSpan)*60*60*24)
        let carbohydrateAbsorptionTime: Double = -6*60*60
        let startDateCarbs = startDate.addingTimeInterval(TimeInterval(carbohydrateAbsorptionTime))
        let startDateInsulin = startDate.addingTimeInterval(TimeInterval(-insulinModel.actionDuration))
        
        var timeDeltaList: [TimeDelta] = []
        
        guard let glucoseLevelSampleType = HKSampleType.quantityType(forIdentifier: .bloodGlucose) else {
          print("Glucose Level Sample Type is no longer available in HealthKit")
          return
        }
        guard let carbohydrateSampleType = HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates) else {
          print("Carbohydrate Intake Sample Type is no longer available in HealthKit")
          return
        }
        guard let insulinSampleType = HKSampleType.quantityType(forIdentifier: .insulinDelivery) else {
          print("Insulin Dose Sample Type is no longer available in HealthKit")
          return
        }
        self.healthKitDataStore.getSamples(for: glucoseLevelSampleType, start: startDate, end: Date()) { samples, error in
            // Initialize time delta list with glucose values
            DispatchQueue.main.async {
                guard let samples = samples else {
                    if let error = error {
                        print("Error loading glucose samples, \(error)")
                    }
                    return
                }
                for i in 1...samples.endIndex-1 {
                    let timeDelta = TimeDelta(startDate: samples[i-1].startDate, endDate: samples[i].startDate, glucoseValue: samples[i].quantity.doubleValue(for: .millimolesPerLiter), deltaGlucose: samples[i].quantity.doubleValue(for: .millimolesPerLiter)-samples[i-1].quantity.doubleValue(for: .millimolesPerLiter), insulinModel: self.insulinModel, carbMath: self.carbMath)
                    timeDeltaList.append(timeDelta)
                }
                self.healthKitDataStore.getSamples(for: carbohydrateSampleType, start: startDateCarbs, end: Date()) { samples, error in
                    // Initialize time delta list with carbohydrate values
                    DispatchQueue.main.async {
                        guard let samples = samples else {
                            if let error = error {
                                print("Error loading glucose samples, \(error)")
                            }
                            return
                        }
                        var iterator = timeDeltaList.makeIterator()
                        while let timeDelta = iterator.next() {
                            timeDelta.setCOB(samples: samples)
                            timeDelta.setAbsorbedCarbohydrates(samples: samples)
                        }
                    }
                    self.healthKitDataStore.getSamples(for: insulinSampleType, start: startDateInsulin, end: Date()) { samples, error in
                        // Initialize time delta list with insulin values
                        DispatchQueue.main.async {
                            guard let samples = samples else {
                                if let error = error {
                                    print("Error loading glucose samples, \(error)")
                                }
                                return
                            }
                            var iterator = timeDeltaList.makeIterator()
                            while let timeDelta = iterator.next() {
                                // I think all of these are syncronous because they have no network/API/database calls
                                timeDelta.setIOB(samples: samples)
                                timeDelta.setAbsorbedInsulin(samples: samples)
                                timeDelta.setInjectedInsulin(samples: samples)
                                timeDelta.calculateBaselineInsulin(basal: basalRate, ISF: insulinSensitivity, carb_ratio: carbohydrateRatio)
                            }
                            completion(timeDeltaList)
                        }
                    }
                }
            }
        }
    }
}
