//
//  TimeDeltaCollection.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 20/09/2022.
//
import HealthKit
import LoopKit

class TimeDeltaCollection {
    var timeDeltaList: [TimeDelta] = []
    
    var percentageInsulinDemand: Float?
    var advice: String?
    
    let healthStore = HKHealthStore()
    let insulinModel = ExponentialInsulinModel(actionDuration: 21600.0, peakActivityTime: 4500.0)
    let carbMath = CarbMath()
    
    var timeSpan: Float?
    var startDate: Date?
    var basalRate: Float?
    var insulinSensitivity: Float?
    var carbohydrateRate: Float?
    
    init() {
        
    }
    
    func setTimeDeltaList(timeSpan: Float, basalRate: Float, insulinSensitivity: Float, carbohydrateRate: Float) {
        // Make sure this works! Should probably be done on the main thread
        self.timeSpan = timeSpan
        self.startDate = Date(timeIntervalSinceNow: -Double(timeSpan)*60*60)
        self.basalRate = basalRate
        self.insulinSensitivity = insulinSensitivity
        self.carbohydrateRate = carbohydrateRate
        self.setGlucoseValues()
        self.setCarbohydrateValues()
        // Important that this goes lastly because it calculates the baseline insulin
        self.setInsulinValues()
    }
    
    // Calculate the average percentage insulin demand
    func getAveragePercentageInsulinDemand() -> Double {
        var iterator = self.timeDeltaList.makeIterator()
        var sum = 0.0
        while let timeDelta = iterator.next() {
            if let baseline = timeDelta.baselineInsulin {
                sum = sum + baseline
                print("YAY BASELINE!")
                print(baseline)
            } else {
                print("NO BASELINE:(")
            }
        }
        return sum/Double(timeDeltaList.count)
    }
    
    
    // Create functions to initialize the timeDeltaList
    
    
    // Start by setting the glucose values in timedelta
    private func setGlucoseValues() {
        guard let startDate = startDate else {
            print("Start date is not available")
            return
        }
                
        // Add glucose values with delta glucose and start and enddate (use the already made getSamples)
        guard let glucoseLevelSampleType = HKSampleType.quantityType(forIdentifier: .bloodGlucose) else {
          print("Glucose Level Sample Type is no longer available in HealthKit")
          return
        }
        // TODO: Correct the time zones in date
        HealthKitDataStore.getSamples(for: glucoseLevelSampleType, start: startDate, end: Date()) { samples, error in
            guard let samples = samples else {
                if let error = error {
                    print("Error loading glucose samples, \(error)")
                }
                return
            }

            for i in 1...samples.endIndex-1 {
                let timeDelta = TimeDelta(startDate: samples[i-1].startDate, endDate: samples[i].startDate, glucoseValue: samples[i].quantity.doubleValue(for: .millimolesPerLiter), deltaGlucose: samples[i].quantity.doubleValue(for: .millimolesPerLiter)-samples[i-1].quantity.doubleValue(for: .millimolesPerLiter), insulinModel: self.insulinModel, carbMath: self.carbMath)
                self.timeDeltaList.append(timeDelta)
            }
        }
    }
    
    private func setCarbohydrateValues() {
        guard let carbohydrateSampleType = HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates) else {
          print("Carbohydrate Intake Sample Type is no longer available in HealthKit")
          return
        }
        guard let startDate = startDate else {
            print("Start date is not available")
            return
        }
        // The last hour and the carbohydrate duration time and delay before with some margin
        let carbohydrateAbsorptionTime: Double = -6*60*60
        let startDateCarbs = startDate.addingTimeInterval(TimeInterval(carbohydrateAbsorptionTime))
        HealthKitDataStore.getSamples(for: carbohydrateSampleType, start: startDateCarbs) { samples, error in
            guard let samples = samples else {
                if let error = error {
                    print("Error loading carbohydrate samples, \(error)")
                }
                return
            }
            var iterator = self.timeDeltaList.makeIterator()
            while let timeDelta = iterator.next() {
                timeDelta.setCOB(samples: samples)
                timeDelta.setAbsorbedCarbohydrates(samples: samples)
            }
        }
    }
    
    private func setInsulinValues() {
        guard let insulinSampleType = HKSampleType.quantityType(forIdentifier: .insulinDelivery) else {
          print("Insulin Dose Sample Type is no longer available in HealthKit")
          return
        }
        guard let startDate = startDate else {
            print("Start date is not available")
            return
        }
        
        // The last hour and the insulin duration time and delay before
        //let timeInterval: Double = -60*60-370*60
        let startDateInsulin = startDate.addingTimeInterval(TimeInterval(-insulinModel.actionDuration))
        HealthKitDataStore.getSamples(for: insulinSampleType, start: startDateInsulin) { samples, error in
            guard let samples = samples else {
                if let error = error {
                    print("Error loading insulin samples, \(error)")
                }
                return
            }
            guard let basalRate = self.basalRate,
                    let insulinSensitivity = self.insulinSensitivity,
                    let carbohydrateRate = self.carbohydrateRate else {
                print("Baseline settings are not available")
                return
            }

            // TODO: create methods in TimeDelta that set IOB and Absorbed insulin
            var iterator = self.timeDeltaList.makeIterator()
            while let timeDelta = iterator.next() {
                timeDelta.setIOB(samples: samples)
                timeDelta.setAbsorbedInsulin(samples: samples)
                timeDelta.setInjectedInsulin(samples: samples)
                timeDelta.calculateBaselineInsulin(basal: basalRate, ISF: insulinSensitivity, carb_ratio: carbohydrateRate)
                print("BASELINE")
                print(timeDelta.baselineInsulin)
                print("DELTA GLUCOSE")
                print(timeDelta.deltaGlucose)
            }
        }
    }

    
}
