//
//  DailyPlanEngine.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import Foundation

public final class DailyPlanEngine: @unchecked Sendable {
    public static let shared = DailyPlanEngine()
    
    private init() {}
    
    // MARK: - Intent Detection
    
    public func isPlanningIntent(_ text: String) -> Bool {
        isPlanningIntent(text: text, hasActivePlan: false)
    }

    public func isPlanningIntent(text: String, hasActivePlan: Bool = false) -> Bool {
        let normalized = text.lowercased().folding(options: .diacriticInsensitive, locale: .current)
        
        var triggers = [
            "rotina",
            "rotinas",
            "meu dia",
            "planejar",
            "planejamento",
            "planeje",
            "planeja",
            "plano",
            "planos",
            "cronograma",
            "agenda",
            "organizar",
            "organize",
            "organizacao",
            "horario",
            "horarios",
            "tarefa",
            "tarefas",
            "bloco",
            "blocos",
            "reorganizar",
            "reorganize",
            "recalibrar",
            "atrasei",
            "acordei tarde",
            "mudei de plano",
            "novo compromisso",
            "estudar",
            "estudo",
            "trabalhar",
            "trabalho",
            "academia",
            "treino",
            "conclui",
            "concluido",
            "terminei",
            "fechei o bloco"
        ]
        
        if hasActivePlan {
            triggers.append(contentsOf: ["concluir", "fechar", "mudar", "remarcar", "adiar", "pausa"])
        }
        
        return triggers.contains { normalized.contains($0) }
    }
    
