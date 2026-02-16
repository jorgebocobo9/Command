import SwiftUI

struct OnboardingView: View {
    @State private var currentPage = 0
    @State private var wakeTime = Calendar.current.date(from: DateComponents(hour: 7, minute: 0)) ?? Date()
    @State private var sleepTime = Calendar.current.date(from: DateComponents(hour: 23, minute: 0)) ?? Date()
    @State private var peakHours: PeakPreference = .morning

    let onComplete: () -> Void

    enum PeakPreference: String, CaseIterable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
    }

    var body: some View {
        ZStack {
            CommandColors.background.ignoresSafeArea()

            TabView(selection: $currentPage) {
                welcomePage.tag(0)
                energyPage.tag(1)
                classroomPage.tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(CommandAnimations.spring, value: currentPage)

            // Page indicator
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<3) { index in
                        Circle()
                            .fill(index == currentPage ? CommandColors.school : CommandColors.surfaceBorder)
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Welcome

    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "scope")
                .font(.system(size: 64, weight: .thin))
                .foregroundStyle(CommandColors.school)

            Text("Command")
                .font(.system(size: 40, weight: .bold))
                .foregroundStyle(CommandColors.textPrimary)

            Text("Your personal mission control for tasks, focus, and momentum.")
                .font(CommandTypography.body)
                .foregroundStyle(CommandColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            Button {
                withAnimation { currentPage = 1 }
            } label: {
                Text("Get Started")
                    .font(CommandTypography.headline)
                    .foregroundStyle(CommandColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CommandColors.school.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CommandColors.school.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Energy

    private var energyPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "bolt.fill")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(CommandColors.personal)

            Text("Your Energy Profile")
                .font(CommandTypography.title)
                .foregroundStyle(CommandColors.textPrimary)

            Text("Help Command schedule tasks when you're most productive.")
                .font(CommandTypography.body)
                .foregroundStyle(CommandColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            VStack(spacing: 16) {
                HStack {
                    Text("Wake time")
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textSecondary)
                    Spacer()
                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(CommandColors.school)
                }
                .padding(.horizontal, 20)

                HStack {
                    Text("Sleep time")
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textSecondary)
                    Spacer()
                    DatePicker("", selection: $sleepTime, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .tint(CommandColors.school)
                }
                .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Peak focus time")
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textSecondary)
                        .padding(.horizontal, 20)

                    HStack(spacing: 8) {
                        ForEach(PeakPreference.allCases, id: \.self) { pref in
                            Button {
                                withAnimation(CommandAnimations.springQuick) { peakHours = pref }
                            } label: {
                                Text(pref.rawValue)
                                    .font(CommandTypography.caption)
                                    .foregroundStyle(peakHours == pref ? CommandColors.textPrimary : CommandColors.textSecondary)
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 8)
                                    .background(peakHours == pref ? CommandColors.surfaceElevated : CommandColors.surface)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }

            Spacer()

            Button {
                withAnimation { currentPage = 2 }
            } label: {
                Text("Continue")
                    .font(CommandTypography.headline)
                    .foregroundStyle(CommandColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CommandColors.personal.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CommandColors.personal.opacity(0.4), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
        }
    }

    // MARK: - Classroom

    private var classroomPage: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "graduationcap.fill")
                .font(.system(size: 48, weight: .thin))
                .foregroundStyle(CommandColors.school)

            Text("Google Classroom")
                .font(CommandTypography.title)
                .foregroundStyle(CommandColors.textPrimary)

            Text("Connect to automatically import your courses and assignments.")
                .font(CommandTypography.body)
                .foregroundStyle(CommandColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            Spacer()

            VStack(spacing: 12) {
                Button {
                    // ClassroomService.authenticate() will be wired during integration
                    onComplete()
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("Connect Classroom")
                    }
                    .font(CommandTypography.headline)
                    .foregroundStyle(CommandColors.textPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(CommandColors.school.opacity(0.2))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(CommandColors.school.opacity(0.4), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)

                Button {
                    onComplete()
                } label: {
                    Text("Skip for now")
                        .font(CommandTypography.body)
                        .foregroundStyle(CommandColors.textTertiary)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 60)
        }
    }
}
