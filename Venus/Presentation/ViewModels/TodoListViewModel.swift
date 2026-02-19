//
//  TodoListViewModel.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation
import Combine
import SwiftUI

enum CalendarMode: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

@MainActor
class TodoListViewModel: ObservableObject {
    @Published var selectedDate: Date = Date()
    @Published var selectedMonth: Date = Date() // For Month View
    @Published var todos: [TodoItem] = []
    @Published var completedCount: Int = 0
    @Published var totalCount: Int = 0
    
    @Published var calendarMode: CalendarMode = .week
    @Published var showAddSheet: Bool = false
    
    // Properties for date strip
    @Published var currentWeek: [Date] = []
    
    private let todoRepository: TodoRepositoryProtocol
    private let generateScheduleUseCase: GenerateScheduleUseCase
    private let userProfileRepository: UserProfileRepositoryProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(
        todoRepository: TodoRepositoryProtocol,
        generateScheduleUseCase: GenerateScheduleUseCase,
        userProfileRepository: UserProfileRepositoryProtocol
    ) {
        self.todoRepository = todoRepository
        self.generateScheduleUseCase = generateScheduleUseCase
        self.userProfileRepository = userProfileRepository
        
        setupWeek(for: Date())
        setupBindings()
        Task { await loadData(for: Date()) }
    }
    
    private func setupWeek(for date: Date) {
        let calendar = Calendar.current
        // Find start of the week for the given date
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date))!
        
        self.currentWeek = (0..<7).compactMap { day in
            calendar.date(byAdding: .day, value: day, to: startOfWeek)
        }
    }
    
    private func setupBindings() {
        $selectedDate
            .sink { [weak self] newDate in
                guard let self = self else { return }
                // Re-setup week if selected date is out of current week?
                // For simplified UX, we can just load data
                Task {
                    await self.loadData(for: newDate)
                    if !self.isDateInCurrentWeek(newDate) {
                        self.setupWeek(for: newDate)
                    }
                }
            }
            .store(in: &cancellables)
            
        $selectedMonth
             .sink { [weak self] _ in
                 // Logic to handle month change if needed
             }
             .store(in: &cancellables)
    }
    
    func loadData(for date: Date) async {
        do {
            // 1. Ensure schedule blocks are generated
            if let profile = try await userProfileRepository.load() {
                try await generateScheduleUseCase.execute(for: date, userProfile: profile)
            }
            
            // 2. Load todos
            let items = try await todoRepository.getTodos(for: date)
            self.todos = items
            self.calculateProgress()
        } catch {
            print("Error loading todos: \(error)")
        }
    }
    
    func toggleTodo(id: UUID) {
        // Optimistic update
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos[index].isCompleted.toggle()
            calculateProgress()
            
            Task {
                try? await todoRepository.toggleCompletion(id: id)
            }
        }
    }
    
    func deleteTodo(id: UUID) {
        if let index = todos.firstIndex(where: { $0.id == id }) {
            todos.remove(at: index)
            calculateProgress()
            
            Task {
                try? await todoRepository.delete(id: id)
            }
        }
    }
    
    func addTodo(title: String, time: Date? = nil, type: TodoType = .task) {
        let newItem = TodoItem(
            title: title,
            date: selectedDate,
            time: time,
            type: type
        )
        
        Task {
            try? await todoRepository.save(item: newItem)
            await loadData(for: selectedDate)
        }
    }
    
    private func calculateProgress() {
        totalCount = todos.count
        completedCount = todos.filter { $0.isCompleted }.count
    }
    
    func isSameDay(date1: Date, date2: Date) -> Bool {
        Calendar.current.isDate(date1, inSameDayAs: date2)
    }
    
    private func isDateInCurrentWeek(_ date: Date) -> Bool {
        guard let first = currentWeek.first, let last = currentWeek.last else { return false }
        let calendar = Calendar.current
        // Simple check if date is between first and last
        return date >= calendar.startOfDay(for: first) && date <= calendar.date(bySettingHour: 23, minute: 59, second: 59, of: last)!
    }
}
