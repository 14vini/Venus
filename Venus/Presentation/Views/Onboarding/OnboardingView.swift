//
//  OnboardingView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(UserProfile.self) private var userProfile
    
    var body: some View {
        OnboardingContainer(userProfile: userProfile)
    }
}

#Preview {
    OnboardingView()
        .environment(UserProfile())
}
