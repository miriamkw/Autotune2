//
//  HealthKitDataStore.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 20/09/2022.
//

import HealthKit
import LoopKit
import UIKit

final class HealthKitDataStore {
    
    let healthStore = HKHealthStore()
    // Create singleton instance
    static let shared = HealthKitDataStore()
    
    func getSamples(for sampleType: HKSampleType, start: Date, end: Date = Date(), completion: @escaping ([HKQuantitySample]?, Error?) -> Swift.Void) {
          
        //1. Use HKQuery to get samples from the last hour
        let predicate = HKQuery.predicateForSamples(withStart: start,
                                                          end: end,
                                                          options: .strictEndDate)

        // Sort by the oldest first, this is important when calculating difference in glucose value samples
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate,
                                              ascending: true)
        
        let limit = 10000 // Upper limit of 10000 samples, should be enough for one month if there are maximum 14 samples per hour
        
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
         
        self.healthStore.execute(sampleQuery)
    }
    
}


