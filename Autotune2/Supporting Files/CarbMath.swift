//
//  CarbMath.swift
//  Autotune2
//
//  Created by Miriam Kopperstad Wolff on 18/09/2022.
// Code is borrowed from LoopKit CarbMath
//

import Foundation

struct CarbMath {
    
    // MARK: - Piecewise linear absorption as a factor of reported duration
    /// Nonlinear  carb absorption model where absorption rate increases linearly from zero to a maximum value at a fraction of absorption time equal to percentEndOfRise, then remains constant until a fraction of absorption time equal to percentStartOfFall, and then decreases linearly to zero at the end of absorption time
    /// - Parameters:
    ///   - percentEndOfRise: the percentage of absorption time when absorption rate reaches maximum, must be strictly between 0 and 1
    ///   - percentStartOfFall: the percentage of absorption time when absorption rate starts to decay, must be stritctly between 0 and 1 and  greater than percentEndOfRise
    public func percentEffectRemaining(at time: TimeInterval, actionDuration: Double) -> Double {
        
        let percentEndOfRise = 0.15
        let percentStartOfFall = 0.5
        var scale: Double {
            return 2.0 / (1.0 + percentStartOfFall - percentEndOfRise)
        }
        
        func percentAbsorptionAtPercentTime(_ percentTime: Double) -> Double {
            switch percentTime {
            case let t where t <= 0.0:
                return 0.0
            case let t where t < percentEndOfRise:
                return 0.5 * scale * pow(t, 2.0) / percentEndOfRise
            case let t where t >= percentEndOfRise && t < percentStartOfFall:
                return scale * (t - 0.5 * percentEndOfRise)
            case let t where t >= percentStartOfFall && t < 1.0:
                return scale * (percentStartOfFall - 0.5 * percentEndOfRise +
                (t - percentStartOfFall) * (1.0 - 0.5 * (t - percentStartOfFall) / (1.0 - percentStartOfFall)))
            default:
                return 1.0
            }
        }
        
        return 1 - percentAbsorptionAtPercentTime(time/actionDuration)
    }
    
    
    
}
