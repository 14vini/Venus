//
//  VenusAppBackground.swift
//  Venus
//
//  Fundo suave e reutilizável do shell do app (azul → lilás → rosa).
//

import SwiftUI

// MARK: - VenusAppBackground

/// Gradiente suave usado como base do app.
///
/// - Light: azul claro → lilás → rosa, com um brilho rosado no canto inferior.
/// - Dark: tons profundo equivalentes, com opacidade controlada para manter legibilidade.
///
/// É um componente puramente decorativo: não captura toques e ignora safe areas.
struct VenusAppBackground: View {
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    VenusTheme.softBlue,
                    VenusTheme.softLilac,
                    VenusTheme.softPink
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            RadialGradient(
                colors: [
                    VenusTheme.softPink.opacity(colorScheme == .dark ? 0.20 : 0.42),
                    Color.clear
                ],
                center: .bottomTrailing,
                startRadius: 40,
                endRadius: 320
            )
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
}

// MARK: - View extension

extension View {
    /// Coloca o fundo suave do app atrás do conteúdo.
    func venusAppBackground() -> some View {
        background { VenusAppBackground() }
    }
}

#Preview {
    VenusAppBackground()
}
