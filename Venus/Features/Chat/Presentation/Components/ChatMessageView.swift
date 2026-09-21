//
//  ChatMessageView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct ChatMessageView: View {
    let message: ChatMessage
    let isPrevSame: Bool
    let isNextSame: Bool
    let onReact: () -> Void
    let onReply: () -> Void
    var onScheduleReminder: ((String) -> Void)? = nil
    
    @State private var dragOffset: CGFloat = 0
    @State private var hasTriggeredReply = false
    @State private var isHeartPopping = false
    
    var body: some View {
        HStack(spacing: 0) {
            if dragOffset > 0 {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(VenusTheme.textSecondary)
                    .frame(width: 30)
                    .opacity(Double(min(1.0, dragOffset / 50.0)))
                    .scaleEffect(min(1.1, dragOffset / 50.0))
                    .padding(.trailing, 8)
            }
            
            HStack(spacing: 8) {
                if !message.isFromUser {
                    if !isNextSame {
                        VenusMoodOrb(
                            mood: .calm,
                            state: .idle,
                            size: 28,
                            showFace: true,
                            isInteractive: false
                        )
                    } else {
                        Spacer()
                            .frame(width: 28)
                    }
                }
                
                VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 3) {
                    if let replyContent = message.replyToContent {
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(message.isFromUser ? Color.white.opacity(0.6) : VenusTheme.primary)
                                .frame(width: 2)
                            
                            Text(replyContent)
                                .font(.caption2)
                                .italic()
                                .foregroundColor(message.isFromUser ? Color.white.opacity(0.8) : VenusTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(message.isFromUser ? Color.white.opacity(0.12) : VenusTheme.surface.opacity(0.5))
                        .cornerRadius(6)
                        .padding(.top, 4)
                    }
                    
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(message.isFromUser ? .white : VenusTheme.text)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Group {
                                if message.isFromUser {
                                    LinearGradient(
                                        colors: [
                                            Color(hex: "8A2387"),
                                            Color(hex: "E94057"),
                                            Color(hex: "F27121")
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                } else {
                                    VenusTheme.surface
                                }
                            }
                        )
                        .clipShape(ChatBubbleCornerShape(
                            isFromUser: message.isFromUser,
                            isPrevSame: isPrevSame,
                            isNextSame: isNextSame
                        ))
                    
                    if !message.isFromUser {
                        if let tags = message.tags, !tags.isEmpty {
                            HStack(spacing: 6) {
                                ForEach(tags, id: \.self) { tag in
                                    Text("#\(tag)")
                                        .font(.system(size: 10, weight: .bold, design: .rounded))
                                        .foregroundColor(VenusTheme.primary.opacity(0.85))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Capsule().fill(VenusTheme.primary.opacity(0.12)))
                                }
                            }
                            .padding(.top, 4)
                            .padding(.horizontal, 4)
                        }
                        
                        if let summary = message.summary, !summary.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                HStack(spacing: 5) {
                                    Image(systemName: "note.text")
                                        .font(.system(size: 11, weight: .bold))
                                    Text("Nota Mental")
                                        .font(.system(size: 11, weight: .bold, design: .rounded))
                                }
                                .foregroundColor(VenusTheme.accentPink)
                                
                                Text(summary)
                                    .font(.system(size: 12))
                                    .foregroundColor(VenusTheme.textSecondary)
                                    .lineLimit(nil)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                            .padding(10)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(VenusTheme.cardSurface)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(VenusTheme.accentPink.opacity(0.2), lineWidth: 1)
                                    )
                            )
                            .frame(maxWidth: 260, alignment: .leading)
                            .padding(.top, 4)
                            .padding(.horizontal, 4)
                        }
                        
                        if let reminder = message.reminder, !reminder.isEmpty {
                            Button {
                                onScheduleReminder?(reminder)
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: "bell.badge.fill")
                                        .font(.system(size: 10))
                                    Text("Ativar Lembrete: \(reminder)")
                                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                                        .lineLimit(1)
                                }
                                .foregroundColor(.white)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [VenusTheme.accentPurple, VenusTheme.primary],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                )
                                .shadow(color: VenusTheme.accentPurple.opacity(0.2), radius: 3, x: 0, y: 2)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .overlay(
                    Group {
                        if let reaction = message.reaction {
                            Text(reaction)
                                .font(.system(size: 13))
                                .padding(4)
                                .background(VenusTheme.cardSurface)
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
                                .scaleEffect(isHeartPopping ? 1.3 : 1.0)
                                .offset(x: message.isFromUser ? -10 : 10, y: 15)
                                .onTapGesture {
                                    onReact()
                                }
                        }
                    },
                    alignment: message.isFromUser ? .bottomLeading : .bottomTrailing
                )
            }
            .offset(x: dragOffset)
            .gesture(
                DragGesture(minimumDistance: 10, coordinateSpace: .local)
                    .onChanged { value in
                        let translation = value.translation.width
                        if translation > 0 {
                            withAnimation(.interactiveSpring()) {
                                dragOffset = min(translation, 80)
                            }
                            
                            if dragOffset >= 50 && !hasTriggeredReply {
                                hasTriggeredReply = true
                                onReply()
                            }
                        }
                    }
                    .onEnded { _ in
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.65)) {
                            dragOffset = 0
                        }
                        hasTriggeredReply = false
                    }
            )
            .onTapGesture(count: 2) {
                isHeartPopping = true
                onReact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
                    isHeartPopping = false
                }
            }
            
            if message.isFromUser {
                Spacer(minLength: 0)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, isPrevSame ? 3 : 12)
        .transition(
            message.isFromUser ?
                .asymmetric(
                    insertion: .move(edge: .bottom)
                        .combined(with: .scale(scale: 0.1, anchor: .bottomTrailing))
                        .combined(with: .opacity),
                    removal: .opacity
                ) :
                .asymmetric(
                    insertion: .move(edge: .leading)
                        .combined(with: .scale(scale: 0.4, anchor: .topLeading))
                        .combined(with: .opacity),
                    removal: .opacity
                )
        )
    }
}

