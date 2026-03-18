//
//  TodoListView.swift
//  Venus
//
//  Created by Kaua on 14/12/25.
//

import SwiftUI

private enum TodoScreenPalette {
    static let background = VenusTheme.background
    static let cardBackground = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark
            ? UIColor(hex: "1F1611", alpha: 0.92)
            : UIColor(hex: "FFF9F5", alpha: 0.92)
    })
    static let cardStroke = VenusTheme.cardBorder
    static let title = VenusTheme.text
    static let subtitle = VenusTheme.textSecondary
    static let accent = VenusTheme.accentOrange
    static let accentStrong = Color(UIColor { trait in
        trait.userInterfaceStyle == .dark ? UIColor(hex: "FF9A58") : UIColor(hex: "FF6424")
    })
    static let progress = VenusTheme.accentOrange
}

private enum TodoLayout {
    static let horizontalPadding: CGFloat = 22
    static let sectionSpacing: CGFloat = 26
    static let contentTopPadding: CGFloat = 8
    static let contentBottomPadding: CGFloat = 150
    static let quickActionWidth: CGFloat = 136
    static let quickActionHeight: CGFloat = 132
}

struct TodoListView: View {
    @Environment(\.colorScheme) private var colorScheme

    @StateObject private var viewModel: TodoListViewModel
    @State private var showBreathingView = false
    @State private var showPomodoroView = false
    @State private var showGratitudeView = false
    @State private var showCalendarSheet = false
    @State private var showCompletedSection = true

    init(viewModel: TodoListViewModel) {
        _viewModel = StateObject(wrappedValue: viewModel)
    }

    var incompleteTasks: [TodoItem] {
        viewModel.todos
            .filter { !$0.isCompleted }
            .sorted(by: sortTodos)
    }

    var completedTasks: [TodoItem] {
        viewModel.todos
            .filter { $0.isCompleted }
            .sorted(by: sortTodos)
    }

    var completionProgress: Double {
        guard !viewModel.todos.isEmpty else { return 0 }
        return Double(completedTasks.count) / Double(viewModel.todos.count)
    }

    var body: some View {
        ZStack {
            VenusTheme.backgroundGradient
                .ignoresSafeArea()

            Circle()
                .fill(VenusTheme.ambientWarm.opacity(colorScheme == .dark ? 0.32 : 0.24))
                .frame(width: 320, height: 320)
                .blur(radius: 62)
                .offset(x: -140, y: -270)

            Circle()
                .fill(TodoScreenPalette.accentStrong.opacity(colorScheme == .dark ? 0.24 : 0.17))
                .frame(width: 290, height: 290)
                .blur(radius: 56)
                .offset(x: 180, y: -10)

            Circle()
                .fill(VenusTheme.ambientCool.opacity(colorScheme == .dark ? 0.18 : 0.12))
                .frame(width: 240, height: 240)
                .blur(radius: 48)
                .offset(x: -30, y: 300)

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: TodoLayout.sectionSpacing) {
                    headerSection
                    progressSection
                    quickActionsSection
                    tasksSection
                }
                .padding(.horizontal, TodoLayout.horizontalPadding)
                .padding(.top, TodoLayout.contentTopPadding)
            }
            .scrollClipDisabled()
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: TodoLayout.contentBottomPadding)
            }
        }
        .safeAreaInset(edge: .bottom, alignment: .trailing) {
            addButton
                .padding(.trailing, TodoLayout.horizontalPadding)
                .padding(.bottom, 12)
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
                        }
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
    }

    private var headerSection: some View {
        VStack(spacing: 24) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Hoje")
                        .font(.system(size: 50, weight: .heavy, design: .rounded))
                        .foregroundColor(TodoScreenPalette.accentStrong)

                    HStack(spacing: 10) {
                        Text(headerDateText)
                            .font(.system(size: 17, weight: .semibold, design: .rounded))
                            .foregroundColor(TodoScreenPalette.title)
                    }
                }

                Spacer()

                Button {
                    showCalendarSheet = true
                } label: {
                    Image(systemName: "calendar")
                        .font(.system(size: 24))
                        .foregroundColor(TodoScreenPalette.accentStrong)
                        .padding(10)
                        .glassEffect(.clear.interactive())
                }
                .buttonStyle(.plain)
                .padding(.top, 10)
            }

            ScrollViewReader { proxy in
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        Color.clear.frame(width: 2)
                        ForEach(viewModel.currentWeek, id: \.self) { date in
                            TodoWeekdayItem(
                                date: date,
                                isSelected: viewModel.isSameDay(date1: date, date2: viewModel.selectedDate)
                            ) {
                                withAnimation(.spring(response: 0.35, dampingFraction: 0.80)) {
                                    viewModel.selectedDate = date
                                }
                            }
                            .id(date)
                        }
                        Color.clear.frame(width: 2)
                    }
                }
                .scrollClipDisabled()
                .onAppear {
                    proxy.scrollTo(viewModel.selectedDate, anchor: .center)
                }
                .onChange(of: viewModel.selectedDate) { _, newDate in
                    withAnimation(.easeInOut(duration: 0.25)) {
                        proxy.scrollTo(newDate, anchor: .center)
                    }
                }
            }
        }
    }

    private var progressSection: some View {
        HStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("SEU PROGRESSO")
                    .font(.system(size: 13, weight: .black, design: .rounded))
                    .foregroundColor(TodoScreenPalette.subtitle)
                    .tracking(1.5)

                Text("\(completedTasks.count) / \(viewModel.todos.count)")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(TodoScreenPalette.title)

                Text("tarefas concluídas")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(TodoScreenPalette.subtitle)
            }

            Spacer(minLength: 4)

            TodoCircularProgressView(progress: completionProgress)

        }
        .padding(.horizontal, 24)
        .padding(.vertical)
