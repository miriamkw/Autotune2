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
    
    func getInsulinDemandValue() -> String {
        let insulinDemandRounded = String(format: "%.0f%%", insulinDemand?.value ?? 0.0)
        print("FIFTH REQUEST!<3")
        return insulinDemandRounded
    }
    
    func getAdvice() -> String {
        return insulinDemand?.advice ?? "No advice"
    }
    
    // Is mutating in BMI calculator
    func calculateInsulinDemand(timeSpan: Float, basalRate: Float, insulinSensitivity: Float, carbohydrateRatio: Float, completion: @escaping () -> Void) {
        self.getTimeDeltaList(timeSpan: timeSpan, basalRate: basalRate, insulinSensitivity: insulinSensitivity, carbohydrateRatio: carbohydrateRatio) { timeDeltaList in
            DispatchQueue.main.async {
                print("AND HERE WE INITIALIZE (FOUR)")
                
                print("TIMEDELTA LIST LENGTH")
                print(timeDeltaList.count)
                var sum = 0.0
                var count = 0.0
                for timeDelta in timeDeltaList {
                    if let baselineInsulin = timeDelta.baselineInsulin {
                        sum = sum + baselineInsulin
                        count = count + 1
                    } else {
                        print("Baseline insulin was not available")
                    }
                }
                let averageValue = sum/count * 100
                
                if averageValue < 80 {
                    self.insulinDemand = InsulinDemand(value: averageValue, advice: "You need less insulin than you think!")
                } else if averageValue <= 120 {
                    self.insulinDemand = InsulinDemand(value: averageValue, advice: "Your settings are good!")
                } else {
                    self.insulinDemand = InsulinDemand(value: averageValue, advice: "Your need more insulin than you think!")
                }
                completion()
            }
        }
    }
    
    // Should add error closure here
    private func getTimeDeltaList(timeSpan: Float, basalRate: Float, insulinSensitivity: Float, carbohydrateRatio: Float, completion: @escaping ([TimeDelta]) -> Void) {
        
        let startDate = Date(timeIntervalSinceNow: -Double(timeSpan)*60*60)
        let carbohydrateAbsorptionTime: Double = -6*60*60
        let startDateCarbs = startDate.addingTimeInterval(TimeInterval(carbohydrateAbsorptionTime))
        let startDateInsulin = startDate.addingTimeInterval(TimeInterval(-insulinModel.actionDuration))
        
        var timeDeltaList: [TimeDelta] = []
        // DIRECTLY INITIALIZE WITH GLUCOSE VALUES!
        
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
        HealthKitDataStore.getSamples(for: glucoseLevelSampleType, start: startDate, end: Date()) { samples, error in
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
                print("first")
                HealthKitDataStore.getSamples(for: carbohydrateSampleType, start: startDateCarbs, end: Date()) { samples, error in
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
                    print("second")
                    HealthKitDataStore.getSamples(for: insulinSampleType, start: startDateInsulin, end: Date()) { samples, error in
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
                                // I think all of these are syncronous because they have no network/API/database calls???
                                timeDelta.setIOB(samples: samples)
                                timeDelta.setAbsorbedInsulin(samples: samples)
                                timeDelta.setInjectedInsulin(samples: samples)
                                
                                // CALCULATE BASELINE INSIDE OF ANOTHER CLOSURE??
                                
                                timeDelta.calculateBaselineInsulin(basal: basalRate, ISF: insulinSensitivity, carb_ratio: carbohydrateRatio)
                                //print("BASELINE")
                                //print(timeDelta.baselineInsulin)
                                //print("DELTA GLUCOSE")
                                //print(timeDelta.deltaGlucose)
                            }
                            completion(timeDeltaList)
                        }
                        print("third")
                    }
                }
            }
        }
    }
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    var timeDeltaCollection = TimeDeltaCollection()
    var baselineInsulinPercentage: Double?
    
    // var error / variance / something to describe how accurate the predictions are
    
    func getPercentageInsulinDemand() -> String {
        // The problem is that this is executed BEFORE the init of the values
        print("WE WANT TO RECEIVE HERE!")
        //let avg = timeDeltaCollection.getAveragePercentageInsulinDemand()
        //print(avg)
        if let baselineInsulinPercentage = baselineInsulinPercentage {
            return String(format: "%.0f %", baselineInsulinPercentage * 100)
        } else {
            return "Still nah"
        }
    }
    
    func calculatePercentageInsulinDemand(timeSpan: Float, basalRate: Float, insulinSensitivity: Float, carbohydrateRatio: Float) {
        self.timeDeltaCollection.setTimeDeltaList(timeSpan: timeSpan, basalRate: basalRate, insulinSensitivity: insulinSensitivity, carbohydrateRate: carbohydrateRatio)
        self.baselineInsulinPercentage = timeDeltaCollection.getAveragePercentageInsulinDemand()
    }
    
}
