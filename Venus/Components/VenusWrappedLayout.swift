//
//  VenusWrappedLayout.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct VenusWrappedLayout: Layout {
    var spacing: CGFloat = 8
    var lineSpacing: CGFloat = 8
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? .infinity
        var height: CGFloat = 0
        var currentX: CGFloat = 0
        var rowHeight: CGFloat = 0
        
        // If there are no subviews, return zero size
        if subviews.isEmpty { return .zero }
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            // Check if adding this item would overflow the width
            if currentX + size.width > width && currentX > 0 {
                // Move to next line
                height += rowHeight + lineSpacing
                currentX = 0
                rowHeight = 0
            }
            
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
        
        height += rowHeight
        
        return CGSize(width: width, height: height)
    }
    
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let width = bounds.width
        var currentX: CGFloat = bounds.minX
        var currentY: CGFloat = bounds.minY
        var rowHeight: CGFloat = 0
        
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            
            if currentX + size.width > bounds.maxX && currentX > bounds.minX {
                // Move to next line
                currentX = bounds.minX
                currentY += rowHeight + lineSpacing
                rowHeight = 0
            }
            
            subview.place(at: CGPoint(x: currentX, y: currentY), proposal: ProposedViewSize(size))
            
            currentX += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
