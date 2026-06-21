//
//  ActionExecutionView.swift
//  Venus
//

import SwiftUI
import Combine

struct ActionExecutionView: View {
    let actionModel: NextBestAction
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    @State private var isPlaying = false
    @State private var timeRemaining: Int
    @State private var totalTime: Int

    init(actionModel: NextBestAction) {
        self.actionModel = actionModel
        let seconds = actionModel.estimatedMinutes * 60
        _timeRemaining = State(initialValue: seconds)
        _totalTime = State(initialValue: seconds)
    }

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: VenusTheme.accentGreen,
                secondaryAccent: VenusTheme.moodMintStrong,
                tertiaryAccent: VenusTheme.primary,
                isAnimated: isPlaying
            )

            VStack(spacing: 32) {
                // Top Bar
                HStack {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(VenusTheme.textSecondary)
                            .padding(14)
                            .background(Circle().fill(.ultraThinMaterial))
                    }
                    .buttonStyle(.plain)
                    Spacer()
                }
                .padding(.horizontal, 24)
                .padding(.top, 24)

                Spacer()

                // Titulo
                VStack(spacing: 12) {
                    Text(actionModel.title)
                        .font(.system(size: 32, weight: .black, design: .rounded))
                        .foregroundColor(VenusTheme.text)
                        .multilineTextAlignment(.center)

                    Text(actionModel.detail)
                        .font(.system(.body, design: .rounded).weight(.medium))
                        .foregroundColor(VenusTheme.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                // Timer Circular
                ZStack {
                    Circle()
                        .stroke(VenusTheme.cardBorder.opacity(0.3), lineWidth: 16)
                        .frame(width: 240, height: 240)

                    Circle()
                        .trim(from: 0, to: CGFloat(timeRemaining) / CGFloat(totalTime))
                        .stroke(VenusTheme.primaryGradient, style: StrokeStyle(lineWidth: 16, lineCap: .round))
                        .frame(width: 240, height: 240)
                        .rotationEffect(.degrees(-90))
                        .animation(.linear(duration: 1.0), value: timeRemaining)

                    Text(timeString(from: timeRemaining))
                        .font(.system(size: 56, weight: .black, design: .rounded).monospacedDigit())
                        .foregroundColor(VenusTheme.text)
                }
                .padding(.vertical, 24)

                Spacer()

                // Botão de Play/Pause
                Button {
                    isPlaying.toggle()
                } label: {
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 32, weight: .black))
                        .foregroundColor(Color(UIColor.systemBackground))
                        .frame(width: 90, height: 90)
                        .background(Color.primary)
                        .clipShape(Circle())
                        .shadow(color: Color.primary.opacity(0.2), radius: 12, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .padding(.bottom, 48)
            }
        }
        .onReceive(Timer.publish(every: 1, on: .main, in: .common).autoconnect()) { _ in
            if isPlaying && timeRemaining > 0 {
                timeRemaining -= 1
            } else if timeRemaining == 0 {
                isPlaying = false
            }
        }
    }

    private func timeString(from seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%02d:%02d", m, s)
    }
}
