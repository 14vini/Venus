//
//  HomeScreen.swift
//  Venus
//
//  Created by Kaua on 26/03/26.
//

import SwiftUI

struct HomeScreen: View {
    let userName: String

    @StateObject private var viewModel = HomeViewModel(
        patternEngineUseCase: DependencyContainer.shared.makePatternEngineUseCase(),
        checkInAllowanceUseCase: DependencyContainer.shared.makeCheckInAllowanceUseCase(),
        moodRepository: DependencyContainer.shared.makeMoodRepository()
    )
    @StateObject private var inlineCheckInViewModel = DependencyContainer.shared.makeMoodCheckInViewModel()

    var body: some View {
        HomeView(
            userName: userName,
            viewModel: viewModel,
            inlineCheckInViewModel: inlineCheckInViewModel
        )
        .onAppear(perform: viewModel.onAppear)
        .onChange(of: viewModel.showMoodCheckIn) { _, isPresented in
            guard isPresented else { return }
            inlineCheckInViewModel.startNewCheckIn(prefilledMood: viewModel.checkInPrefilledMood)
        }
    }
}

#Preview {
    HomeScreen(userName: "Kauã")
}

