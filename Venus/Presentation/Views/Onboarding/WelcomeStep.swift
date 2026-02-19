//
//  WelcomeStep.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct WelcomeStep: View {
    @Binding var userProfile: UserProfile
    @State private var inputName: String = ""
    
    var body: some View {
        VStack(spacing: 32) {
            VStack(spacing: 20) {
                VStack(spacing: 12) {
                    Text("Venus")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(VenusTheme.text)
                    
                    Text("Não é terapia, mas é terapêutico.")
                        .font(.title3.bold())
                        .foregroundColor(VenusTheme.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .fontDesign(.rounded)
            }
            
            VenusCard {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Qual é o seu nome?")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(VenusTheme.text)
                    
                    TextField("Digite seu nome", text: $inputName)
                        .padding(16)
                        .background(VenusTheme.chipBackground)
                        .cornerRadius(12)
                        .foregroundColor(VenusTheme.text)
                        .onChange(of: inputName) { oldValue, newValue in
                            userProfile.name = newValue
                        }
                    
                    Text("Seu nome nos ajuda a personalizar sua experiência")
                        .font(.caption)
                        .foregroundColor(VenusTheme.textSecondary)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.top, 32)
        .padding(.bottom, 20)
        
        .onAppear {
            inputName = userProfile.name
        }
    }
}



#Preview {
    ZStack {
        VenusTheme.backgroundGradient
            .ignoresSafeArea()
        
        WelcomeStep(userProfile: .constant(UserProfile()))
    }
}
