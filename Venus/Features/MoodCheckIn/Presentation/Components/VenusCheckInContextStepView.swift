//
//  VenusCheckInContextStepView.swift
//  Venus
//
//  Etapa 2 do check-in: Seleção de gatilhos e área afetada sem scroll horizontal,
//  adaptada para modo claro e escuro com grade adaptativa.
//

import SwiftUI

struct VenusCheckInContextStepView: View {
    @Bindable var viewModel: MoodCheckInViewModel
    let level: VenusCheckInMoodLevel

    @Environment(\.colorScheme) private var colorScheme

    private var titleColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "12233F")
    }

    private var subtitleColor: Color {
        colorScheme == .dark ? Color(hex: "94A3B8") : Color(hex: "3A4E70")
    }

    private var sectionHeaderColor: Color {
        colorScheme == .dark ? Color(hex: "93C5FD") : Color(hex: "4B6EA8")
    }

    private var unselectedChipGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color(hex: "19263A"), Color(hex: "152132")],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color.white.opacity(0.85), Color.white.opacity(0.65)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var unselectedTextColor: Color {
        colorScheme == .dark ? Color(hex: "E2E8F0") : Color(hex: "1A2C4A")
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                // Título em Serif editorial
                VStack(spacing: 8) {
                    Text("O que está motivando isso?")
                        .font(.system(size: 28, weight: .regular, design: .serif))
                        .foregroundColor(titleColor)
                        .multilineTextAlignment(.center)

                    Text("Selecione os principais fatores para alinharmos seu plano.")
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(subtitleColor)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 4)
                .padding(.horizontal, 20)

                // Mascote Oficial compacto e atento
                VenusPastelMascotView(
                    level: level,
                    size: 110,
                    isAnimated: true,
                    customState: .curious,
                    customExpression: .curious
                )
                .padding(.vertical, 2)

                // Seção de Gatilhos Principais
                VStack(alignment: .leading, spacing: 10) {
                    Text("GATILHOS PRINCIPAIS")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(sectionHeaderColor)
                        .tracking(1.0)
                        .padding(.horizontal, 24)

                    VenusWrappedLayout(spacing: 8, lineSpacing: 10) {
                        ForEach(viewModel.quickTags, id: \.self) { tag in
                            let isSelected = viewModel.selectedTags.contains(tag)
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.toggleTag(tag)
                            } label: {
                                Text(tag)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isSelected ? .white : unselectedTextColor)
                                    .padding(.horizontal, 15)
                                    .padding(.vertical, 9)
                                    .background(
                                        isSelected
                                            ? LinearGradient(
                                                colors: [Color(hex: "4F78DE"), Color(hex: "355BBF")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : unselectedChipGradient,
                                        in: Capsule()
                                    )
                                    .overlay(
                                        Capsule()
                                            .stroke(
                                                isSelected
                                                    ? Color.clear
                                                    : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.6)),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(
                                        color: isSelected
                                            ? Color(hex: "355BBF").opacity(0.35)
                                            : (colorScheme == .dark ? Color.black.opacity(0.25) : Color(hex: "4A6EB0").opacity(0.10)),
                                        radius: isSelected ? 5 : 3,
                                        y: 2
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                // Seção de Área Mais Impactada (Sem Scroll — Grade Adaptativa)
                VStack(alignment: .leading, spacing: 10) {
                    Text("ÁREA MAIS IMPACTADA")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(sectionHeaderColor)
                        .tracking(1.0)
                        .padding(.horizontal, 24)

                    VenusWrappedLayout(spacing: 8, lineSpacing: 10) {
                        ForEach(viewModel.affectedAreas, id: \.self) { area in
                            let isSelected = viewModel.selectedAffectedArea == area
                            Button {
                                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                viewModel.selectAffectedArea(area)
                            } label: {
                                Text(area.rawValue)
                                    .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                                    .foregroundColor(isSelected ? .white : unselectedTextColor)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 8)
                                    .background(
                                        isSelected
                                            ? LinearGradient(
                                                colors: [Color(hex: "4F78DE"), Color(hex: "355BBF")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                            : unselectedChipGradient,
                                        in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                                            .stroke(
                                                isSelected
                                                    ? Color.clear
                                                    : (colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.6)),
                                                lineWidth: 1
                                            )
                                    )
                                    .shadow(
                                        color: isSelected
                                            ? Color(hex: "355BBF").opacity(0.30)
                                            : (colorScheme == .dark ? Color.black.opacity(0.2) : Color(hex: "4A6EB0").opacity(0.08)),
                                        radius: isSelected ? 5 : 3,
                                        y: 2
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 24)
                }

                Spacer(minLength: 24)
            }
        }
    }
}
