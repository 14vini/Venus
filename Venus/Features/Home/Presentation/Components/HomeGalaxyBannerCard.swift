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
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                HStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [VenusTheme.accentPurple, VenusTheme.primary],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 36, height: 36)
                            .scaleEffect(isPulsing ? 1.08 : 1.0)
                        
                        Image(systemName: "sparkles")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("GALÁXIA DE MEMÓRIAS")
                            .font(.system(size: 11, weight: .black, design: .rounded))
                            .foregroundColor(VenusTheme.primary)
                            .tracking(1.2)
                        
                        Text("Sua Constelação & Venus Wrap")
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
                            .font(.system(size: 12))
                        Text("Ver Story")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(VenusTheme.primary, in: Capsule())
                }
            }
            
            Text("Veja seus check-ins transformados em estrelas cintilantes e assista ao resumo da sua evolução com a escrita da Venus.")
                .font(.system(size: 13, design: .rounded))
                .foregroundColor(.white.opacity(0.8))
                .lineSpacing(3)
            
            Button {
                onOpenGalaxy()
            } label: {
                HStack {
                    Text("Explorar Constelação")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(VenusTheme.accentBlue)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hex: "17142B"),
                            Color(hex: "0D0A1C")
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
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
