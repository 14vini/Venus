//
//  EditPlannedBlockSheet.swift
//  Venus
//
//  Created for Venus Daily Planning.
//

import SwiftUI

struct EditPlannedBlockSheet: View {
    @Environment(\.dismiss) private var dismiss

    let initialBlock: PlannedBlock?
    let onSave: (PlannedBlock) -> Void
    let onDelete: ((UUID) -> Void)?

    @State private var title: String
    @State private var category: BlockCategory
    @State private var priority: BlockPriority
    @State private var startTime: Date
    @State private var endTime: Date
    @State private var note: String
    @State private var errorMessage: String? = nil
    @State private var showingDeleteAlert: Bool = false

    init(
        initialBlock: PlannedBlock? = nil,
        onSave: @escaping (PlannedBlock) -> Void,
        onDelete: ((UUID) -> Void)? = nil
    ) {
        self.initialBlock = initialBlock
        self.onSave = onSave
        self.onDelete = onDelete

        let now = Date()
        let calendar = Calendar.current
        let defaultStart = initialBlock?.startTime ?? now
        let defaultEnd = initialBlock?.endTime ?? (calendar.date(byAdding: .minute, value: 45, to: defaultStart) ?? defaultStart.addingTimeInterval(45 * 60))

        _title = State(initialValue: initialBlock?.title ?? "")
        _category = State(initialValue: initialBlock?.category ?? .study)
        _priority = State(initialValue: initialBlock?.priority ?? .medium)
        _startTime = State(initialValue: defaultStart)
        _endTime = State(initialValue: defaultEnd)
        _note = State(initialValue: initialBlock?.note ?? "")
    }

