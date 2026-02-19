//
//  TodoListView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

struct TodoListView: View {
    @StateObject private var viewModel: TodoListViewModel
    @State private var showBreathingView = false
    @State private var showPomodoroView = false
    @State private var showGratitudeView = false
    @State private var showCalendarSheet = false
    
    // Animation states
    @State private var animateHeader = false
    @State private var headerOffset: CGFloat = 0
    
    init(viewModel: TodoListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var incompleteTasks: [TodoItem] {
        viewModel.todos.filter { !$0.isCompleted }
    }
    
    var completedTasks: [TodoItem] {
        viewModel.todos.filter { $0.isCompleted }
    }
    
    var completionProgress: Double {
        guard !viewModel.todos.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(viewModel.todos.count)
    }
    
    var body: some View {
        ZStack {
            // Base Background
            VenusTheme.backgroundGradient
                .ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    
                    // MARK: - Premium Orange Header
                    VStack(spacing: 20) {
                        // Top Bar Space
                        Color.clear.frame(height: 20)
                        
                        // Date & Title Row
                        HStack(alignment: .center, spacing: 16) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(viewModel.selectedDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    .foregroundColor(.white.opacity(0.85))
                                    .tracking(0.8)
                                
                                Text("Minha Agenda")
                                    .font(.system(size: 32, weight: .heavy, design: .rounded))
                                    .foregroundColor(.white)
                            }
                            
                            Spacer()
                            
                            HStack(spacing: 10) {
                                // Today Jump
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                        viewModel.selectedDate = Date()
                                    }
                                }) {
                                    Text("Hoje")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 18)
                                        .padding(.vertical, 11)
                                        .background(
                                            Capsule()
                                                .fill(Color.white.opacity(0.25))
                                                .overlay(
                                                    Capsule()
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                                
                                // Calendar Button
                                Button(action: { showCalendarSheet = true }) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundColor(.white)
                                        .frame(width: 46, height: 46)
                                        .background(
                                            Circle()
                                                .fill(Color.white.opacity(0.25))
                                                .overlay(
                                                    Circle()
                                                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                                                )
                                        )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        
                        // Week Strip
                        ScrollViewReader { proxy in
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    Spacer().frame(width: 14)
                                    ForEach(viewModel.currentWeek, id: \.self) { date in
                                        DateStripItem(
                                            date: date,
                                            isSelected: viewModel.isSameDay(date1: date, date2: viewModel.selectedDate),
                                            isToday: viewModel.isSameDay(date1: date, date2: Date()),
                                            onTap: {
                                                withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                                                    viewModel.selectedDate = date
                                                }
                                            },
                                            isOrangeTheme: true
                                        )
                                        .id(date)
                                    }
                                    Spacer().frame(width: 14)
                                }
                            }
                            .onChange(of: viewModel.selectedDate) { _, newDate in
                                withAnimation {
                                    proxy.scrollTo(newDate, anchor: .center)
                                }
                            }
                        }
                        
                        Spacer().frame(height: 20)
                    }
                    .background(
                        ZStack {
                            VenusTheme.orangeTopGradient
                            
                            // Animated Orbs
                            Circle()
                                .fill(Color.white.opacity(0.12))
                                .frame(width: 350, height: 350)
                                .blur(radius: 60)
                                .offset(x: -120, y: -40)
                                .scaleEffect(animateHeader ? 1.15 : 0.85)
                            
                            Circle()
                                .fill(Color.yellow.opacity(0.18))
                                .frame(width: 250, height: 250)
                                .blur(radius: 50)
                                .offset(x: 110, y: 35)
                                .scaleEffect(animateHeader ? 0.85 : 1.15)
                        }
                        .clipShape(CustomCornerShape(corners: [.bottomLeft, .bottomRight], radius: 40))
                        .shadow(color: Color(hex: "FF3D00").opacity(0.25), radius: 20, x: 0, y: 10)
                        .ignoresSafeArea(edges: .top)
                    )
                    .animation(.easeInOut(duration: 4.5).repeatForever(autoreverses: true), value: animateHeader)
                    
