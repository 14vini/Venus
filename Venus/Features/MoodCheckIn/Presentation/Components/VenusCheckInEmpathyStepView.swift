//
//  VenusCheckInEmpathyStepView.swift
//  Venus
//
//  Tela de acolhimento e validação emocional ("Obrigado por ser honesto!"),
//  adaptada para modo claro e escuro.
//

import SwiftUI

struct VenusCheckInEmpathyStepView: View {
    let level: VenusCheckInMoodLevel
    var onContinue: () -> Void

    @Environment(\.colorScheme) private var colorScheme

    private var titleColor: Color {
        colorScheme == .dark ? Color.white : Color(hex: "14213D")
    }

    private var headlineColor: Color {
        colorScheme == .dark ? Color(hex: "CBD5E1") : Color(hex: "3A4B6E")
    }

    private var footnoteColor: Color {
        colorScheme == .dark ? Color(hex: "94A3B8") : Color(hex: "435A80")
    }

    private var empathyTitle: String {
        "Obrigado por ser honesto!"
    }

    private var empathyHeadline: String {
        switch level {
        case .veryLow:
            return "Reconhecer que sua energia está baixa é o primeiro passo para o autocuidado real. Respeitar o seu ritmo hoje evitará exaustão amanhã."
        case .low:
            return "Dias com ritmo mais lento fazem parte da jornada. Vamos ajustar o seu dia para focar apenas no essencial com pausas restauradoras."
        case .neutral:
            return "O ponto de equilíbrio é uma base sólida para clareza mental. Uma cadência constante permite decisões conscientes sem sobrecarga."
        case .good:
            return "Sentir-se disposto é um presente. É o momento perfeito para avançar nas suas prioridades com foco e leveza."
        case .optimal:
            return "Essa energia radiante é contagiante! Vamos direcionar esse impulso criativo para o que realmente move os seus maiores sonhos."
        }
    }

    private var empathyFootnote: String {
        switch level {
        case .veryLow, .low:
            return "É o primeiro passo em direção a um dia leve, seguro e com respeito aos seus limites."
        case .neutral:
            return "O primeiro passo para calibrar suas próximas horas com serenidade e foco."
        case .good, .optimal:
            return "O primeiro passo para um dia rico em realizações, alegria e conexões significativas."
        }
    }

    var body: some View {
        VStack(spacing: 20) {
            // Título e Subtítulo acolhedores
            VStack(spacing: 12) {
                Text(empathyTitle)
                    .font(.system(size: 34, weight: .regular, design: .serif))
                    .foregroundColor(titleColor)
                    .multilineTextAlignment(.center)

                Text(empathyHeadline)
                    .font(.system(size: 15, weight: .regular, design: .rounded))
                    .foregroundColor(headlineColor)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .padding(.horizontal, 16)
            }
            .padding(.top, 12)

            Spacer(minLength: 8)

            // Mascote Oficial Venus Acolhedor no Centro
            VenusPastelMascotView(
                level: level,
                size: 190,
                isAnimated: true,
                customState: .empathetic,
                customExpression: .empathetic
            )

            Spacer(minLength: 8)

            // Texto inferior de reforço positivo
            Text(empathyFootnote)
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(footnoteColor)
                .multilineTextAlignment(.center)
                .lineSpacing(3)
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
        .padding(.horizontal, 20)
    }
}