    public func isPlanningConfirmationIntent(_ text: String) -> Bool {
        let normalized = text.lowercased().trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current)
        let exactYes = ["sim", "s", "ok", "claro", "com certeza", "bora", "pode ser", "perfeito", "otimo", "beleza", "fechado", "combinado", "vamos"]
        if exactYes.contains(normalized) {
            return true
        }
        let confirmTriggers = [
            "pode criar",
            "pode salvar",
            "pode confirmar",
            "confirmo",
            "confirmar",
            "ativar",
            "ativa o plano",
            "ativar plano",
            "salvar plano",
            "gostei",
            "cria pra mim",
            "crie pra mim",
            "pode montar",
            "aprovo",
            "aprovado",
            "aceito",
            "salva esse",
            "salvar esse"
        ]
        return confirmTriggers.contains { normalized.contains($0) }
    }
    
    // MARK: - Time Parsing & Formatting
    
    public func parseTime(from timeString: String, baseDate: Date = Date()) -> Date? {
        let cleaned = timeString.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "h", with: ":")
            .replacingOccurrences(of: "H", with: ":")
        
        let parts = cleaned.split(separator: ":")
        guard parts.count >= 1, let hour = Int(parts[0]), hour >= 0, hour < 24 else {
            return nil
        }
        
        let minute = parts.count >= 2 ? (Int(parts[1]) ?? 0) : 0
        guard minute >= 0, minute < 60 else {
            return nil
        }
        
        let calendar = Calendar.current
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: baseDate)
    }
    
    public func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter.string(from: date)
    }
    
    // MARK: - Validation
    
    public func validateBlock(_ block: PlannedBlock) -> [String] {
        var errors: [String] = []
        
        if block.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("O título do bloco não pode estar vazio.")
        }
        
        if block.endTime <= block.startTime {
            errors.append("O horário de término deve ser posterior ao horário de início.")
        }
        
        if block.durationMinutes < 5 {
            errors.append("O bloco deve ter pelo menos 5 minutos de duração.")
        }
        
        if block.durationMinutes > 360 {
            errors.append("Blocos com mais de 6 horas devem ser divididos em etapas com descanso.")
        }
        
        return errors
    }
    
    public func validateBlocks(_ blocks: [PlannedBlock]) -> [String] {
        var allErrors: [String] = []
        for block in blocks {
            let errors = validateBlock(block)
            allErrors.append(contentsOf: errors)
        }
        return allErrors
    }
    
    // MARK: - Conflict Detection
    
    public func detectConflicts(in blocks: [PlannedBlock]) -> [(PlannedBlock, PlannedBlock)] {
        let sorted = blocks.sorted { $0.startTime < $1.startTime }
        var conflicts: [(PlannedBlock, PlannedBlock)] = []
        
        for i in 0..<sorted.count {
            for j in (i + 1)..<sorted.count {
                let first = sorted[i]
                let second = sorted[j]
                
                // If second starts before first ends, there is an overlap
                if second.startTime < first.endTime {
                    conflicts.append((first, second))
                } else {
                    // Since it's sorted by startTime, subsequent blocks start even later
                    break
                }
            }
        }
        
        return conflicts
    }
    
    // MARK: - Proposed Blocks Conversion
    
    public func convertProposedBlocks(
        _ proposed: [AIProposedBlock],
        baseDate: Date = Date()
    ) -> [PlannedBlock] {
        var result: [PlannedBlock] = []
        
        for (index, item) in proposed.enumerated() {
            guard let start = parseTime(from: item.startTime, baseDate: baseDate),
                  let end = parseTime(from: item.endTime, baseDate: baseDate),
                  end > start else {
                continue
            }
            
            let category = BlockCategory(rawValue: item.category.lowercased()) ?? .personal
            let priority: BlockPriority
            switch item.priority?.lowercased() {
            case "high", "alta": priority = .high
            case "low", "baixa": priority = .low
            default: priority = .medium
            }
            
            let block = PlannedBlock(
                id: item.id.flatMap(UUID.init(uuidString:)) ?? UUID(),
                title: item.title,
                category: category,
                startTime: start,
                endTime: end,
                priority: priority,
                status: .planned,
                note: item.note,
                order: index
            )
            result.append(block)
        }
        
        return result.sorted { $0.startTime < $1.startTime }
    }
    
    // MARK: - Starter Blocks Generator (Fallback if AI proposes 0 blocks)
    
    public func generateDefaultStarterProposedBlocks(
        startingFrom: Date = Date(),
        readinessScore: Double? = nil
    ) -> [AIProposedBlock] {
        let calendar = Calendar.current
        let isLowEnergy = (readinessScore ?? 7.0) < 5.0
        let focusMinutes = isLowEnergy ? 45 : 75
        let restMinutes = isLowEnergy ? 25 : 15
        
        let start1 = startingFrom
        let end1 = calendar.date(byAdding: .minute, value: focusMinutes, to: start1) ?? start1.addingTimeInterval(TimeInterval(focusMinutes * 60))
        
        let start2 = end1
        let end2 = calendar.date(byAdding: .minute, value: restMinutes, to: start2) ?? start2.addingTimeInterval(TimeInterval(restMinutes * 60))
        
        let start3 = end2
        let end3 = calendar.date(byAdding: .minute, value: focusMinutes, to: start3) ?? start3.addingTimeInterval(TimeInterval(focusMinutes * 60))
        
        let start4 = calendar.date(byAdding: .hour, value: 3, to: start1) ?? start1.addingTimeInterval(3 * 3600)
        let end4 = calendar.date(byAdding: .minute, value: 45, to: start4) ?? start4.addingTimeInterval(45 * 60)
        
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        
        return [
            AIProposedBlock(
                title: "Foco Principal & Prioridade",
                category: "study",
                startTime: formatter.string(from: start1),
                endTime: formatter.string(from: end1),
                priority: "high",
                note: "Momento de dedicação com menor distração."
            ),
            AIProposedBlock(
                title: "Pausa Consciente & Hidratação",
                category: "rest",
                startTime: formatter.string(from: start2),
                endTime: formatter.string(from: end2),
                priority: "medium",
                note: "Respire fundo, beba água e afaste-se da tela."
            ),
            AIProposedBlock(
                title: "Segundo Bloco de Atividades",
                category: "work",
                startTime: formatter.string(from: start3),
                endTime: formatter.string(from: end3),
                priority: "medium",
                note: "Continuidade no ritmo sustentável."
            ),
            AIProposedBlock(
                title: "Caminhada ou Descompressão",
                category: "health",
                startTime: formatter.string(from: start4),
                endTime: formatter.string(from: end4),
                priority: "low",
                note: "Liberar a tensão acumulada do dia."
            )
        ]
    }
    
    // MARK: - Reorganize Remainder of the Day
    
    public func reorganizeRemainderOfDay(
        currentPlan: DailyPlan,
        startingFrom: Date,
        newBlocks: [PlannedBlock]? = nil,
        readinessScore: Double? = nil
    ) -> DailyPlan {
        var updated = currentPlan
        
        // 1. Preserve all completed blocks intact regardless of time
        let completedBlocks = currentPlan.blocks.filter { $0.status == .completed }
        
        // 2. Candidate uncompleted blocks to reschedule for remainder of the day
        var incomingBlocks: [PlannedBlock]
        if let newBlocks = newBlocks, !newBlocks.isEmpty {
            incomingBlocks = newBlocks
        } else {
            // Keep all pending or inProgress blocks that weren't completed yet
            incomingBlocks = currentPlan.blocks.filter { $0.status != .completed }
        }
        
        // Reset state of rescheduled blocks to planned
        var rescheduled: [PlannedBlock] = []
        var currentTimeCursor = startingFrom
        
        // Adjust for readiness
        let isLowEnergy = (readinessScore ?? 7.0) < 5.0
        let maxWorkDurationMinutes = isLowEnergy ? 45 : 90
        let restIntervalMinutes = isLowEnergy ? 20 : 15
        
        for var block in incomingBlocks {
            let originalDuration = block.durationMinutes
            let adjustedDuration: Int
            if isLowEnergy && (block.category == .study || block.category == .work) {
                adjustedDuration = min(originalDuration, maxWorkDurationMinutes)
            } else {
                adjustedDuration = max(15, originalDuration)
            }
            
            // Adjust start and end times to be at least startingFrom / currentTimeCursor
            if block.startTime < currentTimeCursor {
                block.startTime = currentTimeCursor
                block.endTime = currentTimeCursor.addingTimeInterval(TimeInterval(adjustedDuration * 60))
            } else if adjustedDuration != originalDuration {
                block.endTime = block.startTime.addingTimeInterval(TimeInterval(adjustedDuration * 60))
            }
            
            if block.status != .completed {
                block.status = .planned
            }
            
            rescheduled.append(block)
            
            // Move cursor to end of block plus recommended rest interval
            currentTimeCursor = block.endTime.addingTimeInterval(TimeInterval(restIntervalMinutes * 60))
        }
        
        // Combine preserved completed blocks and rescheduled blocks
        var allCombined = completedBlocks
        for block in rescheduled {
            if !allCombined.contains(where: { $0.id == block.id }) {
                allCombined.append(block)
            }
        }
        
        allCombined.sort { $0.startTime < $1.startTime }
        
        // Re-index order
        for i in 0..<allCombined.count {
            allCombined[i].order = i
        }
        
        updated.blocks = allCombined
        updated.updatedAt = Date()
        return updated
    }
}