struct ChatBubbleCornerShape: Shape {
    let isFromUser: Bool
    let isPrevSame: Bool
    let isNextSame: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        
        let minCorner: CGFloat = 4
        let maxCorner: CGFloat = 20
        
        var topLeft: CGFloat = maxCorner
        var topRight: CGFloat = maxCorner
        var bottomLeft: CGFloat = maxCorner
        var bottomRight: CGFloat = maxCorner
        
        if isFromUser {
            if isPrevSame {
                topRight = minCorner
            }
            if isNextSame {
                bottomRight = minCorner
            }
        } else {
            if isPrevSame {
                topLeft = minCorner
            }
            if isNextSame {
                bottomLeft = minCorner
            }
        }
        
        let width = rect.width
        let height = rect.height
        
        path.move(to: CGPoint(x: topLeft, y: 0))
        path.addLine(to: CGPoint(x: width - topRight, y: 0))
        path.addArc(withCenter: CGPoint(x: width - topRight, y: topRight), radius: topRight, startAngle: -CGFloat.pi/2, endAngle: 0, clockwise: true)
        path.addLine(to: CGPoint(x: width, y: height - bottomRight))
        path.addArc(withCenter: CGPoint(x: width - bottomRight, y: height - bottomRight), radius: bottomRight, startAngle: 0, endAngle: CGFloat.pi/2, clockwise: true)
        path.addLine(to: CGPoint(x: bottomLeft, y: height))
        path.addArc(withCenter: CGPoint(x: bottomLeft, y: height - bottomLeft), radius: bottomLeft, startAngle: CGFloat.pi/2, endAngle: CGFloat.pi, clockwise: true)
        path.addLine(to: CGPoint(x: 0, y: topLeft))
        path.addArc(withCenter: CGPoint(x: topLeft, y: topLeft), radius: topLeft, startAngle: CGFloat.pi, endAngle: -CGFloat.pi/2, clockwise: true)
        path.close()
        
        return Path(path.cgPath)
    }
}
