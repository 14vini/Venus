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
    @Namespace private var animation
    @Environment(\.colorScheme) private var colorScheme
    
    private var activeColor: Color {
        VenusTheme.primary
    }
    
    private var inactiveColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.6) : VenusTheme.textSecondary.opacity(0.85)
    }
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    let impactMed = UIImpactFeedbackGenerator(style: .medium)
                    impactMed.impactOccurred()
                    
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 20, weight: .semibold))
                            .symbolEffect(.bounce, value: selectedTab == tab)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .foregroundColor(selectedTab == tab ? activeColor : inactiveColor)
                    .overlay(
                        ZStack {
                            if selectedTab == tab {
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [VenusTheme.primary.opacity(0.18), VenusTheme.primaryLight.opacity(0.12)],
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