                    // MARK: - Content Area
                    VStack(spacing: 20) {
                        
                        // Progress & Stats Card
                        VStack(spacing: 16) {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Progresso de Hoje")
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(VenusTheme.textSecondary)
                                    
                                    HStack(spacing: 8) {
                                        Text("\(completedTasks.count)")
                                            .font(.system(size: 32, weight: .bold, design: .rounded))
                                            .foregroundColor(Color(hex: "FF3D00"))
                                        
                                        Text("/ \(viewModel.todos.count) tarefas")
                                            .font(.system(size: 18, weight: .medium))
                                            .foregroundColor(VenusTheme.text)
                                    }
                                }
                                
                                Spacer()
                                
                                // Circular Progress
                                ZStack {
                                    Circle()
                                        .stroke(Color.gray.opacity(0.2), lineWidth: 8)
                                        .frame(width: 70, height: 70)
                                    
                                    Circle()
                                        .trim(from: 0, to: completionProgress)
                                        .stroke(
                                            LinearGradient(
                                                colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            ),
                                            style: StrokeStyle(lineWidth: 8, lineCap: .round)
                                        )
                                        .frame(width: 70, height: 70)
                                        .rotationEffect(.degrees(-90))
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: completionProgress)
                                    
                                    Text("\(Int(completionProgress * 100))%")
                                        .font(.system(size: 14, weight: .bold))
                                        .foregroundColor(VenusTheme.text)
                                }
                            }
                            
                            // Progress Bar
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Capsule()
                                        .fill(Color.gray.opacity(0.15))
                                        .frame(height: 8)
                                    
                                    Capsule()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .frame(width: geometry.size.width * completionProgress, height: 8)
                                        .animation(.spring(response: 0.6, dampingFraction: 0.7), value: completionProgress)
                                }
                            }
                            .frame(height: 8)
                        }
                        .padding(20)
                        .background(
                            ZStack {
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(.ultraThinMaterial)
                                RoundedRectangle(cornerRadius: 24)
                                    .fill(VenusTheme.surface)
                            }
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 6)
                        .padding(.horizontal, 24)
                        .padding(.top, 28)
                        
                        // Quick Actions
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Ações Rápidas")
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(VenusTheme.text)
                                .padding(.horizontal, 24)
                            
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 14) {
                                    Spacer().frame(width: 10)
                                    
                                    TodoQuickActionCard(
                                        title: "Respiração",
                                        subtitle: "5 min",
                                        icon: "wind",
                                        gradient: [Color(hex: "FF5F15"), Color(hex: "FF3D00")]
                                    ) { showBreathingView = true }
                                    
                                    TodoQuickActionCard(
                                        title: "Foco",
                                        subtitle: "25 min",
                                        icon: "timer",
                                        gradient: [Color(hex: "9D50BB"), Color(hex: "6E48AA")]
                                    ) { showPomodoroView = true }
                                    
                                    TodoQuickActionCard(
                                        title: "Gratidão",
                                        subtitle: "3 min",
                                        icon: "heart.fill",
                                        gradient: [Color(hex: "F472B6"), Color(hex: "EC4899")]
                                    ) { showGratitudeView = true }
                                    
                                    Spacer().frame(width: 10)
                                }
                            }
                        }
                        
                        // MARK: - Tasks Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Text("Tarefas")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(VenusTheme.text)
                                Spacer()
                                
                                if !incompleteTasks.isEmpty {
                                    Text("\(incompleteTasks.count) pendentes")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(VenusTheme.textSecondary)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 6)
                                        .background(
                                            Capsule()
                                                .fill(VenusTheme.textSecondary.opacity(0.12))
                                        )
                                }
                            }
                            .padding(.horizontal, 24)
                            
                            if viewModel.todos.isEmpty {
                                // Empty State
                                VStack(spacing: 20) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "FF3D00").opacity(0.1))
                                            .frame(width: 100, height: 100)
                                        
                                        Image(systemName: "checkmark.circle.fill")
                                            .font(.system(size: 50))
                                            .foregroundColor(Color(hex: "FF3D00"))
                                    }
                                    
                                    VStack(spacing: 8) {
                                        Text("Nenhuma tarefa")
                                            .font(.system(size: 20, weight: .bold))
                                            .foregroundColor(VenusTheme.text)
                                        Text("Toque no botão + para adicionar uma nova tarefa")
                                            .font(.system(size: 15))
                                            .foregroundColor(VenusTheme.textSecondary)
                                            .multilineTextAlignment(.center)
                                            .padding(.horizontal, 40)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 70)
                            } else {
                                VStack(spacing: 14) {
                                    // Incomplete Tasks
                                    ForEach(incompleteTasks) { item in
                                        EnhancedTodoItemView(item: item, onToggle: {
                                            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                viewModel.toggleTodo(id: item.id)
                                            }
                                        })
                                        .padding(.horizontal, 24)
                                        .transition(.asymmetric(
                                            insertion: .scale.combined(with: .opacity),
                                            removal: .scale(scale: 0.9).combined(with: .opacity)
                                        ))
                                    }
                                    
                                    // Completed Section
                                    if !completedTasks.isEmpty {
                                        VStack(alignment: .leading, spacing: 12) {
                                            HStack {
                                                Image(systemName: "checkmark.circle.fill")
                                                    .foregroundColor(Color(hex: "FF3D00"))
                                                Text("Concluídas (\(completedTasks.count))")
                                                    .font(.system(size: 16, weight: .semibold))
                                                    .foregroundColor(VenusTheme.textSecondary)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 24)
                                            .padding(.top, 12)
                                            
                                            ForEach(completedTasks) { item in
                                                EnhancedTodoItemView(item: item, onToggle: {
                                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                                        viewModel.toggleTodo(id: item.id)
                                                    }
                                                })
                                                .padding(.horizontal, 24)
                                                .transition(.asymmetric(
                                                    insertion: .scale.combined(with: .opacity),
                                                    removal: .scale(scale: 0.9).combined(with: .opacity)
                                                ))
                                            }
                                        }
                                    }
                                }
                            }
                        }
                        
                        Spacer().frame(height: 120)
                    }
                }
            }
            
            // MARK: - Premium FAB
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button(action: { 
                        viewModel.showAddSheet = true
                    }) {
                        ZStack {
                            // Shadow layer
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 68, height: 68)
                                .blur(radius: 12)
                                .opacity(0.6)
                            
                            // Main button
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [Color(hex: "FF5F15"), Color(hex: "FF3D00")],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 68, height: 68)
                            
                            Image(systemName: "plus")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .padding(.trailing, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .sheet(isPresented: $viewModel.showAddSheet) {
            AddTodoView { title, time, type in
                viewModel.addTodo(title: title, time: time, type: type)
            }
            .presentationDetents([.fraction(0.6)])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showCalendarSheet) {
            NavigationView {
                VStack(spacing: 20) {
                    CalendarMonthView(
                        currentMonth: $viewModel.selectedMonth,
                        selectedDate: $viewModel.selectedDate,
                        onSelect: { date in
                            withAnimation {
                                viewModel.selectedDate = date
                                showCalendarSheet = false
                            }
                        },
                        isOrangeTheme: false
                    )
                    .padding(.top, 10)
                    Spacer()
                }
                .navigationTitle("Selecionar Data")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Fechar") {
                            showCalendarSheet = false
                        }
                        .foregroundColor(Color(hex: "FF3D00"))
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
        .fullScreenCover(isPresented: $showBreathingView) { BreathingView() }
        .fullScreenCover(isPresented: $showPomodoroView) { PomodoroView() }
        .fullScreenCover(isPresented: $showGratitudeView) { GratitudeView() }
        .onAppear {
            animateHeader = true
        }
    }
    
    @Namespace private var namespace
}

