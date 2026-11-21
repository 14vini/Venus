//
//  VenusCheckInProjectionChartView.swift
//  Venus
//
//  Gráfico preditivo de energia e plano personalizado,
//  adaptado para modo claro e escuro.
//

import SwiftUI

struct VenusCheckInProjectionChartView: View {
    let level: VenusCheckInMoodLevel
    var onExplorePlan: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @State private var curveProgress: CGFloat = 0.0
    @State private var showBadge: Bool = false

    private var titleColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "12233F")
    }

    private var eyebrowColor: Color {
        colorScheme == .dark ? Color(hex: "93C5FD") : Color(hex: "4A6EB0")
    }

    private var footnoteColor: Color {
        colorScheme == .dark ? Color(hex: "CBD5E1") : Color(hex: "40557A")
    }

    private var cardBackground: Color {
        colorScheme == .dark ? Color(hex: "152238").opacity(0.92) : Color.white.opacity(0.85)
    }

    private var gridLineColor: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color(hex: "E8EEF8")
    }

    private var targetDateString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "d 'de' MMM"
        let future = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
        return formatter.string(from: future)
    }

    private var projectionHeadline: String {
        switch level {
        case .veryLow, .low:
            return "Prevemos que você recuperará energia estável para seus projetos e vida pessoal até \(targetDateString)"
        case .neutral:
            return "Prevemos um ganho de clareza e foco contínuo para suas metas até \(targetDateString)"
        case .good, .optimal:
            return "Prevemos uma elevação sustentada do seu potencial realizador até \(targetDateString)"
        }
    }

    private var percentageGain: String {
        switch level {
        case .veryLow: return "+180%"
        case .low: return "+150%"
        case .neutral: return "+90%"
        case .good: return "+65%"
        case .optimal: return "+45%"
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Título descritivo em Serif editorial
            VStack(alignment: .leading, spacing: 8) {
                Text("Previsão de recuperação")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(eyebrowColor)
                    .textCase(.uppercase)
                    .tracking(1.2)

                Text(projectionHeadline)
                    .font(.system(size: 26, weight: .regular, design: .serif))
                    .foregroundColor(titleColor)
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 24)
            .padding(.top, 10)

            // Gráfico com Curva Suave Ascendente
            ZStack {
                // Card de fundo adaptável (Glass / Surface)
                RoundedRectangle(cornerRadius: 28, style: .continuous)
                    .fill(cardBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 28, style: .continuous)
                            .stroke(colorScheme == .dark ? Color.white.opacity(0.12) : Color.white.opacity(0.6), lineWidth: 1)
                    )
                    .shadow(
                        color: colorScheme == .dark ? Color.black.opacity(0.40) : Color(hex: "6A85BD").opacity(0.18),
                        radius: 20,
                        x: 0,
                        y: 10
                    )

                VStack(spacing: 0) {
                    GeometryReader { geometry in
                        let w = geometry.size.width
                        let h = geometry.size.height

                        ZStack(alignment: .topLeading) {
                            // Linhas de grade horizontais sutis
                            VStack(spacing: h * 0.28) {
                                ForEach(0..<3) { _ in
                                    Rectangle()
                                        .fill(gridLineColor)
                                        .frame(height: 1)
                                }
                            }
                            .offset(y: h * 0.15)

                            // Área preenchida sob a curva
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: h * 0.78))
                                path.addCurve(
                                    to: CGPoint(x: w * 0.85, y: h * 0.22),
                                    control1: CGPoint(x: w * 0.35, y: h * 0.74),
                                    control2: CGPoint(x: w * 0.60, y: h * 0.24)
                                )
                                path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.88))
                                path.addLine(to: CGPoint(x: 0, y: h * 0.88))
                                path.closeSubpath()
                            }
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "F472B6").opacity(0.28 * curveProgress),
                                        Color(hex: "F472B6").opacity(0.04 * curveProgress),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )

                            // Curva Bézier ascendente
                            Path { path in
                                path.move(to: CGPoint(x: 0, y: h * 0.78))
                                path.addCurve(
                                    to: CGPoint(x: w * 0.85, y: h * 0.22),
                                    control1: CGPoint(x: w * 0.35, y: h * 0.74),
                                    control2: CGPoint(x: w * 0.60, y: h * 0.24)
                                )
                            }
                            .trim(from: 0, to: curveProgress)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color(hex: "60A5FA"),
                                        Color(hex: "EC4899"),
                                        Color(hex: "F43F5E")
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: 4, lineCap: .round)
                            )

                            // Linha tracejada vertical para o marco
                            Path { path in
                                path.move(to: CGPoint(x: w * 0.85, y: h * 0.22))
                                path.addLine(to: CGPoint(x: w * 0.85, y: h * 0.88))
                            }
                            .stroke(
                                Color(hex: "F472B6").opacity(0.65 * curveProgress),
                                style: StrokeStyle(lineWidth: 1.5, dash: [4, 4])
                            )

                            // Ponto destacado no final da curva
                            Circle()
                                .fill(Color(hex: "F43F5E"))
                                .frame(width: 10, height: 10)
                                .shadow(color: Color(hex: "F43F5E").opacity(0.5), radius: 6)
                                .position(x: w * 0.85, y: h * 0.22)
                                .opacity(curveProgress > 0.8 ? 1 : 0)

                            // Tag Flutuante "Nível de energia +150%"
                            if showBadge {
                                HStack(spacing: 5) {
                                    Image(systemName: "bolt.fill")
                                        .font(.system(size: 10, weight: .bold))
                                    Text("Nível de energia \(percentageGain)")
                                        .font(.system(size: 12, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "3B82F6"), Color(hex: "2563EB")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .shadow(color: Color(hex: "2563EB").opacity(0.4), radius: 8, x: 0, y: 3)
                                )
                                .position(x: w * 0.40, y: h * 0.52)
                                .transition(.scale.combined(with: .opacity))
                            }

                            // Rótulo da data de destino
                            Text(targetDateString)
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(Color(hex: "F472B6"))
                                .position(x: w * 0.85, y: h * 0.95)
                                .opacity(curveProgress > 0.6 ? 1 : 0)
                        }
                    }
                    .frame(height: 220)
                    .padding(18)
                }
            }
            .frame(height: 250)
            .padding(.horizontal, 24)

            // Mensagem de compromisso
            Text("Iremos incorporar esse objetivo diretamente no seu plano personalizado de hoje.")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(footnoteColor)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 32)
                .padding(.top, 4)

            Spacer(minLength: 16)

            // Botão CTA Principal: "Explorar meu plano ➔"
            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onExplorePlan()
            } label: {
                HStack(spacing: 10) {
                    Text("Explorar meu plano")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                    Image(systemName: "arrow.right")
                        .font(.system(size: 15, weight: .bold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "3B82F6"), Color(hex: "1D4ED8")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .shadow(color: Color(hex: "1D4ED8").opacity(0.45), radius: 14, x: 0, y: 6)
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.1)) {
                curveProgress = 1.0
            }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.75).delay(0.7)) {
                showBadge = true
            }
        }
    }
}
