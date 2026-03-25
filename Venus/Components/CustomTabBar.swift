//
//  CustomTabBar.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

enum Tab: String, CaseIterable {
    case home = "Hoje"
    case activities = "Atividades"
    case todo = "Agenda"
    
    var icon: String {
        switch self {
        case .home: return "sparkles"
        case .activities: return "figure.mind.and.body"
        case .todo: return "calendar"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    @Namespace private var animation // For distinct selection animation
    
    // Aesthetic Colors
    private let activeColor = Color.white
    private let inactiveColor = Color.white.opacity(0.6)
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    // Haptic Feedback
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold)) // Slightly bolder
                            .symbolEffect(.bounce, value: selectedTab == tab) // Icon Bounce on iOS 17+
                        
                        // Text label optional, maybe better without for "Miracle" look?
                        // Let's keep it minimal, icon only or very small text.
                        // For a premium feel, let's try Icon only with a glow indicator.
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundColor(selectedTab == tab ? activeColor : inactiveColor)
                    .overlay(
                        // Active Indicator
                        ZStack {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "FF5F15").opacity(0.3), Color(hex: "FF3D00").opacity(0.3)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .matchedGeometryEffect(id: "ActiveTab", in: animation)
                                    .frame(width: 72, height: 44)
                            }
                        }
                    )
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.clear.interactive())
        .padding(.horizontal, 24)
        .padding(.bottom, 12)
    }
}

#Preview {
    ZStack {
        VenusTheme.backgroundGradient.ignoresSafeArea()
        VStack {
            Spacer()
            CustomTabBar(selectedTab: .constant(.home))
        }
    }
}
