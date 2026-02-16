import SwiftUI
import SwiftData

struct IntelView: View {
    @Environment(\.modelContext) private var context
    @State private var viewModel = IntelViewModel()

    var body: some View {
        ZStack {
            CommandColors.background.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    VStack(alignment: .leading, spacing: 4) {
                        Text("INTEL")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundStyle(CommandColors.textPrimary)
                            .tracking(3)
                        Text("Your productivity analytics")
                            .font(CommandTypography.caption)
                            .foregroundStyle(CommandColors.textTertiary)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                    // Summary stats
                    summaryRow

                    if viewModel.totalMissionsCompleted == 0 && viewModel.totalFocusMinutes == 0 {
                        EmptyStateView(
                            icon: "chart.bar.xaxis.ascending",
                            title: "No data yet",
                            subtitle: "Complete missions and focus sessions to see your analytics here."
                        )
                        .padding(.top, 20)
                    } else {
                        // Heatmap
                        HeatmapView(profiles: viewModel.energyProfiles)
                            .padding(.horizontal, 16)

                        // Momentum
                        MomentumChartView(streaks: viewModel.streaks)
                            .padding(.horizontal, 16)

                        // Task DNA
                        TaskDNAChartView(missions: viewModel.completedMissions)
                            .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 20)
            }
            .scrollContentBackground(.hidden)
        }
        .task {
            viewModel.load(context: context)
        }
        .refreshable {
            viewModel.load(context: context)
        }
    }

    private var summaryRow: some View {
        HStack(spacing: 8) {
            statCard("Missions", value: "\(viewModel.totalMissionsCompleted)", color: CommandColors.school)
            statCard("Focus", value: "\(viewModel.totalFocusMinutes)m", color: CommandColors.personal)
            statCard("Streak", value: "\(longestStreak)d", color: CommandColors.warning)
        }
        .padding(.horizontal, 16)
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
        .padding(.vertical, 14)
        .background(CommandColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(CommandColors.surfaceBorder, lineWidth: 0.5)
        )
    }
}
