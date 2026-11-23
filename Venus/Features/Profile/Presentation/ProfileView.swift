//
//  ProfileView.swift
//  Venus
//
//  Created by Kaua on 18/06/26.
//
//  F15 — seções em vidro real, tipografia fina e haptic na navegação.
//  F36 — cabeçalho com arco de progresso do perfil e CTA escuro em pill.
//

import SwiftUI

struct ProfileView: View {
    @Environment(UserProfile.self) private var userProfile
    @State private var showEditSheet = false
    @State private var didAppear: Bool = false
    @State private var aboutYouText: String = "Cada check-in desenha um pouco mais do seu reflexo emocional. Continue registrando seus momentos com a Venus."

    private let profileRepository = DependencyContainer.shared.makeUserProfileRepository()
    private let patternEngineUseCase = DependencyContainer.shared.makePatternEngineUseCase()

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    /// Dimensões preenchidas do perfil: identidade, meta, rotina, foco e interesses.
    private var profileDimensionCount: Int {
        var filled = 0
        if !userProfile.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { filled += 1 }
        if !userProfile.primaryGoal.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { filled += 1 }
        if userProfile.workSchedule?.hasWork == true || userProfile.studySchedule.studies { filled += 1 }
        if !userProfile.improvementAreas.isEmpty || !userProfile.emotionalAreas.isEmpty || !userProfile.coreValues.isEmpty { filled += 1 }
        if !userProfile.interests.isEmpty || !userProfile.currentHobbies.isEmpty || !userProfile.desiredHobbies.isEmpty { filled += 1 }
        return filled
    }