//        .glassEffect(.clear, in: .rect(cornerRadius: 36))
//        .glassEffectTransition(.materialize)
        .background(
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 36, style: .continuous)
                    .fill(TodoScreenPalette.cardBackground)
            }
            .clipShape(RoundedRectangle(cornerRadius: 36, style: .continuous))
        )

        .shadow(color: Color.black.opacity(0.1), radius: 18, x: 0, y: 8)
    }

    private var quickActionsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Acesso Rápido")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(TodoScreenPalette.title)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    TodoQuickActionCard(
                        title: "Respiração",
                        icon: "leaf.fill",
                        iconColor: Color(hex: "3B82F6"),
                        backgroundColor: Color(hex: "DDEBFF")
                    ) { showBreathingView = true }

                    TodoQuickActionCard(
                        title: "Foco",
                        icon: "timer",
                        iconColor: Color(hex: "F97316"),
                        backgroundColor: Color(hex: "FFE7CC")
                    ) { showPomodoroView = true }

                    TodoQuickActionCard(
                        title: "Gratidão",
                        icon: "heart.fill",
                        iconColor: Color(hex: "EC4899"),
                        backgroundColor: Color(hex: "FCE3F0")
                    ) { showGratitudeView = true }
                }
                .padding(.vertical, 2)
            }
            .scrollClipDisabled()
        }
    }

    private var tasksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Tarefas")
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(TodoScreenPalette.title)

                Spacer()

                if !incompleteTasks.isEmpty {
                    Text("\(incompleteTasks.count) pendentes")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(TodoScreenPalette.subtitle)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.black.opacity(0.06))
                        )
                } else {
                    Button {
                        showCalendarSheet = true
                    } label: {
                        Text("Ver tudo")
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(TodoScreenPalette.accentStrong)
                    }
                    .buttonStyle(.plain)
                }
            }

            if viewModel.todos.isEmpty {
                VStack(spacing: 10) {
                    Text("Nenhuma tarefa")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(TodoScreenPalette.title)
                    Text("Toque no botão + para criar a primeira tarefa do dia.")
                        .font(.system(size: 15, weight: .medium, design: .rounded))
                        .foregroundColor(TodoScreenPalette.subtitle)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 44)
                .background(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .fill(TodoScreenPalette.cardBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 28, style: .continuous)
                        .stroke(TodoScreenPalette.cardStroke, lineWidth: 1)
                )
                .onTapGesture {
                    viewModel.showAddSheet = true
                }
            } else {
                LazyVStack(spacing: 12) {
                    if !incompleteTasks.isEmpty {
                        ForEach(incompleteTasks) { item in
                            EnhancedTodoItemView(
                                item: item,
                                onToggle: {
                                    withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                                        viewModel.toggleTodo(id: item.id)
                                    }
                                }
                            )
                            .transition(.opacity.combined(with: .scale(scale: 0.98)))
                        }
                    }

                    if !completedTasks.isEmpty {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                showCompletedSection.toggle()
                            }
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(TodoScreenPalette.subtitle)
                                Text("Concluídas (\(completedTasks.count))")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(TodoScreenPalette.subtitle)
                                Spacer()
                                Image(systemName: showCompletedSection ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(TodoScreenPalette.subtitle)
                            }
                            .padding(.horizontal, 4)
                            .padding(.top, 8)
                        }
                        .buttonStyle(.plain)

                        if showCompletedSection {
                            ForEach(completedTasks) { item in
                                EnhancedTodoItemView(
                                    item: item,
                                    onToggle: {
                                        withAnimation(.spring(response: 0.30, dampingFraction: 0.82)) {
                                            viewModel.toggleTodo(id: item.id)
                                        }
                                    }
                                )
                                .transition(.opacity.combined(with: .scale(scale: 0.98)))
                            }
                        }
                    }
                }
                .animation(.spring(response: 0.30, dampingFraction: 0.82), value: viewModel.todos)
                .animation(.easeInOut(duration: 0.20), value: showCompletedSection)
            }
        }
    }

    private var addButton: some View {
        Button {
            viewModel.showAddSheet = true
        } label: {
            ZStack {
                Circle()
                    .fill(TodoScreenPalette.accentStrong.opacity(0.42))
                    .frame(width: 74, height: 74)
                    .blur(radius: 12)

                Circle()
                    .fill(
                        LinearGradient(
                            colors: [TodoScreenPalette.accent, TodoScreenPalette.accentStrong],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 74, height: 74)

                Image(systemName: "plus")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Adicionar tarefa")
    }

    private var headerDateText: String {
        let locale = Locale(identifier: "pt_BR")
        let day = Calendar.current.component(.day, from: viewModel.selectedDate)
        let formatter = DateFormatter()
        formatter.locale = locale
        formatter.dateFormat = "MMMM"
        let month = formatter.string(from: viewModel.selectedDate).capitalized(with: locale)
        return "\(day) de \(month)"
    }

    private func sortTodos(_ lhs: TodoItem, _ rhs: TodoItem) -> Bool {
        switch (lhs.time, rhs.time) {
        case let (left?, right?):
            if left != right {
                return left < right
            }
        case (_?, nil):
            return true
        case (nil, _?):
            return false
        case (nil, nil):
            break
        }
        return lhs.title.localizedCaseInsensitiveCompare(rhs.title) == .orderedAscending
    }
}

struct TodoCircularProgressView: View {
    let progress: Double

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "D7D6DB"), lineWidth: 6)
                .frame(width: 64, height: 64)

            Circle()
                .trim(from: 0, to: max(0.04, progress))
                .stroke(
                    TodoScreenPalette.progress,
                    style: StrokeStyle(lineWidth: 6, lineCap: .round)
                )
                .frame(width: 64, height: 64)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.45, dampingFraction: 0.78), value: progress)

            Text("\(Int((progress * 100).rounded()))%")
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(TodoScreenPalette.progress)
        }
    }
}

