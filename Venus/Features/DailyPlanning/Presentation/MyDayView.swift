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
    
    init(viewModel: MyDayViewModel? = nil) {
        _viewModel = State(initialValue: viewModel ?? MyDayViewModel())
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                VenusReadingBackground(dayMoment: .current, isAnimated: true)
                
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // Venus Daily Focus Banner
                        dailyFocusBanner
                        
                        if let plan = viewModel.currentPlan, !plan.blocks.isEmpty {
                            // Top 3 Priorities
                            if !viewModel.topPriorities.isEmpty {
                                MyDayPrioritiesView(
                                    priorities: viewModel.topPriorities,
                                    onComplete: { blockId in
                                        viewModel.completeBlock(id: blockId)
                                    }
                                )
                            }
                            
                            // Timeline Section Header & Progress
                            HStack {
                                Label("Linha do Tempo", systemImage: "clock.fill")
                                    .font(.system(size: 16, weight: .bold, design: .rounded))
                                    .foregroundColor(VenusTheme.text)
                                
                                Spacer()
                                
                                Text("\(viewModel.completedCount) de \(viewModel.totalCount) feitos")
                                    .font(.system(size: 12, weight: .medium, design: .rounded))
                                    .foregroundColor(VenusTheme.primary)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(VenusTheme.primary.opacity(0.12), in: Capsule())
                            }
                            .padding(.top, 6)
                            
                            // Timeline of Blocks
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
                                
                                // Manual Add Block button in timeline
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
                                    .padding(.vertical, 12)
                                    .background(VenusTheme.cardSurface)
                                    .cornerRadius(14)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 14)
                                            .strokeBorder(VenusTheme.primary.opacity(0.3), style: StrokeStyle(lineWidth: 1.2, dash: [5]))
                                    )
                                }
                                .buttonStyle(.plain)
                                .padding(.top, 4)
                            }
                            
                            // Reorganize Button
                            reorganizeButton
                                .padding(.top, 8)
                                .padding(.bottom, 60)
                            
                        } else {
                            // Empty State
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
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 10)
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
                    HStack(spacing: 14) {
                        // Button to add block manually
                        Button {
                            viewModel.startCreatingBlock()
                        } label: {
                            Image(systemName: "plus")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundStyle(VenusTheme.text)
                        }
                        
                        // Button to chat with Venus
                        Button {
                            viewModel.openPlanChat()
                        } label: {
                            Image(systemName: "sparkles")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundStyle(VenusTheme.primary)
                        }
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
            }
        }
    }
    
    // MARK: - Subviews
    
    private var dailyFocusBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("FOCO DO DIA")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(VenusTheme.primary)
                    .tracking(1.2)
                
                Spacer()
                
                if let score = viewModel.readinessAssessment?.score {
                    HStack(spacing: 4) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 10))
                        Text(String(format: "%.1f", score))
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                    }
                    .foregroundColor(VenusTheme.primary)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(VenusTheme.primary.opacity(0.12), in: Capsule())
                }
            }
            
            Text(viewModel.focusQuote)
                .font(.system(size: 15, weight: .medium, design: .serif))
                .foregroundColor(VenusTheme.text)
                .lineSpacing(3)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(VenusTheme.cardSurface)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.06), lineWidth: 1)
        )
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
            .padding(.vertical, 13)
            .background(VenusTheme.surface)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
