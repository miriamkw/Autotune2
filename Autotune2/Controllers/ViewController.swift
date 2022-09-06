//
//  ViewController.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 06/09/2022.
//

import UIKit
import HealthKit

class ViewController: UIViewController {

    private let userHealthProfile = UserHealthProfile()
    
    @IBOutlet weak var ageLabel: UILabel!
    @IBOutlet weak var biologicalSexLabel: UILabel!
    @IBOutlet weak var bloodGlucoseLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadAndDisplayAgeAndSex()
        loadAndDisplayMostRecentGlucoseLevel()
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
    
    private func loadAndDisplayMostRecentGlucoseLevel() {
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
          let heightInMeters = sample.quantity.doubleValue(for: mmolLUnit)
          self.userHealthProfile.bloodGlucose = heightInMeters
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
    }
    
}

