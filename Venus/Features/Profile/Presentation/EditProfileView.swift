//
//  EditProfileView.swift
//  Venus
//
//  Created by Kaua on 18/06/26.
//

import SwiftUI

struct EditProfileView: View {
    @Binding var showSheet: Bool
    let onSave: () -> Void
    
    @Environment(UserProfile.self) private var userProfile
    
    @State private var name: String = ""
    @State private var primaryGoal: String = ""
    @State private var coachingTone: String = "Acolhedor"
    @State private var dailyTimeBudgetMinutes: Int = 15
    
    @State private var hasWork: Bool = false
    @State private var workStartTime: Date = Date()
    @State private var workEndTime: Date = Date()
    
    @State private var studies: Bool = false
    @State private var studyStartTime: Date = Date()
    @State private var studyEndTime: Date = Date()
    
    @State private var selectedInterests: Set<String> = []
    @State private var selectedCurrentHobbies: Set<String> = []
    @State private var selectedDesiredHobbies: Set<String> = []
    @State private var selectedImprovementAreas: Set<String> = []
    @State private var selectedEmotionalAreas: Set<String> = []
    
    let allInterests = [
        "Tecnologia", "Natureza", "Artes", "Esportes", "Culinária", "Música", 
        "Leitura", "Viagens", "Fotografia", "Filmes", "Meditação", "Educação", 
        "Dança", "Jogos", "Moda", "Bem-estar", "Arquitetura", "História", 
        "Ciência", "Filosofia", "Desenho", "Escrita", "Espiritualidade", "Humor"
    ]
    
    let allHobbies = [
        "Leitura", "Exercícios", "Culinária", "Jardinagem", "Música", "Desenho", 
        "Fotografia", "Caminhada", "Ioga", "Meditação", "Escrita", "Dança", 
        "Natação", "Ciclismo", "Pintura", "Artesanato", "Jogos", "Cinema"
    ]
    
    let allImprovementAreas = ["foco e produtividade", "equilibrio de vida", "saude fisica", "sono", "relacionamentos", "comunicacao", "energia", "motivacao"]
    let allEmotionalAreas = ["estresse", "ansiedade", "sobrecarga", "tristeza", "desanimo", "apatia", "solidao", "inseguranca"]
    
    var body: some View {
        Form {
            Section(header: Text("Informações Básicas")) {
                TextField("Nome", text: $name)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                
                TextField("Meta Principal", text: $primaryGoal)
                    .font(.system(.subheadline, design: .rounded).weight(.medium))
                
                Picker("Tom da Venus", selection: $coachingTone) {
                    Text("Acolhedor").tag("Acolhedor")
                    Text("Direto").tag("Direto")
                    Text("Motivador").tag("Motivador")
                    Text("Normal").tag("Normal")
                }
                .font(.system(.subheadline, design: .rounded))
                
                Stepper(value: $dailyTimeBudgetMinutes, in: 5...120, step: 5) {
                    Text("Tempo diário: \(dailyTimeBudgetMinutes) minutos")
                        .font(.system(.subheadline, design: .rounded).weight(.medium))
                }
            }
            
            Section(header: Text("Rotina de Trabalho")) {
                Toggle("Tenho expediente de trabalho", isOn: $hasWork)
                
                if hasWork {
                    DatePicker("Início", selection: $workStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("Término", selection: $workEndTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("Rotina de Estudos")) {
                Toggle("Estudo ativamente", isOn: $studies)
                
                if studies {
                    DatePicker("Início", selection: $studyStartTime, displayedComponents: .hourAndMinute)
                    DatePicker("Término", selection: $studyEndTime, displayedComponents: .hourAndMinute)
                }
            }
            
            Section(header: Text("Áreas de Foco")) {
                DisclosureGroup("Melhorias desejadas") {
                    checkboxList(options: allImprovementAreas, selected: $selectedImprovementAreas)
                }
                DisclosureGroup("Prioridades emocionais") {
                    checkboxList(options: allEmotionalAreas, selected: $selectedEmotionalAreas)
                }
            }
            
            Section(header: Text("Interesses e Hobbies")) {
                DisclosureGroup("Interesses") {
                    checkboxList(options: allInterests, selected: $selectedInterests)
                }
                
                DisclosureGroup("Hobbies Atuais") {
                    checkboxList(options: allHobbies, selected: $selectedCurrentHobbies)
                }
                
                DisclosureGroup("Hobbies Desejados") {
                    checkboxList(options: allHobbies.filter { !selectedCurrentHobbies.contains($0) }, selected: $selectedDesiredHobbies)
                }
            }
        }
        .navigationTitle("Editar Perfil")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancelar") {
                    showSheet = false
                }
            }
            
            ToolbarItem(placement: .confirmationAction) {
                Button("Salvar") {
                    saveChanges()
                    onSave()
                    showSheet = false
                }
                .fontWeight(.bold)
            }
        }
        .onAppear(perform: loadCurrentProfileValues)
    }
    
