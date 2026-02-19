//
//  GenerateScheduleUseCase.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

class GenerateScheduleUseCase {
    private let todoRepository: TodoRepositoryProtocol
    private let calendar: Calendar = .current
    
    init(todoRepository: TodoRepositoryProtocol) {
        self.todoRepository = todoRepository
    }
    
    func execute(for date: Date, userProfile: UserProfile) async throws {
        // 1. Check if we already have system generated tasks for this day
        let existingTodos = try await todoRepository.getTodos(for: date)
        if existingTodos.contains(where: { $0.isSystemGenerated }) {
            return // Already generated for this day
        }
        
        let dayOfWeek = calendar.component(.weekday, from: date)
        
        // 2. Add Work Block
        if userProfile.workSchedule?.hasWork == true {
             // 2 (Mon) ... 6 (Fri) usually, but let's assume M-F for MVP or check specific days if we had that detail
             // Assuming UserProfile has simplistic "Has Work" -> Mon-Fri
             if dayOfWeek >= 2 && dayOfWeek <= 6 {
                 if let start = userProfile.workSchedule?.startTime,
                    let end = userProfile.workSchedule?.endTime {
                     
                     // Adjust time to be on 'date'
                     let startToday = timeOnDate(time: start, date: date)
                     let title = "Horário de Trabalho (\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened)))"
                     
                     let workItem = TodoItem(
                        title: title,
                        date: date,
                        time: startToday,
                        type: .work,
                        isSystemGenerated: true
                     )
                     try await todoRepository.save(item: workItem)
                 }
             }
        }
        
        // 3. Add Study Block
        if userProfile.studySchedule.studies {
            // Again assuming M-F or everyday? Let's assume everyday for study for now or M-F
            // Ideally we'd have days selection in onboarding, but MVP.
            let start = userProfile.studySchedule.startTime
            let end = userProfile.studySchedule.endTime
            
            let startToday = timeOnDate(time: start, date: date)
            let title = "Horário de Estudos (\(start.formatted(date: .omitted, time: .shortened)) - \(end.formatted(date: .omitted, time: .shortened)))"
            
            let studyItem = TodoItem(
               title: title,
               date: date,
               time: startToday,
               type: .study,
               isSystemGenerated: true
            )
            try await todoRepository.save(item: studyItem)
        }
    }
    
    private func timeOnDate(time: Date, date: Date) -> Date {
        let components = calendar.dateComponents([.hour, .minute], from: time)
        return calendar.date(bySettingHour: components.hour ?? 0, minute: components.minute ?? 0, second: 0, of: date) ?? date
    }
}
