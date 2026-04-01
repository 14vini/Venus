//
//  VenusCard.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusCard<Content: View>: View {
    let content: Content
    var cornerRadius: CGFloat = 24
    var padding: CGFloat = 20
    var showBorder: Bool = true
    
    init(cornerRadius: CGFloat = 24, padding: CGFloat = 20, showBorder: Bool = true, @ViewBuilder content: () -> Content) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.showBorder = showBorder
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(padding)
            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
//            .background(
//                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                    .fill(VenusTheme.surface)
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
//                    .stroke(showBorder ? VenusTheme.cardBorder : Color.clear, lineWidth: 1)
//            )
//            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
    }
}

#Preview {
    ZStack {
        VenusTheme.backgroundGradient.ignoresSafeArea()
        VenusCard {
            Text("Premium Card Content")
                .foregroundColor(VenusTheme.text)
        }
        .padding()
    }
}
