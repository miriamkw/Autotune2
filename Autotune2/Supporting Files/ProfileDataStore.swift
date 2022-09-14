/**
 * This file is borrowed from the following free of charge HealthKit Tutorial:
 * https://www.raywenderlich.com/459-healthkit-tutorial-with-swift-getting-started#ratings-count-hook
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
import LoopKit
import UIKit

class ProfileDataStore {
    

    var timeDelta: TimeDelta?
    
    
    
    // Asks for age (calculated from date), sex and blood type
    class func getAgeAndSex() throws -> (
        age: Int,
        biologicalSex: HKBiologicalSex) {
        
        let healthKitStore = DataManager().healthStore
      do {
        //1. This method throws an error if these data are not available.
        let birthdayComponents =  try healthKitStore.dateOfBirthComponents()
        let biologicalSex =       try healthKitStore.biologicalSex()

        //2. Use Calendar to calculate age.
        let today = Date()
        let calendar = Calendar.current
        let todayDateComponents = calendar.dateComponents([.year],
                                                            from: today)
        let thisYear = todayDateComponents.year!
        let age = thisYear - birthdayComponents.year!
         
        //3. Unwrap the wrappers to get the underlying enum values.
        let unwrappedBiologicalSex = biologicalSex.biologicalSex
          
        return (age, unwrappedBiologicalSex)
      }
    }
    
    class func getMostRecentSample(for sampleType: HKSampleType,
                                   completion: @escaping (HKQuantitySample?, Error?) -> Swift.Void) {
      
        //1. Use HKQuery to load the most recent samples.
        let mostRecentPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast,
                                                              end: Date(),
                                                              options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: false)
        let limit = 1
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: mostRecentPredicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            //2. Always dispatch to the main thread when complete.
            DispatchQueue.main.async {
                guard let samples = samples,
                    let mostRecentSample = samples.first as? HKQuantitySample else {
                        
                    completion(nil, error)
                    return
              }
              completion(mostRecentSample, nil)
            }
          }
         
        DataManager().healthStore.execute(sampleQuery)
    }
        
    class func getAverageBloodGlucose(completion: @escaping (HKQuantity?, Error?) -> Swift.Void) {
          
        //1. Use HKQuery to get samples from the last hour
        let predicate = HKQuery.predicateForSamples(withStart: Date(timeIntervalSinceNow: -60*60),
                                                          end: Date(),
                                                          options: .strictEndDate)

        // Create the query descriptor.
        let bloodGlucoseType = HKQuantityType(.bloodGlucose)
        let query = HKStatisticsQuery(quantityType: bloodGlucoseType, quantitySamplePredicate: predicate, options: .discreteAverage) { query, results, error in
            //2. Always dispatch to the main thread when complete.
            DispatchQueue.main.async {
                guard let results = results,
                      let averageValue = results.averageQuantity() else {
                        
                    completion(nil, error)
                    return
              }
              completion(averageValue, nil)
            }
          }
         
        DataManager().healthStore.execute(query)
    }
    
    
    
    
    
    
    class func getSamples(for sampleType: HKSampleType, start: Date, completion: @escaping ([HKQuantitySample]?, Error?) -> Swift.Void) {
          
        //1. Use HKQuery to get samples from the last hour
        let predicate = HKQuery.predicateForSamples(withStart: start,
                                                          end: Date(),
                                                          options: .strictEndDate)

        // Sort by the oldest first
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: true)
        
        let limit = 1000 // Upper limit of 1000 samples (like 3 days)
        
        let sampleQuery = HKSampleQuery(sampleType: sampleType,
                                        predicate: predicate,
                                        limit: limit,
                                        sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            //2. Always dispatch to the main thread when complete.
            DispatchQueue.main.async {
                guard let samples = samples as? [HKQuantitySample] else {
                    completion(nil, error)
                    return
                }
                completion(samples, nil)
            }
          }
         
        DataManager().healthStore.execute(sampleQuery)
    }
    
    
    
    
    
    
    

    
    
    
    
    
    
    
    // JUST DO EVERYTHING HERE FIRST!
    // YOU CAN REFACTOR LATER!
    class func getAutotune(completion: @escaping (HKQuantity?, Error?) -> Swift.Void) {
        
        // Define the time period, lets start with the last hour
        let startDate = Date(timeIntervalSinceNow: -60*60)
        
        guard let glucoseLevelSampleType = HKSampleType.quantityType(forIdentifier: .bloodGlucose) else {
          print("Glucose Level Sample Type is no longer available in HealthKit")
          return
        }
        
        // Get all the relevant insulin and glucose values
        getSamples(for: glucoseLevelSampleType, start: startDate) { samples, error in
            //print(samples)
            
            // TODO: Write guard let before you do the calculations,
            // instead of force unwrapping
            
            print("NUMBER OF SAMPLES")
            
            for i in 1...samples!.endIndex {
                print("SAMPLE BY INDEX")
                print(samples![i-1].quantity.doubleValue(for: .millimolesPerLiter))
                
                // 
                //self.timeDelta = TimeDelta()
            }
            
            // step 1: get the difference between all the glucose values
            // Cast the sampels to bloodglucose type
            // Store the values in a list in this class
            // create a method that takes sampes and returns the collection of delta objects containing delta objects
            
            
            // LoopKit:
            // GlucoseSampleValue or GlucoseValue
        }
        
        // Create a model for delta glucose (or extend from LoopKit), where you store the absorbed insulin and all the results
        
        // Store all Delta Glucose objects into an array.
        
        // Create a model for the collection of delta glucose (or extend from LoopKit)
        // In this model you can calculate for example getPercentageFromSettings
        
        // Be aware of possible memory leaks if you calculate over big time spans,
        // for later you should implement core data or realm.
    }
    
    
}
