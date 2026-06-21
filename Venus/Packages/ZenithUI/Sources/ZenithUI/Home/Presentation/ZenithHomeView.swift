import SwiftUI

struct ZenithHomeView: View {
    let userName: String
    @ObservedObject var viewModel: ZenithHomeViewModel

    var body: some View {
        ZStack {
            VenusReadingBackground(
                accent: VenusTheme.ambientCool,
                secondaryAccent: VenusTheme.accentBlue,
                tertiaryAccent: VenusTheme.ambientRose
            )

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 28) {
                    ZenithHeroSection(
                        userName: userName,
                        title: viewModel.greetingTitle,
                        subtitle: viewModel.greetingSubtitle
                    )

                    ZenithEnergyCheckInSection(
                        latestCheckIn: viewModel.latestCheckIn,
                        onSelectLevel: viewModel.selectEnergyLevel
                    )

                    ZenithSentinelInsightSection(
                        insight: viewModel.currentInsight,
                        trigger: viewModel.activeTrigger
                    )

                    ZenithDebugActionsSection(
                        onStuckTap: viewModel.registerStuckMoment,
                        onRecoveryTap: viewModel.registerRecoveryMoment,
                        onWeeklySweepTap: viewModel.runWeeklySweepPreview
                    )

                    ZenithSentinelLogSection(events: viewModel.debugEvents)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)
                .padding(.bottom, 120)
            }
        }
        .navigationTitle("Zenith")
        .navigationBarTitleDisplayMode(.inline)
    }
}

