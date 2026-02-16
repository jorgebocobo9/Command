import SwiftUI
import SwiftData

struct FocusSessionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var viewModel = FocusViewModel()
    @State private var microStart: String?

    let mission: Mission
    var focusMinutes: Int = 25

    private let microStartGenerator = MicroStartGenerator(aiService: OnDeviceAIService())

    var body: some View {
        ZStack {
            CommandColors.background.ignoresSafeArea()

            switch viewModel.focusState {
            case .ready:
                readyView
            case .focusing, .paused:
                focusingView
            case .onBreak:
                BreakView(
                    breakDuration: viewModel.breakDuration,
                    cognitiveLoad: mission.cognitiveLoad,
                    onSkip: {
                        viewModel.endEarly(context: context)
                    },
                    onContinue: {
                        viewModel.continueAfterBreak()
                    }
                )
            case .completed:
                completedView
            }
        }
        .onAppear {
            viewModel.configure(mission: mission, minutes: focusMinutes)
        }
        .task {
            microStart = await microStartGenerator.generate(for: mission.title)
        }
    }

    // MARK: - Ready

    private var readyView: some View {
        VStack(spacing: 24) {
            Spacer()

            SectionHeader("FOCUS SESSION")

            Text(mission.title)
                .font(CommandTypography.title)
                .foregroundStyle(CommandColors.textPrimary)
                .multilineTextAlignment(.center)

            if let load = mission.cognitiveLoad {
                Text(load.rawValue.capitalized + " intensity")
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textSecondary)
            }

            if let microStart {
                VStack(spacing: 4) {
                    SectionHeader("MICRO-START")
                    Text(microStart)
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                }
            }

            FocusTimerView(
                totalSeconds: viewModel.totalSeconds,
                remainingSeconds: viewModel.remainingSeconds,
                accentColor: viewModel.accentColor,
                isPaused: false
            )
            .frame(width: 240, height: 240)
            .padding(.vertical, 20)

            Spacer()

            Button {
                Haptic.impact(.medium)
                viewModel.start(context: context)
            } label: {
                Text("Start Focus")
                    .font(CommandTypography.headline)
                    .foregroundStyle(CommandColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(viewModel.accentColor.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(viewModel.accentColor.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)

            Button {
                dismiss()
            } label: {
                Text("Cancel")
                    .font(CommandTypography.body)
                    .foregroundStyle(CommandColors.textTertiary)
            }
            .buttonStyle(.plain)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Focusing

    private var focusingView: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(mission.title)
                .font(CommandTypography.headline)
                .foregroundStyle(CommandColors.textSecondary)

            FocusTimerView(
                totalSeconds: viewModel.totalSeconds,
                remainingSeconds: viewModel.remainingSeconds,
                accentColor: viewModel.accentColor,
                isPaused: viewModel.focusState == .paused
            )
            .frame(width: 260, height: 260)

            // Current step
            if let nextStep = mission.steps.sorted(by: { $0.orderIndex < $1.orderIndex }).first(where: { !$0.isCompleted }) {
                VStack(spacing: 4) {
                    SectionHeader("CURRENT STEP")

                    Text(nextStep.title)
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textPrimary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }

            Spacer()

            HStack(spacing: 20) {
                // Break button
                Button {
                    viewModel.takeBreak()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "cup.and.saucer")
                            .font(.system(size: 20))
                        Text("Break")
                            .font(CommandTypography.caption)
                    }
                    .foregroundStyle(CommandColors.textSecondary)
                    .frame(width: 70, height: 60)
                    .background(CommandColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                // Pause/Resume
                Button {
                    if viewModel.focusState == .paused {
                        viewModel.resume()
                    } else {
                        viewModel.pause()
                    }
                } label: {
                    Image(systemName: viewModel.focusState == .paused ? "play.fill" : "pause.fill")
                        .font(.system(size: 28))
                        .foregroundStyle(CommandColors.textPrimary)
                        .frame(width: 70, height: 70)
                        .background(viewModel.accentColor.opacity(0.2))
                        .clipShape(Circle())
                        .overlay(
                            Circle().stroke(viewModel.accentColor.opacity(0.4), lineWidth: 1)
                        )
                }
                .buttonStyle(.plain)

                // End button
                Button {
                    viewModel.endEarly(context: context)
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20))
                        Text("End")
                            .font(CommandTypography.caption)
                    }
                    .foregroundStyle(CommandColors.textSecondary)
                    .frame(width: 70, height: 60)
                    .background(CommandColors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
            }
            .padding(.bottom, 40)
        }
    }

    // MARK: - Completed

    @State private var showCheckmark = false

    private var completedView: some View {
        VStack(spacing: 24) {
            Spacer()

            ZStack {
                Circle()
                    .fill(CommandColors.success.opacity(0.1))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showCheckmark ? 1 : 0.5)
                    .opacity(showCheckmark ? 1 : 0)

                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(CommandColors.success)
                    .scaleEffect(showCheckmark ? 1 : 0.3)
                    .opacity(showCheckmark ? 1 : 0)
            }
            .glow(CommandColors.success, radius: 20, intensity: showCheckmark ? 0.4 : 0)

            Text("Session Complete")
                .font(CommandTypography.title)
                .foregroundStyle(CommandColors.textPrimary)

            if viewModel.sessionsCompleted > 1 {
                Text("\(viewModel.sessionsCompleted) sessions today")
                    .font(CommandTypography.caption)
                    .foregroundStyle(CommandColors.textSecondary)
            }

            Spacer()

            VStack(spacing: 12) {
                Button {
                    viewModel.reset()
                    viewModel.configure(mission: mission, minutes: focusMinutes)
                    viewModel.start(context: context)
                } label: {
                    Text("Another Session")
                        .font(CommandTypography.headline)
                        .foregroundStyle(CommandColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(CommandColors.surfaceElevated)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
        .onAppear {
            Haptic.notification(.success)
            withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                showCheckmark = true
            }
        }
    }
}
