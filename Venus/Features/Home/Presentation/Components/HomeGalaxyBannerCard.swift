//
//  HomeGalaxyBannerCard.swift
//  Venus
//
//  Created by Kaua on 24/09/26.
//

import SwiftUI

struct HomeGalaxyBannerCard: View {
    let checkInCount: Int
    let onOpenGalaxy: () -> Void
    let onOpenWrap: () -> Void
    
    @State private var isPulsing: Bool = false
    
    var body: some View {
        HStack {
            HStack(spacing: 8) {
                Image(systemName: "sparkles.rectangle.stack.fill")
                    .foregroundColor(VenusTheme.text)
                    .font(.system(size: 16, weight: .semibold))

                VStack(alignment: .leading, spacing: 2) {
                    Text("Venus Wrap")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                    Text("Sua retrospectiva emocional")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(VenusTheme.textSecondary)
                }
            }
            
            Spacer()
            
            Button {
                onOpenWrap()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "play.fill")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(VenusTheme.text)
                .frame(width: 32, height: 32)
                .neumorphicCircle(style: .raised, depth: 4)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .neumorphicCard(cornerRadius: 22, style: .raised, depth: 6)
    }
}