    private func loadCurrentProfileValues() {
        name = userProfile.name
        primaryGoal = userProfile.primaryGoal
        coachingTone = userProfile.coachingTone.isEmpty ? "Normal" : userProfile.coachingTone
        dailyTimeBudgetMinutes = userProfile.dailyTimeBudgetMinutes == 0 ? 15 : userProfile.dailyTimeBudgetMinutes
        
        hasWork = userProfile.workSchedule?.hasWork ?? false
        workStartTime = userProfile.workSchedule?.startTime ?? defaultTime(hour: 9)
        workEndTime = userProfile.workSchedule?.endTime ?? defaultTime(hour: 18)
        
        studies = userProfile.studySchedule.studies
        studyStartTime = userProfile.studySchedule.startTime
        studyEndTime = userProfile.studySchedule.endTime
        
        selectedInterests = Set(userProfile.interests)
        selectedCurrentHobbies = Set(userProfile.currentHobbies)
        selectedDesiredHobbies = Set(userProfile.desiredHobbies)
        selectedImprovementAreas = Set(userProfile.improvementAreas)
        selectedEmotionalAreas = Set(userProfile.emotionalAreas)
    }
    
    private func saveChanges() {
        userProfile.name = name
        userProfile.primaryGoal = primaryGoal
        userProfile.coachingTone = coachingTone
        userProfile.dailyTimeBudgetMinutes = dailyTimeBudgetMinutes
        
        if hasWork {
            userProfile.workSchedule = WorkSchedule(hasWork: true, startTime: workStartTime, endTime: workEndTime)
        } else {
            userProfile.workSchedule = nil
        }
        
        userProfile.studySchedule = StudySchedule(studies: studies, startTime: studyStartTime, endTime: studyEndTime)
        
        userProfile.interests = Array(selectedInterests).sorted()
        userProfile.currentHobbies = Array(selectedCurrentHobbies).sorted()
        userProfile.desiredHobbies = Array(selectedDesiredHobbies).sorted()
        userProfile.improvementAreas = Array(selectedImprovementAreas).sorted()
        userProfile.emotionalAreas = Array(selectedEmotionalAreas).sorted()
    }
    
    private func defaultTime(hour: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: 0, second: 0, of: Date()) ?? Date()
    }
    
    @ViewBuilder
    private func checkboxList(options: [String], selected: Binding<Set<String>>) -> some View {
        ForEach(options, id: \.self) { option in
            Button {
                if selected.wrappedValue.contains(option) {
                    selected.wrappedValue.remove(option)
                } else {
                    selected.wrappedValue.insert(option)
                }
            } label: {
                HStack {
                    Text(option)
                        .foregroundColor(VenusTheme.text)
                    Spacer()
                    if selected.wrappedValue.contains(option) {
                        Image(systemName: "checkmark")
                            .foregroundColor(VenusTheme.primary)
                            .fontWeight(.bold)
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}
