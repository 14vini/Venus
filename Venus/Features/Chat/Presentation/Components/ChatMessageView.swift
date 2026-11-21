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
    var onShowPlan: (() -> Void)? = nil
    
    @State private var dragOffset: CGFloat = 0
    @State private var isHeartPopping = false
    @State private var cursorBlink = true
    @Environment(\.colorScheme) private var colorScheme
    
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
                                .fill(VenusTheme.primary)
                                .frame(width: 2.5)
                            
                            Text(replyContent)
                                .font(.system(size: 11, weight: .light, design: .rounded))
                                .italic()
                                .foregroundColor(VenusTheme.textSecondary)
                                .lineLimit(1)
                        }
                        .padding(.horizontal, 11)
                        .padding(.vertical, 5)
                        .background(VenusTheme.surface.opacity(0.35))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .padding(.top, 2)
                    }
                    
                    // Main Message Text Bubble — balão em Liquid Glass real
                    HStack(alignment: .bottom, spacing: 3) {
                        Text(message.content)
                            .font(message.isFromUser
                                  ? .system(size: 15, weight: .regular, design: .rounded)
                                  : .system(size: 16, weight: .light, design: .rounded))
                            .lineSpacing(message.isFromUser ? 4 : 6)
                            .foregroundColor(VenusTheme.text)
                            .contentTransition(.opacity)

                        if !message.isFromUser && isStreaming && !message.content.isEmpty {
                            Rectangle()
                                .fill(VenusTheme.primary)
                                .frame(width: 2, height: 17)
                                .offset(y: -2)
                                .opacity(cursorBlink ? 0.85 : 0.15)
                                .animation(.easeInOut(duration: 0.45).repeatForever(autoreverses: true), value: cursorBlink)
                        }
                    }
                    .padding(.horizontal, 17)
                    .padding(.vertical, 13)
                    .glassEffect(
                        .regular.tint(VenusChatVisualStyle.bubbleTint(
                            isFromUser: message.isFromUser,
                            isDark: colorScheme == .dark
                        )),
                        in: ChatBubbleCornerShape(
                            isFromUser: message.isFromUser,
                            isPrevSame: isPrevSame,
                            isNextSame: isNextSame
                        )
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.82, alignment: message.isFromUser ? .trailing : .leading)
                    
                    // A proposta de rotina vive no acesso secundário; aqui fica só
                    // um convite discreto, para não competir com a conversa.
                    if let proposal = message.planningProposal, !proposal.proposedBlocks.isEmpty, !message.isFromUser {
                        Button {
                            UIImpactFeedbackGenerator(style: .light).impactOccurred()
                            onShowPlan?()
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "calendar.badge.clock")
                                    .font(.system(size: 11, weight: .semibold))

                                Text(message.isPlanningConfirmed == true
                                     ? "Plano ativo · ver detalhes"
                                     : "Ver proposta de rotina")
                                    .font(.system(size: 12, weight: .light, design: .rounded))

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 10, weight: .semibold))
                            }
                            .foregroundStyle(VenusTheme.primary)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .glassEffect(
                                .regular.tint(VenusChatVisualStyle.bubbleTint(
                                    isFromUser: false,
                                    isDark: colorScheme == .dark
                                )),
                                in: Capsule(style: .continuous)
                            )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                        .padding(.horizontal, 4)
                    }
                    
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
                            .foregroundColor(VenusTheme.text)
                            .padding(.horizontal, 13)
                            .padding(.vertical, 7)
                            .glassEffect(
                                .regular.tint(VenusChatVisualStyle.bubbleTint(
                                    isFromUser: true,
                                    isDark: colorScheme == .dark
                                )),
                                in: Capsule(style: .continuous)
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
                                .padding(6)
                                .glassEffect(.regular, in: Circle())
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
        .padding(.top, isPrevSame ? 4 : 16)
        .transition(
            .asymmetric(
                insertion: .scale(scale: 0.94, anchor: message.isFromUser ? .trailing : .leading)
                    .combined(with: .opacity)
                    .combined(with: .offset(y: 8)),
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
