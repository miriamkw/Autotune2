/**
 * Link to the tutorial used:
 * https://www.raywenderlich.com/6992-healthkit-tutorial-with-swift-workouts
 *
 * Copyright (c) 2017 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
 * distribute, sublicense, create a derivative work, and/or sell copies of the
 * Software in any work that is designed, intended, or marketed for pedagogical or
 * instructional purposes related to programming, coding, application development,
 * or information technology.  Permission for such use, copying, modification,
 * merger, publication, distribution, sublicensing, creation of derivative works,
 * or sale is expressly withheld.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import HealthKit

// This class should be used solemnly to fetch a given group of samples from HealthKit
class WorkoutDataStore {
  
    // TODO: List all workout data types
    // TODO: Load all workouts given the workout type
    
    
    class func loadWalkingWorkouts(completion:
      @escaping ([HKWorkout]?, Error?) -> Void) {
      //1. Get all workouts with the "Other" activity type.
      let predicate = HKQuery.predicateForWorkouts(with: .traditionalStrengthTraining)
              
      let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate,
                                            ascending: true)
        
        let query = HKSampleQuery(
          sampleType: .workoutType(),
          predicate: predicate,
          limit: 0,
          sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            DispatchQueue.main.async {
              guard
                let samples = samples as? [HKWorkout],
                error == nil
                else {
                  completion(nil, error)
                  return
              }
              completion(samples, nil)
            }
          }
        HKHealthStore().execute(query)
    }

}
