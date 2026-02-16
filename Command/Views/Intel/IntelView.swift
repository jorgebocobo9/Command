import SwiftUI
import SwiftData

struct IntelView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = IntelViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Summary stats
                    summaryRow

                    // Heatmap
                    HeatmapView(profiles: viewModel.energyProfiles)
                        .padding(.horizontal)

                    // Momentum
                    MomentumChartView(streaks: viewModel.streaks)
                        .padding(.horizontal)

                    // Task DNA
                    TaskDNAChartView(missions: viewModel.completedMissions)
                        .padding(.horizontal)
                }
                .padding(.bottom, 20)
            }
            .background(CommandColors.background)
            .navigationTitle("Intel")
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                viewModel.load(context: context)
            }
            .refreshable {
                viewModel.load(context: context)
            }
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 0) {
            statCard("Missions", value: "\(viewModel.totalMissionsCompleted)", color: CommandColors.school)
            statCard("Focus", value: "\(viewModel.totalFocusMinutes)m", color: CommandColors.personal)
            statCard("Streak", value: "\(longestStreak)d", color: CommandColors.warning)
        }
        .padding(.horizontal)
    }

    private var longestStreak: Int {
        viewModel.streaks.first(where: { $0.category == .overall })?.currentCount ?? 0
    }

    private func statCard(_ title: String, value: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(CommandTypography.title)
                .foregroundStyle(color)
            Text(title)
                .font(CommandTypography.caption)
                .foregroundStyle(CommandColors.textTertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