struct TodoQuickActionCard: View {
    let title: String
    let icon: String
    let iconColor: Color
    let backgroundColor: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 14) {
                Circle()
                    .fill(backgroundColor)
                    .frame(width: 62, height: 62)
                    .overlay(
                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(iconColor)
                    )

                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(TodoScreenPalette.title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.85)
            }
        }
        .buttonStyle(.plain)
        .frame(width: TodoLayout.quickActionWidth, height: TodoLayout.quickActionHeight)
//        .glassEffect(.clear, in: .rect(cornerRadius: 36))
//        .glassEffectTransition(.materialize)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(TodoScreenPalette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(TodoScreenPalette.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
    }
}

struct EnhancedTodoItemView: View {
    let item: TodoItem
    let onToggle: () -> Void

    private var meta: TodoTaskMeta {
        TodoTaskMeta(from: item)
    }

    var body: some View {
        HStack(spacing: 14) {
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .strokeBorder(item.isCompleted ? Color.clear : Color(hex: "C8CDD5"), lineWidth: 2.8)
                        .background(
                            Circle()
                                .fill(item.isCompleted ? Color(hex: "B5BAC5") : .clear)
                        )
                        .frame(width: 40, height: 40)

                    if item.isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 8) {
                Text(item.title)
                    .font(.system(size: 17, weight: .semibold, design: .rounded))
                    .foregroundColor(TodoScreenPalette.title)
                    .strikethrough(item.isCompleted, color: TodoScreenPalette.subtitle)
                    .lineLimit(2)

                HStack(spacing: 9) {
                    Circle()
                        .fill(meta.dotColor)
                        .frame(width: 10, height: 10)

                    Text(meta.category)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(TodoScreenPalette.subtitle)

                    Text("•")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(TodoScreenPalette.subtitle.opacity(0.75))

                    Text(meta.context)
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(TodoScreenPalette.subtitle)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 6)

            if let time = item.time {
                Text(time.formatted(date: .omitted, time: .shortened))
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(item.isCompleted ? Color(hex: "9EA5B1") : meta.timeTextColor)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(item.isCompleted ? Color(hex: "F1F1F4") : meta.timeBackground)
                    )
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 17)
        .background(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(TodoScreenPalette.cardBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(TodoScreenPalette.cardStroke, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 9, x: 0, y: 4)
        .opacity(item.isCompleted ? 0.66 : 1)
        .contentShape(RoundedRectangle(cornerRadius: 30, style: .continuous))
        .glassEffect(.clear.interactive(), in: .rect(cornerRadius: 30))
        .glassEffectTransition(.materialize)
    }
}

private struct TodoTaskMeta {
    let category: String
    let context: String
    let dotColor: Color
    let timeBackground: Color
    let timeTextColor: Color

    init(from item: TodoItem) {
        category = item.type.rawValue

        if item.isSystemGenerated {
            context = "Bloco automático"
            dotColor = Color(hex: "64748B")
            timeBackground = Color(hex: "E9EEF5")
            timeTextColor = Color(hex: "475569")
            return
        }

        switch item.type {
        case .work:
            context = "Venus Inc."
            dotColor = Color(hex: "3B82F6")
            timeBackground = Color(hex: "FFE7DC")
            timeTextColor = Color(hex: "F97316")
        case .health:
            context = "Parque da Cidade"
            dotColor = Color(hex: "22C55E")
            timeBackground = Color(hex: "DCFCE7")
            timeTextColor = Color(hex: "16A34A")
        case .study:
            context = "Plano de Estudos"
            dotColor = Color(hex: "8B5CF6")
            timeBackground = Color(hex: "EDE9FE")
            timeTextColor = Color(hex: "7C3AED")
        case .routine:
            context = "Rotina diária"
            dotColor = Color(hex: "A855F7")
            timeBackground = Color(hex: "F5E8FF")
            timeTextColor = Color(hex: "A855F7")
        case .task:
            context = "Pessoal"
            dotColor = Color(hex: "64748B")
            timeBackground = Color(hex: "E9EEF5")
            timeTextColor = Color(hex: "475569")
        }
    }
}

struct TodoWeekdayItem: View {
    let date: Date
    let isSelected: Bool
    let onTap: () -> Void

    private var weekdayLabel: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "pt_BR")
        formatter.dateFormat = "EEE"
        let raw = formatter.string(from: date)
            .replacingOccurrences(of: ".", with: "")
            .uppercased()
        return String(raw.prefix(3))
    }

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                Text(weekdayLabel)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? TodoScreenPalette.accentStrong : TodoScreenPalette.subtitle.opacity(0.65))
                    .tracking(0.7)

                ZStack {
                    if isSelected {
                        Circle()
                            .fill(TodoScreenPalette.accentStrong)
                            .frame(width: 64, height: 64)
                            .shadow(color: TodoScreenPalette.accentStrong.opacity(0.24), radius: 16, x: 0, y: 8)
                    }

                    Text("\(Calendar.current.component(.day, from: date))")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(isSelected ? .white : TodoScreenPalette.title.opacity(0.78))
                }
                .frame(width: 54, height: 54)
            }
        }
        .buttonStyle(.plain)
    }
}

