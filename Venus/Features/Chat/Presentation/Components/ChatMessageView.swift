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
    var isStreaming: Bool = false
    let onReact: () -> Void
    let onReply: () -> Void
    var onScheduleReminder: ((String) -> Void)? = nil
    
    @State private var dragOffset: CGFloat = 0
    @State private var isHeartPopping = false
    @State private var cursorBlink = true
    
    var body: some View {
        HStack(spacing: 0) {
            // Reply indicator appearing on right swipe
            if dragOffset > 0 {
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(VenusTheme.primary)
                    .frame(width: 32)
                    .opacity(Double(min(1.0, dragOffset / 40.0)))
                    .scaleEffect(min(1.15, dragOffset / 40.0))
                    .padding(.trailing, 6)
            }
            
            // Layout alignment: user messages on the right, Venus messages on the left
            HStack(alignment: .bottom, spacing: 0) {
                if message.isFromUser {
                    Spacer(minLength: 40)
                }
                
                VStack(alignment: message.isFromUser ? .trailing : .leading, spacing: 4) {
                    // Reply citation banner if message is replying to another
                    if let replyContent = message.replyToContent {
                        HStack(spacing: 6) {
                            Rectangle()
                                .fill(message.isFromUser ? Color.white.opacity(0.6) : VenusTheme.primary)
                                .frame(width: 2.5)
                            
                            Text(replyContent)
                                .font(.caption2)
                                .italic()
                                .foregroundColor(message.isFromUser ? Color.white.opacity(0.85) : VenusTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(message.isFromUser ? Color.white.opacity(0.12) : VenusTheme.surface.opacity(0.6))
                        .cornerRadius(6)
                        .padding(.top, 2)
                    }
                    
                    // Main Message Text Bubble
                    HStack(alignment: .bottom, spacing: 3) {
                        if message.content.isEmpty && !message.isFromUser && isStreaming {
                            HStack(spacing: 4) {
                                Circle().fill(VenusTheme.primary).frame(width: 5, height: 5)
                                Circle().fill(VenusTheme.primary.opacity(0.6)).frame(width: 5, height: 5)
                                Circle().fill(VenusTheme.primary.opacity(0.3)).frame(width: 5, height: 5)
                            }
                            .padding(.vertical, 6)
                        } else {
                            Text(message.content)
                                .font(message.isFromUser ? .system(size: 15, weight: .regular, design: .rounded) : .system(size: 16, weight: .regular, design: .serif))
                                .lineSpacing(message.isFromUser ? 3 : 5)
                                .foregroundColor(message.isFromUser ? .white : VenusTheme.text)
                        }
                        
                        if !message.isFromUser && isStreaming && !message.content.isEmpty {
                            Rectangle()
                                .fill(VenusTheme.primary)
                                .frame(width: 2.2, height: 18)
                                .offset(y: -2)
                                .opacity(cursorBlink ? 0.95 : 0.15)
                                .shadow(color: VenusTheme.primary.opacity(0.5), radius: 3)
                                .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: cursorBlink)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        Group {
                            if message.isFromUser {
                                LinearGradient(
                                    colors: [
                                        VenusTheme.primary,
                                        VenusTheme.accentPurple
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
                    .overlay(
                        Group {
                            if !message.isFromUser {
                                ChatBubbleCornerShape(
                                    isFromUser: false,
                                    isPrevSame: isPrevSame,
                                    isNextSame: isNextSame
                                )
                                .stroke(VenusTheme.primary.opacity(isStreaming ? 0.35 : 0.12), lineWidth: 1)
                            }
                        }
                    )
                    .shadow(color: isStreaming && !message.isFromUser ? VenusTheme.primary.opacity(0.18) : Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.82, alignment: message.isFromUser ? .trailing : .leading)
                    
                    // Optional Reminder Button (if present)
                    if let reminder = message.reminder, !reminder.isEmpty, !message.isFromUser {
                        Button {
                            onScheduleReminder?(reminder)
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "bell.badge.fill")
                                    .font(.system(size: 10))
                                Text("Lembrete: \(reminder)")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .lineLimit(1)
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
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
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 2)
                        .padding(.horizontal, 4)
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
                                .offset(x: message.isFromUser ? -8 : 8, y: 14)
                                .onTapGesture {
                                    onReact()
                                }
                        }
                    },
                    alignment: message.isFromUser ? .bottomLeading : .bottomTrailing
                )
                
                if !message.isFromUser {
                    Spacer(minLength: 40)
                }
            }
            .offset(x: dragOffset)
            .simultaneousGesture(
                DragGesture(minimumDistance: 20, coordinateSpace: .local)
                    .onChanged { value in
                        if value.translation.width > 0 && abs(value.translation.width) > abs(value.translation.height) * 1.3 {
                            dragOffset = min(value.translation.width, 60)
                        }
                    }
                    .onEnded { value in
                        if dragOffset >= 40 {
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                            onReply()
                        }
                        withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                            dragOffset = 0
                        }
                    }
            )
            .onTapGesture(count: 2) {
                isHeartPopping = true
                onReact()
                withAnimation(.spring(response: 0.3, dampingFraction: 0.45)) {
                    isHeartPopping = false
                }
            }
            .contextMenu {
                Button {
                    onReply()
                } label: {
                    Label("Responder", systemImage: "arrowshape.turn.up.left")
                }
                
                Button {
                    UIPasteboard.general.string = message.content
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                } label: {
                    Label("Copiar Texto", systemImage: "doc.on.doc")
                }
                
                Button {
                    onReact()
                } label: {
                    Label(message.reaction != nil ? "Remover Reação" : "Reagir com ❤️", systemImage: "heart.fill")
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, isPrevSame ? 2 : 10)
        .transition(
            .asymmetric(
                insertion: .opacity.combined(with: .offset(y: 8)),
                removal: .opacity
            )
        )
        .onAppear {
            if isStreaming {
                cursorBlink.toggle()
            }
        }
    }
}

struct ChatBubbleCornerShape: Shape {
    let isFromUser: Bool
    let isPrevSame: Bool
    let isNextSame: Bool
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath()
        
        let minCorner: CGFloat = 4
        let maxCorner: CGFloat = 18
        
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
