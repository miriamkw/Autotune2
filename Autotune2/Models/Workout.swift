//
//  Workout.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 06/09/2022.
//

import HealthKit

class Workout {
    // THIS SHOULD LONG TERM BE A GENERALISED CLASS FOR EACH TYPE OF WORKOUT
    let activityType: HKWorkoutActivityType = HKWorkoutActivityType.walking
    
    // TODO
    var averageBloodGlucose: Double? /*{
        
        guard let weightInKilograms = weightInKilograms,
          let heightInMeters = heightInMeters,
          heightInMeters > 0 else {
            return nil
        }
        
        return (weightInKilograms/(heightInMeters*heightInMeters))
      }*/

    // TODO: Compute average blood glucose when
    // Question: How should this value be calculated? When should it be updated?
    // Maybe look in loop for inspiration
    // Maybe use the Swift course Climate app for inspiration.
  
    
    // TODO: Compute average baseline value

}
