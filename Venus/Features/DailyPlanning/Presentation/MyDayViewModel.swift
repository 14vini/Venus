//
//  MyDayViewModel.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import SwiftUI
import SwiftData

@MainActor
@Observable
final class MyDayViewModel {
    var currentPlan: DailyPlan? = nil
    var isLoading: Bool = false
    var showVenusChat: Bool = false
    var chatInitialPrompt: String? = nil
    var readinessAssessment: ReadinessEnergyAssessment? = nil
    var userProfile: UserProfile? = nil
    
    // Manual Creation / Editing State
    var showingAddBlockSheet: Bool = false
    var blockToEdit: PlannedBlock? = nil
    
    private let dailyPlanRepository: DailyPlanRepositoryProtocol
    private let userProfileRepository: UserProfileRepositoryProtocol
    private let moodRepository: MoodRepositoryProtocol
    private let readinessEngine: ReadinessEngineProtocol
    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    
    init(
        dailyPlanRepository: DailyPlanRepositoryProtocol? = nil,
        userProfileRepository: UserProfileRepositoryProtocol? = nil,
        moodRepository: MoodRepositoryProtocol? = nil,
        readinessEngine: ReadinessEngineProtocol? = nil
    ) {
        self.dailyPlanRepository = dailyPlanRepository ?? DependencyContainer.shared.makeDailyPlanRepository()
        self.userProfileRepository = userProfileRepository ?? DependencyContainer.shared.makeUserProfileRepository()
        self.moodRepository = moodRepository ?? DependencyContainer.shared.makeMoodRepository()
        self.readinessEngine = readinessEngine ?? DependencyContainer.shared.makeReadinessEngine()
    }
    
    func onAppear() {
        Task {
            await loadData()
        }
    }
    
    func loadData() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            self.userProfile = try await userProfileRepository.load()
            self.currentPlan = try await dailyPlanRepository.getPlan(for: Date())
            
