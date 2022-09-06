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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        loadAndDisplayAgeAndSex()
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
    
    private func updateLabels() {
        if let age = userHealthProfile.age {
          ageLabel.text = "\(age)"
        }

        if let biologicalSex = userHealthProfile.biologicalSex {
            biologicalSexLabel.text = biologicalSex.stringRepresentation
        }
    }
    
}

