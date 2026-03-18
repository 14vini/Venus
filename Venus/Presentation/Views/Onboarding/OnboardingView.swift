//
//  OnboardingView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(UserProfile.self) private var userProfile
    let startAtWelcome: Bool
    
    init(startAtWelcome: Bool = false) {
        self.startAtWelcome = startAtWelcome
    }
    
    var body: some View {
        OnboardingContainer(
            userProfile: userProfile,
            initialStep: startAtWelcome ? 1 : 0
        )
    }
}

#Preview {
    OnboardingView()
        .environment(UserProfile())
}
