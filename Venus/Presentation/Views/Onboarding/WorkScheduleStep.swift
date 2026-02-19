//
//  VenusWorkScheduleStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusWorkScheduleStep: View {
    @Binding var userProfile: UserProfile
    @State private var hasWork: Bool = false
    @State private var workStart: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var workEnd: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var hasStudy: Bool = false
    @State private var studyStart: Date = Calendar.current.date(bySettingHour: 14, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var studyEnd: Date = Calendar.current.date(bySettingHour: 16, minute: 0, second: 0, of: Date()) ?? Date()
    
    var body: some View {
        VStack(spacing: 24) {
            HStack{
                VStack(alignment: .leading, spacing: 8) {
                    Text("Sua Rotina")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(VenusTheme.text)
                    
                    Text("Horários de trabalho e estudo")
                        .font(.subheadline)
                        .foregroundColor(VenusTheme.textSecondary)
                }
                .frame(alignment: .leading)
                .padding(.horizontal)
                
                Spacer()
            }
            VenusCard {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "briefcase.fill")
                            .foregroundColor(VenusTheme.darkGreen)
                        Text("Você trabalha?")
                            .font(.headline)
                            .foregroundColor(VenusTheme.text)
                        Spacer()
                        Toggle("", isOn: $hasWork)
                            .tint(VenusTheme.darkGreen)
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
                    }
                }
            }
            .padding(.horizontal, 24)
            
            VenusCard {
                VStack(spacing: 16) {
                    HStack {
                        Image(systemName: "book.fill")
                            .foregroundColor(VenusTheme.darkGreen)
                        Text("Você estuda?")
                            .font(.headline)
                            .foregroundColor(VenusTheme.text)
                        Spacer()
                        Toggle("", isOn: $hasStudy)
                            .tint(VenusTheme.darkGreen)
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
                    }
                }
            }
            .padding(.horizontal, 24)
            
        }
        .padding(.top, 24)
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
            }
            hasStudy = userProfile.studySchedule.studies
            studyStart = userProfile.studySchedule.startTime
            studyEnd = userProfile.studySchedule.endTime
        }
    }
    
    private func updateProfile() {
        if hasWork || hasStudy {
            userProfile.workSchedule = WorkSchedule(
                hasWork: hasWork,
                startTime: workStart,
                endTime: workEnd
            )
        }
        userProfile.studySchedule.studies = hasStudy
        userProfile.studySchedule.startTime = studyStart
        userProfile.studySchedule.endTime = studyEnd
    }
}

#Preview {
    VenusWorkScheduleStep(userProfile: .constant(UserProfile()))
        .background(VenusTheme.backgroundGradient)
}
