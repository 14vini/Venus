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
        VStack(spacing: 14) {
            HStack{
                HStack(spacing: 8) {

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Venus Wrap")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                
                Spacer()
                
                Button {
                    onOpenWrap()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "play.circle.fill")
                    }
                    .foregroundColor(.white)
                    .padding(4)
                    .background(VenusTheme.primary, in: Capsule())
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "17142B").opacity(0.9),
                            Color(hex: "0D0A1C").opacity(0.3)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    Capsule()
                        .stroke(
                            LinearGradient(
                                colors: [VenusTheme.primary.opacity(0.4), VenusTheme.accentPurple.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
                .shadow(color: VenusTheme.primary.opacity(0.15), radius: 12, x: 0, y: 4)
        )
        .onAppear {
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true)) {
                isPulsing = true
            }
        }
    }
}
