//
//  WeeklyMoodWaveform.swift
//  Venus
//

import SwiftUI

struct ChartPoint: Identifiable, Equatable {
    let id = UUID()
    let day: String
    let score: Double
    let emoji: String
    let title: String
    let detail: String
}

struct WeeklyMoodWaveform: View {
    let moods: [Mood]
    
    private var chartPoints: [ChartPoint] {
        if moods.isEmpty {
            return [
                ChartPoint(day: "Seg", score: 7, emoji: "😌", title: "Calmo", detail: "Dia com sensação de clareza e ritmo estável."),
                ChartPoint(day: "Ter", score: 8, emoji: "😊", title: "Feliz", detail: "Momento de conexão e realização pessoal."),
                ChartPoint(day: "Qua", score: 4, emoji: "🥱", title: "Cansado", detail: "Sobrecarga de tarefas e esforço mental."),
                ChartPoint(day: "Qui", score: 3, emoji: "😢", title: "Triste", detail: "Dia com pensamentos melancólicos."),
                ChartPoint(day: "Sex", score: 9, emoji: "⚡️", title: "Energizado", detail: "Conclusão de projetos importantes!"),
                ChartPoint(day: "Sáb", score: 7, emoji: "😌", title: "Calmo", detail: "Tempo de qualidade com família."),
                ChartPoint(day: "Dom", score: 8, emoji: "😊", title: "Feliz", detail: "Descanso pleno e introspecção.")
            ]
        } else {
            let calendar = Calendar.current
            let weekdays = ["Dom", "Seg", "Ter", "Qua", "Qui", "Sex", "Sáb"]
            
            let sortedMoods = moods.suffix(7).sorted(by: { $0.timestamp < $1.timestamp })
            
            return sortedMoods.map { mood in
                let weekdayIndex = calendar.component(.weekday, from: mood.timestamp) - 1
                let dayName = (weekdayIndex >= 0 && weekdayIndex < weekdays.count) ? weekdays[weekdayIndex] : "Dia"
                
                let score: Double
                switch mood.type {
                case .energetic: score = 9.0
                case .happy: score = 8.0
                case .calm: score = 7.0
                case .tired: score = 4.0
                case .sad: score = 3.0
                case .stressed: score = 2.0
                }
                
                let detail = mood.note ?? "Momento registrado com Venus."
                return ChartPoint(
                    day: dayName,
                    score: score,
                    emoji: mood.type.emoji,
                    title: mood.type.rawValue,
                    detail: detail
                )
            }
        }
    }
    
    @State private var selectedIndex: Int = 2
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "waveform.path.ecg")
                    .foregroundColor(VenusTheme.primary)
                Text("Sua Onda Emocional")
                    .font(.system(.subheadline, design: .rounded).weight(.semibold))
                    .foregroundColor(.white.opacity(0.9))
                Spacer()
                Text("Arraste para explorar")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 4)
            
            GeometryReader { geo in
                let width = geo.size.width
                let count = max(chartPoints.count, 2)
                let step = width / CGFloat(count - 1)
                
                ZStack {
                    MoodWaveformLine(points: chartPoints, isSelected: selectedIndex)
                        .frame(height: 120)
                    
                    Color.clear
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let x = value.location.x
                                    let idx = Int(round(x / step))
                                    let clampedIdx = max(0, min(chartPoints.count - 1, idx))
                                    if clampedIdx != selectedIndex {
                                        selectedIndex = clampedIdx
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                }
                        )
                }
            }
            .frame(height: 120)
            .padding(.horizontal, 10)
            
            GeometryReader { geo in
                let count = max(chartPoints.count, 2)
                let step = geo.size.width / CGFloat(count - 1)
                ForEach(0..<chartPoints.count, id: \.self) { idx in
                    let x = CGFloat(idx) * step
                    Text(chartPoints[idx].day)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(idx == selectedIndex ? VenusTheme.primary : .white.opacity(0.4))
                        .position(x: x, y: 10)
                        .animation(.spring(response: 0.2), value: selectedIndex)
                }
            }
            .frame(height: 20)
            .padding(.horizontal, 10)
            .padding(.top, 4)
            
            if selectedIndex >= 0 && selectedIndex < chartPoints.count {
                let currentPt = chartPoints[selectedIndex]
                HStack(spacing: 12) {
                    Text(currentPt.emoji)
                        .font(.system(size: 28))
                        .padding(10)
                        .background(Circle().fill(.white.opacity(0.08)))
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(currentPt.day) - \(currentPt.title)")
                            .font(.system(.subheadline, design: .rounded).weight(.bold))
                            .foregroundColor(.white)
                        
                        Text(currentPt.detail)
                            .font(.system(size: 13, design: .serif))
                            .foregroundColor(.white.opacity(0.7))
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    Spacer()
                }
                .padding(14)
                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                .id(selectedIndex)
            }
        }
        .padding(16)
        .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 24, style: .continuous))
    }
}

struct MoodWaveformLine: View {
    let points: [ChartPoint]
    let isSelected: Int
    
    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let count = max(points.count, 2)
            let step = width / CGFloat(count - 1)
            
            ZStack {
                Path { path in
                    path.move(to: CGPoint(x: 0, y: height))
                    for (index, pt) in points.enumerated() {
                        let x = CGFloat(index) * step
                        let y = height - (CGFloat(pt.score) / 10.0 * (height - 20))
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        colors: [
                            VenusTheme.primary.opacity(0.2),
                            VenusTheme.primary.opacity(0.0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                
                Path { path in
                    for (index, pt) in points.enumerated() {
                        let x = CGFloat(index) * step
                        let y = height - (CGFloat(pt.score) / 10.0 * (height - 20))
                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(
                        colors: [
                            VenusTheme.primary,
                            VenusTheme.secondary
                        ],
                        startPoint: .leading,
                        endPoint: .trailing
                    ),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )
                
                ForEach(0..<points.count, id: \.self) { idx in
                    let pt = points[idx]
                    let x = CGFloat(idx) * step
                    let y = height - (CGFloat(pt.score) / 10.0 * (height - 20))
                    
                    Circle()
                        .fill(idx == isSelected ? Color.white : VenusTheme.primary)
                        .frame(width: idx == isSelected ? 12 : 8, height: idx == isSelected ? 12 : 8)
                        .overlay(
                            Circle()
                                .stroke(VenusTheme.primary, lineWidth: idx == isSelected ? 3 : 0)
                        )
                        .position(x: x, y: y)
                        .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isSelected)
                }
            }
        }
    }
}
