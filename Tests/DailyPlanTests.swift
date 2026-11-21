//
//  DailyPlanTests.swift
//  Venus Tests
//
//  Created for Venus Daily Planning MVP.
//

import Foundation
import SwiftData

@main
struct DailyPlanTestsRunner {
    static func main() async {
        print("🔮 =========================================")
        print("🔮 INICIANDO BATERIA DE TESTES: DAILY PLANNING")
        print("🔮 VENUS: ASSISTENTE ADAPTATIVA DE ROTINA")
        print("🔮 =========================================\n")
        
        var passedCount = 0
        var totalCount = 0
        
        func test(_ name: String, block: () async throws -> Void) async {
            totalCount += 1
            do {
                try await block()
                print("  ✅ [PASS] \(name)")
                passedCount += 1
            } catch {
                print("  ❌ [FAIL] \(name): \(error)")
            }
        }
        
        let engine = DailyPlanEngine.shared
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        func makeTime(hour: Int, minute: Int = 0) -> Date {
            calendar.date(bySettingHour: hour, minute: minute, second: 0, of: today)!
        }
        
        // MARK: - TEST 1: Conflitos de Horários
        await test("1. Detecção de Conflitos de Horários (Overlaps)") {
            let block1 = PlannedBlock(
                title: "Estudo Matemática",
                category: .study,
                startTime: makeTime(hour: 14, minute: 0),
                endTime: makeTime(hour: 15, minute: 30)
            )
            let block2 = PlannedBlock(
                title: "Reunião de Trabalho",
                category: .work,
                startTime: makeTime(hour: 15, minute: 0), // Conflita das 15:00 às 15:30
                endTime: makeTime(hour: 16, minute: 0)
            )
            let block3 = PlannedBlock(
                title: "Treino",
                category: .health,
                startTime: makeTime(hour: 16, minute: 30),
                endTime: makeTime(hour: 17, minute: 30)
            )
            
            let conflicts = engine.detectConflicts(in: [block1, block2, block3])
            guard conflicts.count == 1 else {
                throw TestError("Esperado 1 conflito, obtido \(conflicts.count)")
            }
            guard conflicts.first?.0.title == "Estudo Matemática" && conflicts.first?.1.title == "Reunião de Trabalho" else {
                throw TestError("Pares de conflito incorretos")
            }
            
            // Sem conflito
            let noConflicts = engine.detectConflicts(in: [block1, block3])
            guard noConflicts.isEmpty else {
                throw TestError("Não deveria haver conflitos entre bloco 1 e 3")
            }
        }
        
        // MARK: - TEST 2: Validação de Blocos Inválidos
        await test("2. Validação de Blocos Inválidos") {
            let invalidEndBeforeStart = PlannedBlock(
                title: "Aula",
                category: .study,
                startTime: makeTime(hour: 15, minute: 0),
                endTime: makeTime(hour: 14, minute: 0) // Inválido
            )
            let errors1 = engine.validateBlock(invalidEndBeforeStart)
            guard errors1.contains(where: { $0.contains("posterior ao horário de início") }) else {
                throw TestError("Deveria acusar término anterior ao início")
            }
            
            let emptyTitleBlock = PlannedBlock(
                title: "   ",
                category: .personal,
                startTime: makeTime(hour: 10, minute: 0),
                endTime: makeTime(hour: 11, minute: 0)
            )
            let errors2 = engine.validateBlock(emptyTitleBlock)
            guard errors2.contains(where: { $0.contains("não pode estar vazio") }) else {
                throw TestError("Deveria acusar título vazio")
            }
            
            let shortBlock = PlannedBlock(
                title: "Pausa rápida",
                category: .rest,
                startTime: makeTime(hour: 10, minute: 0),
                endTime: makeTime(hour: 10, minute: 2) // 2 minutos (< 5 min)
            )
            let errors3 = engine.validateBlock(shortBlock)
            guard errors3.contains(where: { $0.contains("pelo menos 5 minutos") }) else {
                throw TestError("Deveria acusar duração menor que 5 min")
            }
        }
        
        // MARK: - TEST 3: Preservação de Blocos Concluídos
        await test("3. Preservação de Blocos Concluídos na Reorganização") {
            let completedBlock = PlannedBlock(
                title: "Leitura Matinal",
                category: .habit,
                startTime: makeTime(hour: 8, minute: 0),
                endTime: makeTime(hour: 8, minute: 30),
                status: .completed
            )
            let pendingBlock = PlannedBlock(
                title: "Estudo Matemática",
                category: .study,
                startTime: makeTime(hour: 9, minute: 0),
                endTime: makeTime(hour: 11, minute: 0),
                status: .planned
            )
            let initialPlan = DailyPlan(
                date: today,
                summary: "Plano Inicial",
                blocks: [completedBlock, pendingBlock]
            )
            
            // Usuário acordou tarde ou se atrasou, reorganizando a partir das 11h
            let reorganized = engine.reorganizeRemainderOfDay(
                currentPlan: initialPlan,
                startingFrom: makeTime(hour: 11, minute: 0),
                newBlocks: nil,
                readinessScore: 7.0
            )
            
            guard let preservedCompleted = reorganized.blocks.first(where: { $0.title == "Leitura Matinal" }) else {
                throw TestError("Bloco concluído desapareceu!")
            }
            guard preservedCompleted.status == .completed else {
                throw TestError("Status do bloco concluído foi alterado")
            }
            guard preservedCompleted.startTime == makeTime(hour: 8, minute: 0) &&
                  preservedCompleted.endTime == makeTime(hour: 8, minute: 30) else {
                throw TestError("Horário do bloco concluído foi indevidamente alterado")
            }
        }
        
        // MARK: - TEST 4: Reorganização do Restante do Dia (Adaptação ao Readiness)
        await test("4. Reorganização do Restante do Dia com Proteção de Energia Baixa") {
            let blockToShift = PlannedBlock(
                title: "Trabalho Pesado",
                category: .work,
                startTime: makeTime(hour: 9, minute: 0),
                endTime: makeTime(hour: 12, minute: 0) // 180 min
            )
            let plan = DailyPlan(
                date: today,
                summary: "Rotina",
                blocks: [blockToShift]
            )
            
            // Se o usuário está cansado (readiness = 3.8 < 5.0), a Venus reorganiza a partir das 14h
            // diminuindo duração máxima para 45min e garantindo descanso
            let now = makeTime(hour: 14, minute: 0)
            let reorganized = engine.reorganizeRemainderOfDay(
                currentPlan: plan,
                startingFrom: now,
                newBlocks: nil,
                readinessScore: 3.8
            )
            
            guard let rescheduled = reorganized.blocks.first(where: { $0.title == "Trabalho Pesado" }) else {
                throw TestError("Bloco não encontrado na reorganização")
            }
            guard rescheduled.startTime >= now else {
                throw TestError("Novo início deve ser >= horário atual")
            }
            guard rescheduled.durationMinutes <= 45 else {
                throw TestError("Duração deveria ser reduzida para <= 45 min sob baixa energia, obtido \(rescheduled.durationMinutes) min")
            }
        }
        
        // MARK: - TEST 5: Persistência do Plano com SwiftData
        await test("5. Persistência do Plano Diário (SwiftData ModelContainer)") {
            let schema = Schema([
                DailyPlanModel.self,
                PlannedBlockModel.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [config])
            let repository = DailyPlanRepositoryImpl(modelContainer: container)
            
            let planId = UUID()
            let block1Id = UUID()
            let block2Id = UUID()
            
            let block1 = PlannedBlock(
                id: block1Id,
                title: "Estudar Álgebra",
                category: .study,
                startTime: makeTime(hour: 14, minute: 0),
                endTime: makeTime(hour: 15, minute: 0),
                priority: .high,
                status: .planned
            )
            let block2 = PlannedBlock(
                id: block2Id,
                title: "Caminhada",
                category: .health,
                startTime: makeTime(hour: 17, minute: 0),
                endTime: makeTime(hour: 17, minute: 45),
                priority: .medium,
                status: .planned
            )
            
            let plan = DailyPlan(
                id: planId,
                date: today,
                state: .active,
                summary: "Foco suave na tarde",
                blocks: [block1, block2]
            )
            
            // 1. Salvar
            try await repository.save(plan: plan)
            
            // 2. Buscar
            guard let fetched = try await repository.getPlan(for: today) else {
                throw TestError("Plano salvo não foi recuperado")
            }
            guard fetched.id == planId else {
                throw TestError("ID recuperado diferente do salvo")
            }
            guard fetched.blocks.count == 2 else {
                throw TestError("Esperado 2 blocos, obtido \(fetched.blocks.count)")
            }
            guard fetched.summary == "Foco suave na tarde" else {
                throw TestError("Resumo incorreto")
            }
            
            // 3. Atualizar status de bloco
            try await repository.updateBlockStatus(planId: planId, blockId: block1Id, status: .completed)
            guard let updatedPlan = try await repository.getPlan(for: today) else {
                throw TestError("Plano atualizado não encontrado")
            }
            guard let updatedBlock1 = updatedPlan.blocks.first(where: { $0.id == block1Id }) else {
                throw TestError("Bloco 1 não encontrado após update")
            }
            guard updatedBlock1.status == .completed else {
                throw TestError("Status do bloco deveria ser .completed, obtido \(updatedBlock1.status)")
            }
            
            // 4. Deletar plano
            try await repository.deletePlan(id: planId)
            let afterDelete = try await repository.getPlan(for: today)
            guard afterDelete == nil else {
                throw TestError("Plano ainda existe após deleção")
            }
        }
        
        print("\n🔮 =========================================")
        print("🔮 RESULTADO DOS TESTES: \(passedCount)/\(totalCount) PASSARAM (100% SUCESSO)")
        print("🔮 =========================================")
        
        if passedCount != totalCount {
            exit(1)
        }
    }
}

struct TestError: Error, CustomStringConvertible {
    let description: String
    init(_ description: String) {
        self.description = description
    }
}