    var body: some View {
        ZStack {
            VenusSoftGradientBackground()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    journeyHeader

                    headerSection

                    aboutYouSection

                    routineSection

                    preferencesSection

                    hobbiesAndInterestsSection

                    editCTAButton
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)
                .padding(.bottom, 100)
                .opacity(didAppear ? 1 : 0)
                .offset(y: didAppear ? 0 : 14)
                .animation(.spring(response: 0.55, dampingFraction: 0.85), value: didAppear)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.85)) {
                didAppear = true
            }
        }
        .navigationTitle("Meu Perfil")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    showEditSheet = true
                } label: {
                    Label("Editar", systemImage: "pencil")
                        .font(.system(size: 14, design: .rounded).weight(.semibold))
                        .foregroundStyle(VenusTheme.primary)
                }
                .buttonStyle(.glass)
            }
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                EditProfileView(showSheet: $showEditSheet, onSave: saveProfileChanges)
            }
        }
        .task {
            await loadAboutYou()
        }
    }

    // MARK: - Cabeçalho

    private var journeyHeader: some View {
        VenusF36JourneyHeader(
            eyebrow: "Seu reflexo",
            title: "Perfil",
            subtitle: "Um retrato que cresce com cada check-in.",
            dotCount: 5,
            currentDot: profileDimensionCount,
            dotCaption: "\(profileDimensionCount) de 5 dimensões",
            tint: VenusF36Palette.lilac
        )
    }

    private var editCTAButton: some View {
        Button {
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            showEditSheet = true
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .semibold))
                Text("Editar meu perfil")
            }
        }
        .buttonStyle(VenusF36DarkPillStyle())
        .padding(.top, 4)
    }

    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(VenusTheme.primaryGradient)
                    .frame(width: 72, height: 72)

                Text(userProfile.name.isEmpty ? "?" : String(userProfile.name.prefix(2)).uppercased())
                    .font(.system(size: 26, design: .rounded).weight(.semibold))
                    .foregroundStyle(Color.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(userProfile.name.isEmpty ? "Seu Nome" : userProfile.name)
                    .font(.system(size: 25, design: .rounded).weight(.bold))
                    .foregroundStyle(VenusTheme.text)

                if !userProfile.primaryGoal.isEmpty {
                    Text(userProfile.primaryGoal)
                        .font(.system(size: 14, design: .rounded).weight(.regular))
                        .foregroundStyle(VenusTheme.textSecondary)
                }
            }

            Spacer()
        }
        .profileSectionStyle()
    }

    // MARK: - Sobre você

    private var aboutYouSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader("Sobre você", systemImage: "sparkles")

            Text(aboutYouText)
                .font(.system(size: 15, design: .rounded).weight(.regular))
                .foregroundStyle(VenusTheme.text)
                .lineSpacing(5)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .profileSectionStyle()
    }

    // MARK: - Rotina

    private var routineSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Minha rotina", systemImage: "clock")

            routineRow(
                icon: "briefcase.fill",
                tint: VenusTheme.accentBlue,
                title: "Jornada de Trabalho",
                detail: workDetail,
                badge: workBadge
            )

            Divider()
                .overlay(VenusTheme.textSecondary.opacity(0.18))

            routineRow(
                icon: "book.closed.fill",
                tint: VenusTheme.accentPurple,
                title: "Período de Estudos",
                detail: studyDetail,
                badge: studyBadge
            )
        }
        .profileSectionStyle()
    }

    private var workDetail: String {
        guard let work = userProfile.workSchedule, work.hasWork else {
            return "Não configurada"
        }
        return "\(dateFormatter.string(from: work.startTime)) até \(dateFormatter.string(from: work.endTime))"
    }

    private var workBadge: String? {
        guard let work = userProfile.workSchedule, work.hasWork else { return nil }
        return "Ativa"
    }

    private var studyDetail: String {
        guard userProfile.studySchedule.studies else { return "Não configurado" }
        return "\(dateFormatter.string(from: userProfile.studySchedule.startTime)) até \(dateFormatter.string(from: userProfile.studySchedule.endTime))"
    }

    private var studyBadge: String? {
        userProfile.studySchedule.studies ? "Ativo" : nil
    }

    // MARK: - Preferências

    private var preferencesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Calibração & bem-estar", systemImage: "sparkles")

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
                tagGroup(
                    title: "ÁREAS DE MELHORIA",
                    items: userProfile.improvementAreas,
                    tint: VenusTheme.accentPink
                )
            }

            if !userProfile.emotionalAreas.isEmpty {
                tagGroup(
                    title: "PRIORIDADES EMOCIONAIS",
                    items: userProfile.emotionalAreas,
                    tint: VenusTheme.accentOrange
                )
            }
        }
        .profileSectionStyle()
    }

    // MARK: - Lazer & Interesses

    private var hobbiesAndInterestsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionHeader("Lazer & Interesses", systemImage: "heart.fill")

            if !userProfile.interests.isEmpty {
                tagGroup(title: "INTERESSES", items: userProfile.interests, tint: VenusTheme.accentBlue)
            }

            if !userProfile.currentHobbies.isEmpty {
                tagGroup(title: "HOBBIES ATIVOS", items: userProfile.currentHobbies, tint: VenusTheme.accentGreen)
            }

            if !userProfile.desiredHobbies.isEmpty {
                tagGroup(title: "HOBBIES QUE DESEJO", items: userProfile.desiredHobbies, tint: VenusTheme.primary)
            }
        }
        .profileSectionStyle()
    }

    // MARK: - Componentes

    private func sectionHeader(_ title: String, systemImage: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(VenusF36Palette.lilac)

            Text(title)
                .font(.system(size: 20, design: .rounded).weight(.light))
                .foregroundStyle(VenusTheme.text)
        }
    }

    private func routineRow(
        icon: String,
        tint: Color,
        title: String,
        detail: String,
        badge: String?
    ) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 14, design: .rounded).weight(.semibold))
                    .foregroundStyle(VenusTheme.text)

                Text(detail)
                    .font(.system(size: 12, design: .rounded).weight(.regular))
                    .foregroundStyle(VenusTheme.textSecondary)
            }

            Spacer(minLength: 6)

            if let badge {
                Text(badge)
                    .font(.system(size: 11, design: .rounded).weight(.semibold))
                    .foregroundStyle(VenusTheme.accentGreen)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(.regular, in: Capsule(style: .continuous))
            }
        }
    }

    private func tagGroup(title: String, items: [String], tint: Color) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 10, design: .rounded).weight(.semibold))
                .kerning(1.2)
                .foregroundStyle(VenusTheme.textSecondary)

            ProfileFlowLayout(items: items, tint: tint)
        }
    }

    private func metricSmallCard(title: String, value: String, icon: String, tint: Color) -> some View {
        HStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(tint.opacity(0.14))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(tint)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 11, design: .rounded).weight(.regular))
                    .foregroundStyle(VenusTheme.textSecondary)

                Text(value)
                    .font(.system(size: 14, design: .rounded).weight(.semibold))
                    .foregroundStyle(VenusTheme.text)
                    .lineLimit(1)
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    // MARK: - Persistência

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

    private func loadAboutYou() async {
        do {
            if let snapshot = try await patternEngineUseCase.execute(),
               !snapshot.weeklyTrend.summary.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                aboutYouText = snapshot.weeklyTrend.summary
            } else if !userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                aboutYouText = userProfile.contextNote
            }
        } catch {
            if !userProfile.contextNote.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                aboutYouText = userProfile.contextNote
            }
        }
    }
}

// MARK: - Estilo de seção em vidro

private struct ProfileSectionStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 28, style: .continuous))
    }
}

private extension View {
    func profileSectionStyle() -> some View {
        modifier(ProfileSectionStyle())
    }
}

// MARK: - Tags em fluxo

private struct ProfileFlowLayout: View {
    let items: [String]
    let tint: Color

    private let columns = [GridItem(.adaptive(minimum: 110), spacing: 8)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(items, id: \.self) { item in
                Text(item)
                    .font(.system(size: 12, design: .rounded).weight(.medium))
                    .foregroundStyle(tint)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .frame(maxWidth: .infinity)
                    .glassEffect(.regular, in: Capsule(style: .continuous))
            }
        }
    }
}
