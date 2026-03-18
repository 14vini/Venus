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
            
            ActivitiesListView(viewModel: DependencyContainer.shared.makeActivitiesListViewModel())
                .tabItem {
                    Label("Explorar", systemImage: "sparkles.rectangle.stack")
                }
            
            // Profile Placeholder (Future)
//            Text("Perfil (Em construção)")
//                .tabItem {
//                    Label("Perfil", systemImage: "person")
//                }
        }
        .tint(Color(hex: "FF3D00"))
        .preferredColorScheme(nil) // Permite que o sistema controle o modo escuro
    }
}

#Preview {
    MainTabView(userName: "Kauã")
}
