//
//  ViewController.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 06/09/2022.
//

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
        loadAndDisplayAgeAndSex()
        loadAndDisplayBloodGlucose()
        print("Current IOB:")
        let insulinStore = InsulinDeliveryStore.init(healthStore: healthStore, cacheStore: persistance)

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
        
        ProfileDataStore.getAverageIOB { (sample, error) in
              
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