// MARK: - Quick Action Card
struct TodoQuickActionCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradient: [Color]
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(VenusTheme.text)
                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(VenusTheme.textSecondary)
                }
            }
            .frame(width: 145, height: 135)
            .padding(18)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 22)
                        .fill(.ultraThinMaterial)
                    RoundedRectangle(cornerRadius: 22)
                        .fill(VenusTheme.surface)
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
        }
        .buttonStyle(ScaleButtonStyle())
    }
}

// MARK: - Enhanced Todo Item
struct EnhancedTodoItemView: View {
    let item: TodoItem
    let onToggle: () -> Void
    @State private var offset: CGFloat = 0
    
    var body: some View {
        HStack(spacing: 14) {
            // Checkbox
            Button(action: onToggle) {
                ZStack {
                    if item.isCompleted {
                        Circle()
                            .fill(Color(hex: "FF3D00"))
                            .frame(width: 30, height: 30)
                        
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .strokeBorder(VenusTheme.textSecondary.opacity(0.4), lineWidth: 2)
                            .background(Circle().fill(Color.white.opacity(0.05)))
                            .frame(width: 30, height: 30)
                    }
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: item.isCompleted)
            }
            .buttonStyle(PlainButtonStyle())
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold))
                    .strikethrough(item.isCompleted)
                    .foregroundColor(item.isCompleted ? VenusTheme.textSecondary.opacity(0.6) : VenusTheme.text)
                
