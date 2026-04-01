//
//  WorkScheduleStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct WorkScheduleStep: View {
    @Binding var userProfile: UserProfile
    
    @State private var hasWork: Bool = false
    @State private var workStart: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var workEnd: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var hasStudy: Bool = false
    @State private var studyStart: Date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var studyEnd: Date = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
    
    private var workFeedback: ScheduleFeedback? {
        guard hasWork else { return nil }
        
        if let errorMessage = OnboardingScheduleValidator.validationMessage(
            start: workStart,
            end: workEnd,
            context: "trabalho"
        ) {
            return ScheduleFeedback(
                message: errorMessage,
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
        }
        
        if OnboardingScheduleValidator.isOvernight(start: workStart, end: workEnd) {
            return ScheduleFeedback(
                message: "Turno noturno detectado. Tudo certo.",
                icon: "moon.stars.fill",
                color: VenusTheme.textSecondary
            )
        }
        
        return nil
    }
    
    private var studyFeedback: ScheduleFeedback? {
        guard hasStudy else { return nil }
        
        if let errorMessage = OnboardingScheduleValidator.validationMessage(
            start: studyStart,
            end: studyEnd,
            context: "estudo"
        ) {
            return ScheduleFeedback(
                message: errorMessage,
                icon: "exclamationmark.triangle.fill",
                color: .red
            )
        }
        
        if OnboardingScheduleValidator.isOvernight(start: studyStart, end: studyEnd) {
            return ScheduleFeedback(
                message: "Janela de estudo atravessa a madrugada.",
                icon: "moon.stars.fill",
                color: VenusTheme.textSecondary
            )
        }
        
        return nil
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            OnboardingStepHeader(
                eyebrow: "rotina",
                title: "Quais são seus horários?",
                subtitle: "Opcional. Só pra eu sugerir janelas melhores para agir e descansar.",
                systemImage: "calendar.badge.clock",
                tint: VenusTheme.accentOrange
            )

            VenusCard {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(VenusTheme.accentOrange)
                        Text("Você trabalha?")
                            .font(.headline)
                            .foregroundColor(VenusTheme.text)
                        Spacer()
                        Toggle("", isOn: $hasWork)
                            .tint(VenusTheme.accentOrange)
                            .accessibilityLabel("Você trabalha?")
                    }
                    
                    if hasWork {
                        Divider()
                        VStack(spacing: 12) {
                            HStack {
                                Text("Início:")
                                    .foregroundColor(VenusTheme.textSecondary)
                                Spacer()
                                DatePicker("", selection: $workStart, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            HStack {
                                Text("Fim:")
                                    .foregroundColor(VenusTheme.textSecondary)
                                Spacer()
                                DatePicker("", selection: $workEnd, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                        
                        if let feedback = workFeedback {
                            Label(feedback.message, systemImage: feedback.icon)
                                .font(.caption)
                                .foregroundColor(feedback.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
            VenusCard {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(VenusTheme.accentOrange)
                        Text("Você estuda?")
                            .font(.headline)
                            .foregroundColor(VenusTheme.text)
                        Spacer()
                        Toggle("", isOn: $hasStudy)
                            .tint(VenusTheme.accentOrange)
                            .accessibilityLabel("Você estuda?")
                    }
                    
                    if hasStudy {
                        Divider()
                        VStack(spacing: 12) {
                            HStack {
                                Text("Início:")
                                    .foregroundColor(VenusTheme.textSecondary)
                                Spacer()
                                DatePicker("", selection: $studyStart, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                            HStack {
                                Text("Fim:")
                                    .foregroundColor(VenusTheme.textSecondary)
                                Spacer()
                                DatePicker("", selection: $studyEnd, displayedComponents: .hourAndMinute)
                                    .labelsHidden()
                            }
                        }
                        
                        if let feedback = studyFeedback {
                            Label(feedback.message, systemImage: feedback.icon)
                                .font(.caption)
                                .foregroundColor(feedback.color)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            
        }
        .padding(.horizontal, 24)
        .padding(.top, 20)
        .padding(.bottom, 12)
        .onChange(of: hasWork) { _, _ in updateProfile() }
        .onChange(of: workStart) { _, _ in updateProfile() }
        .onChange(of: workEnd) { _, _ in updateProfile() }
        .onChange(of: hasStudy) { _, _ in updateProfile() }
        .onChange(of: studyStart) { _, _ in updateProfile() }
        .onChange(of: studyEnd) { _, _ in updateProfile() }
        .onAppear {
            if let schedule = userProfile.workSchedule {
                hasWork = schedule.hasWork
                workStart = schedule.startTime
                workEnd = schedule.endTime
            } else {
                hasWork = false
            }
            
            hasStudy = userProfile.studySchedule.studies
            studyStart = userProfile.studySchedule.startTime
            studyEnd = userProfile.studySchedule.endTime
            
            updateProfile()
        }
    }
    
    private func updateProfile() {
        if hasWork {
            userProfile.workSchedule = WorkSchedule(
                hasWork: true,
                startTime: workStart,
                endTime: workEnd
            )
        } else {
            userProfile.workSchedule = nil
        }
        
        userProfile.studySchedule.studies = hasStudy
        userProfile.studySchedule.startTime = studyStart
        userProfile.studySchedule.endTime = studyEnd
    }
}

private struct ScheduleFeedback {
    let message: String
    let icon: String
    let color: Color
}

#Preview {
    WorkScheduleStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