struct CalendarMonthView: View {
    @Binding var currentMonth: Date
    @Binding var selectedDate: Date
    let onSelect: (Date) -> Void

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
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(TodoScreenPalette.title)

                Spacer()

                HStack(spacing: 16) {
                    Button(action: { changeMonth(by: -1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(TodoScreenPalette.title)
                    }
                    Button(action: { changeMonth(by: 1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(TodoScreenPalette.title)
                    }
                }
            }
            .padding(.horizontal, 6)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 14) {
                ForEach(calendar.shortWeekdaySymbols, id: \.self) { day in
                    Text(day.prefix(1))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(TodoScreenPalette.subtitle)
                }
                
                ForEach(days, id: \.self) { date in
                    Button(action: { onSelect(date) }) {
                        Text("\(calendar.component(.day, from: date))")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(calendar.isDate(date, inSameDayAs: selectedDate) ? TodoScreenPalette.accentStrong : .clear)
                            )
                            .foregroundColor(
                                calendar.isDate(date, inSameDayAs: selectedDate) ? .white : TodoScreenPalette.title
                            )
                    }
                }
            }
            
            .padding(.top, 4)
        }
        .padding(20)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: currentMonth) {
            currentMonth = newMonth
        }
    }
}

#Preview {
    TodoListView(viewModel: DependencyContainer.shared.makeTodoListViewModel())
}