                if let time = item.time {
                    HStack(spacing: 6) {
                        Image(systemName: "clock")
                            .font(.system(size: 11))
                        Text(time.formatted(date: .omitted, time: .shortened))
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(VenusTheme.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(
                        Capsule()
                            .fill(VenusTheme.textSecondary.opacity(0.1))
                    )
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                RoundedRectangle(cornerRadius: 22)
                    .fill(VenusTheme.surface)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 22)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Date Strip Item
struct DateStripItem: View {
    let date: Date
    let isSelected: Bool
    let isToday: Bool
    let onTap: () -> Void
    var isOrangeTheme: Bool = false
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(date.formatted(.dateTime.weekday(.abbreviated)).uppercased())
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(textColor(for: .secondary))
                
                Text(date.formatted(.dateTime.day()))
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(textColor(for: .primary))
                
                // Today indicator
                if isToday && !isSelected {
                    Circle()
                        .fill(Color.white.opacity(0.6))
                        .frame(width: 5, height: 5)
                } else {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 5, height: 5)
                }
            }
            .frame(width: 65, height: 88)
            .background(
                ZStack {
                    if isSelected {
                        if isOrangeTheme {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color.white)
                                .shadow(color: Color.white.opacity(0.3), radius: 6, x: 0, y: 3)
                        } else {
                            RoundedRectangle(cornerRadius: 22, style: .continuous)
                                .fill(Color(hex: "FF3D00"))
                        }
                    } else {
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .fill(Color.white.opacity(isOrangeTheme ? 0.18 : 0.08))
                    }
                }
            )
        }
        .buttonStyle(PlainButtonStyle())
        .scaleEffect(isSelected ? 1.08 : 1.0)
        .animation(.spring(response: 0.35, dampingFraction: 0.7), value: isSelected)
    }
    
    enum TextType { case primary, secondary }
    
    func textColor(for type: TextType) -> Color {
        if isOrangeTheme {
            if isSelected {
                return Color(hex: "FF3D00")
            } else {
                return type == .primary ? .white : .white.opacity(0.75)
            }
        } else {
            if isSelected {
                return .white
            } else {
                return type == .primary ? VenusTheme.text : VenusTheme.textSecondary
            }
        }
    }
}

// MARK: - Calendar Month View
struct CalendarMonthView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let onSelect: (Date) -> Void
    var isOrangeTheme: Bool = false
    private let calendar = Calendar.current
    
    var days: [Date] {
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return [] }
        return range.compactMap { day -> Date? in
            calendar.date(bySetting: .day, value: day, of: currentMonth)
        }
    }
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text(currentMonth.formatted(.dateTime.month(.wide).year()))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(VenusTheme.text)
                Spacer()
                HStack(spacing: 16) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(VenusTheme.text)
                    }
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(VenusTheme.text)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 14) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day.prefix(1))
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(VenusTheme.textSecondary)
                }
                
                ForEach(days, id: \.self) { date in
                    Button(action: { onSelect(date) }) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 40, height: 40)
                            .background(
                                ZStack {
                                    if calendar.isDate(date, inSameDayAs: selectedDate) {
                                        Circle()
                                            .fill(Color(hex: "FF3D00"))
                                    }
                                }
                            )
                            .foregroundColor(
                                calendar.isDate(date, inSameDayAs: selectedDate) ? .white : VenusTheme.text
                            )
                    }
                }
            }
            .padding(20)
        }
    }
    
    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

// MARK: - Utilities
struct CustomCornerShape: Shape {
    var corners: UIRectCorner
    var radius: CGFloat
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview {
    TodoListView(viewModel: DependencyContainer.shared.makeTodoListViewModel())
}
