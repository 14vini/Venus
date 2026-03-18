//
//  OnboardingScheduleValidator.swift
//  Venus
//
//  Created by Codex on 20/02/26.
//

import Foundation

enum OnboardingScheduleValidator {
    static let minimumDurationMinutes = 30
    static let maximumDurationMinutes = 18 * 60
    
    static func isValid(start: Date, end: Date) -> Bool {
        let duration = durationInMinutes(start: start, end: end)
        return duration >= minimumDurationMinutes && duration <= maximumDurationMinutes
    }
    
    static func isOvernight(start: Date, end: Date) -> Bool {
        minutesSinceMidnight(for: end) < minutesSinceMidnight(for: start)
    }
    
    static func validationMessage(start: Date, end: Date, context: String) -> String? {
        let duration = durationInMinutes(start: start, end: end)
        
        if duration == 0 {
            return "Os horários de \(context) não podem ser iguais."
        }
        
        if duration < minimumDurationMinutes {
            return "A janela de \(context) precisa ter pelo menos 30 minutos."
        }
        
        if duration > maximumDurationMinutes {
            return "A janela de \(context) está longa demais. Ajuste para até 18h."
        }
        
        return nil
    }
    
    static func durationInMinutes(start: Date, end: Date) -> Int {
        let startMinutes = minutesSinceMidnight(for: start)
        let endMinutes = minutesSinceMidnight(for: end)
        
        if startMinutes == endMinutes {
            return 0
        }
        
        if endMinutes > startMinutes {
            return endMinutes - startMinutes
        }
        
        // Supports overnight ranges (e.g. 22:00 -> 06:00).
        return (24 * 60 - startMinutes) + endMinutes
    }
    
    private static func minutesSinceMidnight(for date: Date) -> Int {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (components.hour ?? 0) * 60 + (components.minute ?? 0)
    }
}
