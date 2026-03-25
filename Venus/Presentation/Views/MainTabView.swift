//
//  MainTabView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct MainTabView: View {
    let userName: String
    
    var body: some View {
        TabView {
            NavigationStack {
                HomeView(userName: userName)
            }
            .tabItem {
                Label("Hoje", systemImage: "sparkles")
            }
            
            DailyPracticesView(viewModel: DependencyContainer.shared.makeActivitiesListViewModel())
                .tabItem {
                    Label("Práticas", systemImage: "leaf.fill")
                }
            
            TodoListView(viewModel: DependencyContainer.shared.makeTodoListViewModel())
                .tabItem {
                    Label("Agenda", systemImage: "calendar")
                }
//            
//            ActivitiesListView(viewModel: DependencyContainer.shared.makeActivitiesListViewModel())
//                .tabItem {
//                    Label("Explorar", systemImage: "sparkles.rectangle.stack")
//                }
            
            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Ajustes", systemImage: "gearshape.fill")
            }


            // Profile Placeholder (Future)
//            Text("Perfil (Em construção)")
//                .tabItem {
//                    Label("Perfil", systemImage: "person")
//                }
        }
        .tint(VenusTheme.primary)
        .preferredColorScheme(nil) // Permite que o sistema controle o modo escuro
    }
}

private struct MainTabViewPreviewHost: View {
    var body: some View {
        TabView {
            NavigationStack {
                previewPlaceholder(title: "Hoje", subtitle: "Preview leve da tab principal")
            }
            .tabItem {
                Label("Hoje", systemImage: "sparkles")
            }

            previewPlaceholder(title: "Práticas", subtitle: "Preview leve")
                .tabItem {
                    Label("Práticas", systemImage: "leaf.fill")
                }

            TodoListView(viewModel: TodoListPreviewFactory.makeViewModel())
                .tabItem {
                    Label("Agenda", systemImage: "calendar")
                }

            previewPlaceholder(title: "Explorar", subtitle: "Preview leve")
                .tabItem {
                    Label("Explorar", systemImage: "sparkles.rectangle.stack")
                }

            NavigationStack {
                SettingsView()
            }
            .tabItem {
                Label("Ajustes", systemImage: "gearshape.fill")
            }
        }
        .tint(VenusTheme.primary)
    }

    private func previewPlaceholder(title: String, subtitle: String) -> some View {
        ZStack {
            VenusReadingBackground()

            VStack(spacing: 10) {
                Text(title)
                    .font(.system(size: 34, weight: .black, design: .rounded))
                    .foregroundColor(VenusTheme.text)

                Text(subtitle)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundColor(VenusTheme.textSecondary)
            }
        }
    }
}

#Preview {
    MainTabViewPreviewHost()
        .environment(UserProfile())
}
