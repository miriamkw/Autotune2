//
//  ViewController.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 06/09/2022.
//




// TODO: Next
// Remove all unneccesary code
// Add interface
// Refactor to MVC pattern
// Do further advancements of the backend and integrate to interface

import UIKit
import HealthKit
import LoopKit

class ViewController: UIViewController {

    private let userHealthProfile = UserHealthProfile()
    
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var biologicalSexLabel: UILabel!
    @IBOutlet weak var bloodGlucoseLabel: UILabel!
    @IBOutlet weak var bloodGlucoseLabelAvg: UILabel!
    
    
    
    // For insulindeliverystore:
    let persistance = PersistenceController.init(directoryURL: URL(fileURLWithPath: ""))
    let healthStore = HKHealthStore()
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        //loadAndDisplayAgeAndSex()
        //loadAndDisplayBloodGlucose()
        loadAutotune()

        do {
            let test = try healthStore.activityMoveMode()
          print(test)
        } catch let error {
          print("Error loading user profile details \(error)")
        }
    }
    
    private func loadAndDisplayAgeAndSex() {
        do {
          let userAgeAndSex = try ProfileDataStore.getAgeAndSex()
          userHealthProfile.age = userAgeAndSex.age
          userHealthProfile.biologicalSex =  userAgeAndSex.biologicalSex
          updateLabels()
        } catch let error {
          print("Error loading user profile details \(error)")
        }
    }
    
    private func loadAutotune() {
        // Create a new TimeDelta collection
        var timeDeltaCollection: [TimeDelta] = []
        
        // Add glucose values with delta glucose and start and enddate (use the already made getSamples)
        guard let glucoseLevelSampleType = HKSampleType.quantityType(forIdentifier: .bloodGlucose) else {
          print("Glucose Level Sample Type is no longer available in HealthKit")
          return
        }
        let startDate = Date(timeIntervalSinceNow: -10*60)
        // TODO: Correct the time zones in date
        ProfileDataStore.getSamples(for: glucoseLevelSampleType, start: startDate) { samples, error in
            guard let samples = samples else {
                if let error = error {
                    print("Error loading glucose samples, \(error)")
                }
                return
            }
            print("NUMBER OF SAMPLES")
            
            for i in 1...samples.endIndex-1 {
                print("SAMPLE BY INDEX")
                print(samples[i-1].quantity.doubleValue(for: .millimolesPerLiter))
                
                let timeDelta = TimeDelta(startDate: samples[i-1].startDate, endDate: samples[i].startDate, glucoseValue: samples[i].quantity.doubleValue(for: .millimolesPerLiter), deltaGlucose: samples[i].quantity.doubleValue(for: .millimolesPerLiter)-samples[i-1].quantity.doubleValue(for: .millimolesPerLiter))
                timeDeltaCollection.append(timeDelta)
            }
            self.userHealthProfile.timeDeltaList = timeDeltaCollection
            //print("THE WHOLE LIST!!")
            //print(timeDeltaCollection)
        }
        
        // Add insulin values with absorbed insulin
        guard let carbohydrateSampleType = HKSampleType.quantityType(forIdentifier: .dietaryCarbohydrates) else {
          print("Carbohydrate Intake Sample Type is no longer available in HealthKit")
          return
        }
        // The last hour and the carbohydrate duration time and delay before with some margin
        let timeInterval: Double = -60*60-370*60
        let startDateCarbs = Date(timeIntervalSinceNow: timeInterval)
        ProfileDataStore.getSamples(for: carbohydrateSampleType, start: startDateCarbs) { samples, error in
            guard let samples = samples else {
                if let error = error {
                    print("Error loading carbohydrate samples, \(error)")
                }
                return
            }
            var iterator = self.userHealthProfile.timeDeltaList?.makeIterator()
            while let timeDelta = iterator?.next() {
                print("COB")
                timeDelta.setCOB(samples: samples)
                print(timeDelta.COB)
                print("Absorbed carbs")
                timeDelta.setAbsorbedCarbohydrates(samples: samples)
                print(timeDelta.absorbedCarbohydrates)
            }
            
        }
        
        // Add insulin values with absorbed insulin
        guard let insulinSampleType = HKSampleType.quantityType(forIdentifier: .insulinDelivery) else {
          print("Insulin Dose Sample Type is no longer available in HealthKit")
          return
        }
        // The last hour and the insulin duration time and delay before
        //let timeInterval: Double = -60*60-370*60
        let startDateInsulin = Date(timeIntervalSinceNow: timeInterval)
        ProfileDataStore.getSamples(for: insulinSampleType, start: startDateInsulin) { samples, error in
            guard let samples = samples else {
                if let error = error {
                    print("Error loading insulin samples, \(error)")
                }
                return
            }
            // TODO: create methods in TimeDelta that set IOB and Absorbed insulin
            var iterator = self.userHealthProfile.timeDeltaList?.makeIterator()
            while let timeDelta = iterator?.next() {
                timeDelta.setIOB(samples: samples)
                timeDelta.setAbsorbedInsulin(samples: samples)
                timeDelta.setInjectedInsulin(samples: samples)
                print("BASELINE")
                print(timeDelta.getBaselineInsulin(basal: 0.8, ISF: 3.9, carb_ratio: 10))
                print("DELTA GLUCOSE")
                print(timeDelta.deltaGlucose)
                print(timeDelta.getExpectedDeltaGlucose(basal: 0.8, ISF: 3.9, carb_ratio: 10))
            }
        }
        
        // calculate autotune assuming carbs is always 0
        
        
        // Fill the UserHealthProfile with the TimeDelta collection
        // Create methods that can calculate the average insulin demand for the collection
    }
    
    private func loadAndDisplayBloodGlucose() {
        //1. Use HealthKit to create the Height Sample Type
        guard let glucoseLevelSampleType = HKSampleType.quantityType(forIdentifier: .bloodGlucose) else {
          print("Glucose Level Sample Type is no longer available in HealthKit")
          return
        }
            
        ProfileDataStore.getMostRecentSample(for: glucoseLevelSampleType) { (sample, error) in
              
          guard let sample = sample else {
              
            if let error = error {
                print("Error loading user profile details \(error)")
            }
                
            return
          }
              
          //2. Convert the height sample to meters, save to the profile model,
          //   and update the user interface.
            let mmolLUnit = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter())
          let bloodGlucose = sample.quantity.doubleValue(for: mmolLUnit)
          self.userHealthProfile.bloodGlucose = bloodGlucose
          self.updateLabels()
            /*
            WorkoutDataStore.loadWalkingWorkouts { workouts, error in
                guard let workouts = workouts else {
                    if let error = error {
                        print("Error loading workouts \(error)")
                    }
                    return
                }
                workouts.forEach { workout in
                    print("Workout from \(workout.startDate) to \(workout.endDate)")
                }
            }
            
            // TODO: use workouts to find ISF and basal rates during workouts
             */
            
            //ProfileDataStore.getAutotune { (sample, error) in
                // TODO
            //}
        }
        
        ProfileDataStore.getAverageBloodGlucose() { (sample, error) in
              
          guard let sample = sample else {
              
            if let error = error {
                print("Error loading user profile details \(error)")
            }
            return
          }
              
          //2. Convert the height sample to meters, save to the profile model,
          //   and update the user interface.
            let mmolLUnit = HKUnit.moleUnit(with: .milli, molarMass: HKUnitMolarMassBloodGlucose).unitDivided(by: HKUnit.liter())
            let averageBloodGlucose = sample.doubleValue(for: mmolLUnit)
          self.userHealthProfile.averageBloodGlucose = averageBloodGlucose
          self.updateLabels()
        }
    }
    
    private func updateLabels() {
        if let age = userHealthProfile.age {
          ageLabel.text = "\(age)"
        }

        if let biologicalSex = userHealthProfile.biologicalSex {
            biologicalSexLabel.text = biologicalSex.stringRepresentation
        }
        
        if let bloodGlucose = userHealthProfile.bloodGlucose {
            bloodGlucoseLabel.text = String(format: "%.01f", bloodGlucose)
        }
        
        if let avgBloodGlucose = userHealthProfile.averageBloodGlucose {
            bloodGlucoseLabelAvg.text = String(format: "%.01f", avgBloodGlucose)
        }
    }
    
}

