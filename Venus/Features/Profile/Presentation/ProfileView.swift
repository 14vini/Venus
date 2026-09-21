//
//  ProfileView.swift
//  Venus
//
//  Created by Kaua on 18/06/26.
//

import SwiftUI

struct ProfileView: View {
    @Environment(UserProfile.self) private var userProfile
    @State private var showEditSheet = false
    @Environment(\.colorScheme) private var colorScheme
    
    private let profileRepository = DependencyContainer.shared.makeUserProfileRepository()
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()
    
    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: VenusTheme.primary,
                secondaryAccent: VenusTheme.accentBlue,
                tertiaryAccent: VenusTheme.accentPink,
                isAnimated: true
            )
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Card
                    headerSection
                        .padding(.top, 16)
                    
                    // Routine Card
                    routineSection
                    
                    // Focus and Preferences Card
                    preferencesSection
                    
                    // Hobbies & Interests Card
                    hobbiesAndInterestsSection
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 60)
            }
        }
        .navigationTitle("Meu Perfil")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showEditSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                        Text("Editar")
                    }
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.primary)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                EditProfileView(showSheet: $showEditSheet, onSave: saveProfileChanges)
            }
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(VenusTheme.primaryGradient)
                        .frame(width: 72, height: 72)
                        .shadow(color: VenusTheme.primary.opacity(0.3), radius: 10, x: 0, y: 5)
                    
                    Text(userProfile.name.isEmpty ? "?" : String(userProfile.name.prefix(2)).uppercased())
                        .font(.system(size: 26, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    Text(userProfile.name.isEmpty ? "Seu Nome" : userProfile.name)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    
                    if !userProfile.primaryGoal.isEmpty {
                        Text(userProfile.primaryGoal)
                            .font(.system(.subheadline, design: .rounded).weight(.semibold))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 28)
    }
    
    private var routineSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Minha Rotina", systemImage: "clock.fill")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
            
            // Work Card
            HStack {
                ZStack {
                    Circle()
                        .fill(VenusTheme.accentBlue.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "briefcase.fill")
                        .foregroundColor(VenusTheme.accentBlue)
                        .font(.system(size: 14, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Jornada de Trabalho")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                    
                    if let work = userProfile.workSchedule, work.hasWork {
                        Text("\(dateFormatter.string(from: work.startTime)) até \(dateFormatter.string(from: work.endTime))")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    } else {
                        Text("Não configurada")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                if let work = userProfile.workSchedule, work.hasWork {
                    Text("Ativa")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.accentGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(VenusTheme.accentGreen.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(VenusTheme.cardSurfaceStrong, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(VenusTheme.cardBorder, lineWidth: 1))
            
            // Study Card
            HStack {
                ZStack {
                    Circle()
                        .fill(VenusTheme.accentPurple.opacity(0.12))
                        .frame(width: 40, height: 40)
                    Image(systemName: "book.closed.fill")
                        .foregroundColor(VenusTheme.accentPurple)
                        .font(.system(size: 14, weight: .bold))
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Período de Estudos")
                        .font(.system(.subheadline, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.text)
                    
                    if userProfile.studySchedule.studies {
                        Text("\(dateFormatter.string(from: userProfile.studySchedule.startTime)) até \(dateFormatter.string(from: userProfile.studySchedule.endTime))")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    } else {
                        Text("Não configurado")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(VenusTheme.textSecondary)
                    }
                }
                
                Spacer()
                
                if userProfile.studySchedule.studies {
                    Text("Ativo")
                        .font(.system(.caption2, design: .rounded).weight(.bold))
                        .foregroundColor(VenusTheme.accentGreen)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(VenusTheme.accentGreen.opacity(0.12))
                        .clipShape(Capsule())
                }
            }
            .padding(14)
            .background(VenusTheme.cardSurfaceStrong, in: RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(VenusTheme.cardBorder, lineWidth: 1))
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 28)
    }
    
    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Calibração & Bem-estar", systemImage: "sparkles")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
            
            HStack(spacing: 12) {
                metricSmallCard(
                    title: "Tom da Venus",
                    value: userProfile.coachingTone.isEmpty ? "Normal" : userProfile.coachingTone,
                    icon: "ellipsis.bubble.fill",
                    tint: VenusTheme.accentBlue
                )
                
                metricSmallCard(
                    title: "Meta Diária",
                    value: userProfile.dailyTimeBudgetMinutes > 0 ? "\(userProfile.dailyTimeBudgetMinutes) min" : "Não definido",
                    icon: "timer",
                    tint: VenusTheme.accentOrange
                )
            }
            
            if !userProfile.improvementAreas.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("ÁREAS DE MELHORIA")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.textSecondary)
                        .tracking(0.5)
                    
                    ProfileFlowLayout(items: userProfile.improvementAreas, tint: VenusTheme.accentPink)
                }
                .padding(.top, 4)
            }
            
            if !userProfile.emotionalAreas.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("PRIORIDADES EMOCIONAIS")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.textSecondary)
                        .tracking(0.5)
                    
                    ProfileFlowLayout(items: userProfile.emotionalAreas, tint: VenusTheme.accentOrange)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 28)
    }
    
    private var hobbiesAndInterestsSection: some View {
        VStack(alignment: .leading, spacing: 18) {
            Label("Lazer & Interesses", systemImage: "heart.fill")
                .font(.system(.headline, design: .rounded).weight(.bold))
                .foregroundColor(VenusTheme.text)
            
            if !userProfile.interests.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("INTERESSES")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.textSecondary)
                        .tracking(0.5)
                    
                    ProfileFlowLayout(items: userProfile.interests, tint: VenusTheme.accentBlue)
                }
            }
            
            if !userProfile.currentHobbies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("HOBBIES ATIVOS")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.textSecondary)
                        .tracking(0.5)
                    
                    ProfileFlowLayout(items: userProfile.currentHobbies, tint: VenusTheme.accentGreen)
                }
            }
            
            if !userProfile.desiredHobbies.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("HOBBIES QUE DESEJO")
                        .font(.system(.caption2, design: .rounded).weight(.black))
                        .foregroundColor(VenusTheme.textSecondary)
                        .tracking(0.5)
                    
                    ProfileFlowLayout(items: userProfile.desiredHobbies, tint: VenusTheme.primary)
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .solidCardStyle(cornerRadius: 28)
    }
    
    private func metricSmallCard(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.12))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .foregroundColor(tint)
                    .font(.system(size: 13, weight: .bold))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.textSecondary)
                Text(value)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundColor(VenusTheme.text)
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(VenusTheme.cardSurfaceStrong, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(VenusTheme.cardBorder, lineWidth: 1))
    }
    
    @MainActor
    private func saveProfileChanges() {
        Task {
            do {
                try await profileRepository.save(profile: userProfile)
            } catch {
                print("Error saving profile: \(error)")
            }
        }
    }
}

private struct ProfileFlowLayout: View {
    let items: [String]
    let tint: Color
    
    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(.caption2, design: .rounded).weight(.bold))
                    .foregroundColor(tint)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .frame(maxWidth: .infinity)
                    .background(tint.opacity(0.12))
                    .clipShape(Capsule())
                    .overlay(Capsule().stroke(tint.opacity(0.25), lineWidth: 1))
            }
        }
    }
}
