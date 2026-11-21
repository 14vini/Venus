//
//  MyDayView.swift
//  Venus
//
//  Created for Venus Daily Planning MVP.
//

import SwiftUI

struct MyDayView: View {
    @State private var viewModel: MyDayViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var contentAppeared = false

    init(viewModel: MyDayViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? MyDayViewModel())
    }

    var body: some View {
        NavigationStack {
            ZStack {
                VenusReadingBackground(dayMoment: .current, isAnimated: true)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        dailyFocusBanner
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 14)

                        if let plan = viewModel.currentPlan, !plan.blocks.isEmpty {
                            if !viewModel.topPriorities.isEmpty {
                                MyDayPrioritiesView(
                                    priorities: viewModel.topPriorities,
                                    onComplete: { blockId in
                                        viewModel.completeBlock(id: blockId)
                                    }
                                )
                                .opacity(contentAppeared ? 1 : 0)
                                .offset(y: contentAppeared ? 0 : 16)
                            }

                            timelineHeader
                                .opacity(contentAppeared ? 1 : 0)

                            VStack(spacing: 12) {
                                ForEach(viewModel.timelineBlocks) { block in
                                    PlannedBlockCardView(
                                        block: block,
                                        onStart: {
                                            viewModel.startBlock(id: block.id)
                                        },
                                        onComplete: {
                                            viewModel.completeBlock(id: block.id)
                                        },
                                        onSkip: {
                                            viewModel.skipBlock(id: block.id)
                                        },
                                        onReset: {
                                            viewModel.resetBlock(id: block.id)
                                        },
                                        onEdit: {
                                            viewModel.editBlock(block)
                                        },
                                        onDelete: {
                                            viewModel.deleteBlock(id: block.id)
                                        }
                                    )
                                }

                                Button {
                                    viewModel.startCreatingBlock()
                                } label: {
                                    HStack(spacing: 8) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 15, weight: .bold))
                                        Text("Adicionar bloco à rotina")
                                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                                    }
                                    .foregroundColor(VenusTheme.primary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 13)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                                            .strokeBorder(
                                                VenusTheme.primary.opacity(0.35),
                                                style: StrokeStyle(lineWidth: 1.2, dash: [5])
                                            )
                                    )
                                    .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }

                            reorganizeButton
                                .padding(.top, 8)
                                .padding(.bottom, 60)
                                .opacity(contentAppeared ? 1 : 0)
                                .offset(y: contentAppeared ? 0 : 12)
                        } else {
                            MyDayEmptyStateView(
                                onPlanWithVenus: {
                                    viewModel.openPlanChat()
                                },
                                onManualCreate: {
                                    viewModel.startCreatingBlock()
                                }
                            )
                            .padding(.top, 10)
                            .padding(.bottom, 60)
                            .opacity(contentAppeared ? 1 : 0)
                            .offset(y: contentAppeared ? 0 : 18)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
                    .animation(.spring(response: 0.6, dampingFraction: 0.86).delay(0.05), value: contentAppeared)
                }
            }
            .navigationTitle("Meu dia")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(VenusTheme.text)
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 10) {
                        Button {
                            viewModel.startCreatingBlock()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .bold))
                        }
                        .buttonStyle(.glass)

                        Button {
                            viewModel.openPlanChat()
                        } label: {
                            Image(systemName: "sparkles")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(VenusTheme.primary)
                        }
                        .buttonStyle(.glass)
                    }
                }
            }
            .sheet(isPresented: $viewModel.showingAddBlockSheet) {
                EditPlannedBlockSheet(
                    initialBlock: viewModel.blockToEdit,
                    onSave: { savedBlock in
                        viewModel.saveManualBlock(savedBlock)
                    },
                    onDelete: { blockId in
                        viewModel.deleteBlock(id: blockId)
                    }
                )
            }
            .sheet(isPresented: $viewModel.showVenusChat) {
                NavigationStack {
                    VenusChatView(openedForPlanning: true, initialPrompt: viewModel.chatInitialPrompt)
                }
            }
            .onAppear {
                viewModel.onAppear()
                withAnimation(.spring(response: 0.6, dampingFraction: 0.86)) {
                    contentAppeared = true
                }
            }
        }
    }

    // MARK: - Subviews

    private var dailyFocusBanner: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("FOCO DO DIA")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.primary)
                    .tracking(1.3)

                Spacer()

                if let score = viewModel.readinessAssessment?.score {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", score))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(VenusTheme.primary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .glassEffect(.regular, in: Capsule(style: .continuous))
                }
            }

            Text(viewModel.focusQuote)
                .font(.system(size: 16, weight: .light, design: .rounded))
                .foregroundColor(VenusTheme.text)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }

    private var timelineHeader: some View {
        HStack {
            Label("Linha do Tempo", systemImage: "clock.fill")
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(VenusTheme.text)

            Spacer()

            Text("\(viewModel.completedCount) de \(viewModel.totalCount) feitos")
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundColor(VenusTheme.primary)
                .padding(.horizontal, 11)
                .padding(.vertical, 5)
                .glassEffect(.regular, in: Capsule(style: .continuous))
        }
        .padding(.top, 6)
    }

    private var reorganizeButton: some View {
        Button {
            viewModel.openReorganizeChat()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.system(size: 13, weight: .bold))
                Text("Reorganizar o resto do dia")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
            }
            .foregroundColor(VenusTheme.text)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .glassEffect(.regular.interactive(), in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
