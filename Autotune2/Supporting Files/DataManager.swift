//
//  DataManager.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 12/09/2022.
//

import LoopKit
import HealthKit

final class DataManager {
    
    // MARK: User Settings
    let insulinModel: InsulinModel
    
    let basalProfile: BasalRateSchedule
    
    let ISFProfile: InsulinSensitivitySchedule
    
    let carbRatio: CarbRatioSchedule
    
    // MARK: Stores
    let healthStore: HKHealthStore
    
    //let carbStore: CarbStore
    
    let doseStore: DoseStore
    
    //let glucoseStore: GlucoseStore

    private let cacheStore: PersistenceController
    
    init() {
        self.healthStore = HKHealthStore()
        self.cacheStore = PersistenceController.controllerInLocalDirectory()
        self.insulinModel = ExponentialInsulinModel(actionDuration: 360*60, peakActivityTime: 75*60)
        self.basalProfile = BasalRateSchedule(dailyItems: [RepeatingScheduleValue(startTime: TimeInterval(), value: 0.8)])!
        self.carbRatio = CarbRatioSchedule(unit: .gram(), dailyItems: [RepeatingScheduleValue(startTime: TimeInterval(), value: 10.5)])!
        self.ISFProfile = InsulinSensitivitySchedule(unit: .millimolesPerLiter, dailyItems: [RepeatingScheduleValue(startTime: TimeInterval(), value: 3.9)])!
        
        //LoopKit.CarbAbsorptionModel.nonlinear (there are three, discover in loop which is default etc)
        
        self.doseStore = DoseStore(healthStore: healthStore, cacheStore: cacheStore, insulinModel: insulinModel, basalProfile: basalProfile, insulinSensitivitySchedule: ISFProfile)
       
        // TODO: Create a InsulinDataStore where you create all the methods you need, with inspiration from SleepStore in HealthKit
        // Because the DoseStore in LoopKit is unneccesarily complicated for your needs
    }
}
