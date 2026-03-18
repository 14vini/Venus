//
//  VenusProgressBar.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusProgressBar: View {
    let currentStep: Int
    let totalSteps: Int
    
    private var progress: Double {
        Double(currentStep) / Double(totalSteps)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Progress Track
            HStack {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.3))
                            .frame(height: 12)
                        
                        Capsule()
                            .fill(VenusTheme.darkGreen)
                            .frame(width: max(0, geometry.size.width * CGFloat(progress)))
                            .frame(height: 12)
                            .shadow(color: .black.opacity(0.2), radius: 1.5, x: 2)
                    }
                }
                .frame(height: 12)
            }
            .frame(maxWidth: .infinity)
            
            // Progress Text
            HStack {
                Text("Passo \(currentStep) de \(totalSteps)")
                    .font(.caption2)
                    .foregroundColor(VenusTheme.textSecondary)
                Spacer()
                Text("\(Int(progress * 100))%")
                    .font(.caption2)
                    .fontWeight(.semibold)
                    .foregroundColor(VenusTheme.darkGreen)
                    .frame(width: 35, alignment: .trailing)
            }
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        VenusProgressBar(currentStep: 1, totalSteps: 7)
        VenusProgressBar(currentStep: 4, totalSteps: 7)
        VenusProgressBar(currentStep: 7, totalSteps: 7)
    }
    .padding()
    .background(VenusTheme.backgroundGradient)
}