            let allMoods = (try? await moodRepository.getAllMoods()) ?? []
            let todayMood = allMoods.last?.type
            let todayMoodItem = allMoods.last
            self.readinessAssessment = readinessEngine.evaluate(
                todayMood: todayMood,
                todayMoodItem: todayMoodItem,
                weekMoods: allMoods,
                hasRecentChat: false,
                biometrics: nil,
                chatImpact: nil,
                aiStateTitle: nil,
                aiStateSubtitle: nil
            )
        } catch {
            print("Erro ao carregar Meu dia: \(error)")
        }
    }
    
    var focusQuote: String {
        if let summary = currentPlan?.summary, !summary.isEmpty {
            return summary
        }
        
        if let score = readinessAssessment?.score {
            if score < 5.0 {
                return "Sua energia pede gentileza. Proteja pausas e foque apenas no essencial."
            } else if score < 7.5 {
                return "Um passo de cada vez. Mantenha um ritmo sustentável ao longo do dia."
            } else {
                return "Energia e clareza alinhadas. O que mais importa realizar hoje?"
            }
        }
        
        return "Respire fundo e escolha uma única prioridade de cada vez."
    }
    
    var topPriorities: [PlannedBlock] {
        guard let plan = currentPlan else { return [] }
        return plan.topPriorities
    }
    
    var timelineBlocks: [PlannedBlock] {
        guard let plan = currentPlan else { return [] }
        return plan.blocks.sorted { $0.startTime < $1.startTime }
    }
    
    var completedCount: Int {
        currentPlan?.completedBlocksCount ?? 0
    }
    
    var totalCount: Int {
        currentPlan?.totalBlocksCount ?? 0
    }
    
    var nextBlock: PlannedBlock? {
        timelineBlocks.first { $0.status == .inProgress } ??
        timelineBlocks.first { $0.status == .planned && $0.endTime > Date() }
    }
    
    // MARK: - Block Status Actions
    
    func startBlock(id: UUID) {
        updateBlockStatus(id: id, status: .inProgress)
    }
    
    func completeBlock(id: UUID) {
        updateBlockStatus(id: id, status: .completed)
    }
    
    func skipBlock(id: UUID) {
        updateBlockStatus(id: id, status: .skipped)
    }
    
    func resetBlock(id: UUID) {
        updateBlockStatus(id: id, status: .planned)
    }
    
    private func updateBlockStatus(id: UUID, status: BlockStatus) {
        guard var plan = currentPlan else { return }
        guard let index = plan.blocks.firstIndex(where: { $0.id == id }) else { return }
        
        plan.blocks[index].status = status
        self.currentPlan = plan
        haptic.impactOccurred()
        
        Task {
            try? await dailyPlanRepository.updateBlockStatus(planId: plan.id, blockId: id, status: status)
            if let refreshed = try? await dailyPlanRepository.getPlan(for: Date()) {
                self.currentPlan = refreshed
            }
        }
    }
    
    // MARK: - Manual Creation & Management
    
    func startCreatingBlock() {
        let calendar = Calendar.current
        let now = Date()
        let minute = calendar.component(.minute, from: now)
        let roundedMinute = ((minute / 15) + 1) * 15
        let start = calendar.date(bySettingHour: calendar.component(.hour, from: now), minute: roundedMinute % 60, second: 0, of: now) ?? now
        let end = calendar.date(byAdding: .minute, value: 45, to: start) ?? start.addingTimeInterval(45 * 60)
        
        self.blockToEdit = PlannedBlock(
            title: "",
            category: .study,
            startTime: start,
            endTime: end,
            priority: .medium,
            status: .planned
        )
        self.showingAddBlockSheet = true
        haptic.impactOccurred()
    }
    
    func editBlock(_ block: PlannedBlock) {
        self.blockToEdit = block
        self.showingAddBlockSheet = true
        haptic.impactOccurred()
    }
    
    func saveManualBlock(_ block: PlannedBlock) {
        var plan = currentPlan ?? DailyPlan(
            date: Date(),
            state: .active,
            summary: "Rotina criada por você",
            blocks: []
        )
        
        if let index = plan.blocks.firstIndex(where: { $0.id == block.id }) {
            plan.blocks[index] = block
        } else {
            plan.blocks.append(block)
        }
        
        // Sort and re-index
        plan.blocks.sort { $0.startTime < $1.startTime }
        for i in 0..<plan.blocks.count {
            plan.blocks[i].order = i
        }
        plan.updatedAt = Date()
        
        self.currentPlan = plan
        self.showingAddBlockSheet = false
        self.blockToEdit = nil
        haptic.impactOccurred()
        
        Task {
            try? await dailyPlanRepository.save(plan: plan)
            if let refreshed = try? await dailyPlanRepository.getPlan(for: Date()) {
                self.currentPlan = refreshed
            }
        }
    }
    
    func deleteBlock(id: UUID) {
        guard var plan = currentPlan else { return }
        plan.blocks.removeAll { $0.id == id }
        
        plan.blocks.sort { $0.startTime < $1.startTime }
        for i in 0..<plan.blocks.count {
            plan.blocks[i].order = i
        }
        plan.updatedAt = Date()
        
        self.currentPlan = plan
        self.showingAddBlockSheet = false
        self.blockToEdit = nil
        haptic.impactOccurred()
        
        Task {
            try? await dailyPlanRepository.save(plan: plan)
            if let refreshed = try? await dailyPlanRepository.getPlan(for: Date()) {
                self.currentPlan = refreshed
            }
        }
    }
    
    // MARK: - Navigation to AI Chat
    
    func openReorganizeChat() {
        chatInitialPrompt = "Preciso reorganizar meu dia a partir de agora. Acabei me atrasando ou tive imprevistos."
        showVenusChat = true
        haptic.impactOccurred()
    }
    
    func openPlanChat() {
        chatInitialPrompt = "Quero planejar minha rotina de hoje com a Venus."
        showVenusChat = true
        haptic.impactOccurred()
    }
}
