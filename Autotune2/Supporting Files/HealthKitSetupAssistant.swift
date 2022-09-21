/**
 * This file is inspired from the following free of charge HealthKit Tutorial:
 * https://www.raywenderlich.com/459-healthkit-tutorial-with-swift-getting-started#ratings-count-hook
 *
 */

import HealthKit

class HealthKitSetupAssistant {
  
  private enum HealthkitSetupError: Error {
    case notAvailableOnDevice
    case dataTypeNotAvailable
  }
  
    // TODO: Cleanup this method to only contain needed datatypes
    
  class func authorizeHealthKit(completion: @escaping (Bool, Error?) -> Swift.Void) {
      //1. Check to see if HealthKit Is Available on this device
      guard HKHealthStore.isHealthDataAvailable() else {
        completion(false, HealthkitSetupError.notAvailableOnDevice)
        return
      }
      
      //2. Prepare the data types that will interact with HealthKit
      guard let bloodGlucose = HKObjectType.quantityType(forIdentifier: .bloodGlucose),
            let insulin = HKObjectType.quantityType(forIdentifier: .insulinDelivery),
            let carbohydrates = HKObjectType.quantityType(forIdentifier: .dietaryCarbohydrates)
      else {
              completion(false, HealthkitSetupError.dataTypeNotAvailable)
              return
      }
      
      //3. Prepare a list of types you want HealthKit to read and write
      //let healthKitTypesToWrite: Set<HKSampleType> = [HKObjectType.workoutType()]
          
      let healthKitTypesToRead: Set<HKObjectType> = [bloodGlucose,
                                                     insulin,
                                                     carbohydrates]
      
      //4. Request Authorization
      HKHealthStore().requestAuthorization(toShare: nil,
                                           read: healthKitTypesToRead) { (success, error) in
        completion(success, error)
      }
  }
}