    var isEditing: Bool {
        initialBlock != nil
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VenusTheme.background
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 22) {
                        if let error = errorMessage {
                            HStack(spacing: 8) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.orange)
                                Text(error)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
                                    .foregroundColor(VenusTheme.text)
                            }
                            .padding(12)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        sectionHeader("TÍTULO DO BLOCO")
                        TextField("Ex: Estudar Matemática, Treino, Reunião...", text: $title)
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(VenusTheme.text)
                            .padding(14)
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))

                        VStack(alignment: .leading, spacing: 10) {
                            sectionHeader("CATEGORIA")

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(BlockCategory.allCases, id: \.self) { cat in
                                    let isSelected = category == cat
                                    Button {
                                        category = cat
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    } label: {
                                        HStack(spacing: 10) {
                                            Image(systemName: cat.iconName)
                                                .font(.system(size: 14, weight: .semibold))
                                                .foregroundColor(cat.color)
                                                .frame(width: 22)

                                            Text(cat.displayName)
                                                .font(.system(size: 14, weight: isSelected ? .bold : .medium, design: .rounded))
                                                .foregroundColor(isSelected ? .white : VenusTheme.text)

                                            Spacer()

                                            if isSelected {
                                                Circle()
                                                    .fill(cat.color)
                                                    .frame(width: 7, height: 7)
                                            }
                                        }
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 12)
                                        .background(
                                            isSelected
                                                ? LinearGradient(
                                                    colors: [cat.color.opacity(0.75), cat.color.opacity(0.45)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    colors: [Color.clear, Color.clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        )
                                        .glassEffect(
                                            isSelected ? .clear : .regular.interactive(),
                                            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.84), value: isSelected)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader("HORÁRIOS")

                            VStack(spacing: 0) {
                                HStack {
                                    Label("Início", systemImage: "clock")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(VenusTheme.text)
                                    Spacer()
                                    DatePicker("", selection: $startTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .tint(VenusTheme.primary)
                                }
                                .padding(14)

                                Divider()
                                    .background(Color.white.opacity(0.08))

                                HStack {
                                    Label("Término", systemImage: "clock.badge.checkmark")
                                        .font(.system(size: 15, weight: .medium, design: .rounded))
                                        .foregroundColor(VenusTheme.text)
                                    Spacer()
                                    DatePicker("", selection: $endTime, displayedComponents: .hourAndMinute)
                                        .labelsHidden()
                                        .tint(VenusTheme.primary)
                                }
                                .padding(14)
                            }
                            .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("PRIORIDADE")

                            HStack(spacing: 10) {
                                ForEach(BlockPriority.allCases, id: \.self) { prio in
                                    let isSelected = priority == prio
                                    Button {
                                        priority = pririo(prio)
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    } label: {
                                        HStack(spacing: 6) {
                                            Circle()
                                                .fill(prioColor(prio))
                                                .frame(width: 8, height: 8)
                                            Text(prio.displayName)
                                                .font(.system(size: 13, weight: isSelected ? .bold : .medium, design: .rounded))
                                                .foregroundColor(isSelected ? .white : VenusTheme.textSecondary)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            isSelected
                                                ? LinearGradient(
                                                    colors: [prioColor(prio).opacity(0.7), prioColor(prio).opacity(0.4)],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                )
                                                : LinearGradient(
                                                    colors: [Color.clear, Color.clear],
                                                    startPoint: .topLeading,
                                                    endPoint: .bottomTrailing
                                                ),
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                        .glassEffect(
                                            isSelected ? .clear : .regular.interactive(),
                                            in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                    .animation(.spring(response: 0.3, dampingFraction: 0.84), value: isSelected)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            sectionHeader("OBSERVAÇÕES (OPCIONAL)")
                            TextField("Dica, objetivo ou lembrete gentil para este bloco...", text: $note)
                                .font(.system(size: 14, weight: .regular, design: .rounded))
                                .foregroundColor(VenusTheme.text)
                                .padding(14)
                                .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                        }

                        if isEditing, let onDelete = onDelete, let blockId = initialBlock?.id {
                            Button(role: .destructive) {
                                showingDeleteAlert = true
                            } label: {
                                HStack {
                                    Spacer()
                                    Image(systemName: "trash")
                                    Text("Excluir Bloco")
                                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    Spacer()
                                }
                                .foregroundColor(.red)
                                .padding(14)
                                .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 10)
                            .alert("Excluir Bloco", isPresented: $showingDeleteAlert) {
                                Button("Cancelar", role: .cancel) {}
                                Button("Excluir", role: .destructive) {
                                    onDelete(blockId)
                                    dismiss()
                                }
                            } message: {
                                Text("Tem certeza de que deseja remover este bloco da sua rotina?")
                            }
                        }

                        Spacer(minLength: 40)
                    }
                    .padding(20)
                }
            }
            .navigationTitle(isEditing ? "Editar Bloco" : "Novo Bloco")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(VenusTheme.textSecondary)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Salvar") {
                        saveBlock()
                    }
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .buttonStyle(.glassProminent)
                    .tint(VenusTheme.primary)
                }
            }
        }
    }

    // MARK: - Auxiliares

    @ViewBuilder
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 11, weight: .bold, design: .rounded))
            .foregroundColor(VenusTheme.textSecondary)
            .tracking(0.8)
    }

    private func pririo(_ p: BlockPriority) -> BlockPriority {
        p
    }

    private func prioColor(_ p: BlockPriority) -> Color {
        switch p {
        case .high: return .red
        case .medium: return .orange
        case .low: return .gray
        }
    }

    private func saveBlock() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedTitle.isEmpty else {
            errorMessage = "Por favor, informe o título do bloco."
            return
        }

        guard endTime > startTime else {
            errorMessage = "O horário de término deve ser após o horário de início."
            return
        }

        let block = PlannedBlock(
            id: initialBlock?.id ?? UUID(),
            title: trimmedTitle,
            category: category,
            startTime: startTime,
            endTime: endTime,
            priority: priority,
            status: initialBlock?.status ?? .planned,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : note.trimmingCharacters(in: .whitespacesAndNewlines),
            order: initialBlock?.order ?? 0
        )

        UINotificationFeedbackGenerator().notificationOccurred(.success)
        onSave(block)
        dismiss()
    }
}
