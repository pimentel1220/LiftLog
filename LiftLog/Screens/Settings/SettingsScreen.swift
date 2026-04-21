import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: LiftLogStore
    @EnvironmentObject private var premiumManager: PremiumManager

    var body: some View {
        AppScreen(title: "Settings") {
            AppCard {
                Text("App")
                    .font(.headline)
                settingRow(title: "Storage", value: "Local on this device")
                settingRow(title: "Weight Unit", value: store.weightUnit.title)
                settingRow(title: "Plan", value: premiumManager.unlockType.displayName)
                settingRow(title: "Cloud Sync", value: "Ready for v2")
            }

            AppCard {
                Text("Premium")
                    .font(.headline)
                Text("Beta testers automatically keep Premium on TestFlight builds. Future purchases and ad-based unlocks can plug into the same premium manager without replacing this reward.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                settingRow(title: "Access", value: premiumManager.hasPremiumAccess() ? "Unlocked" : "Free")
                settingRow(title: "Unlock Type", value: premiumManager.unlockType.displayName)
            }

            AppCard {
                Text("Weight Units")
                    .font(.headline)
                Text("Choose how weights appear throughout LiftLog. Your saved data stays correct and converts automatically.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Picker("Weight Unit", selection: Binding(
                    get: { store.weightUnit },
                    set: { store.setWeightUnit($0) }
                )) {
                    ForEach(WeightUnit.allCases) { unit in
                        Text(unit.title).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

            AppCard {
                Text("PR Sync")
                    .font(.headline)
                Text("When this is on, finishing a workout can update an existing PR if a logged set beats that PR weight.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                Toggle(isOn: Binding(
                    get: { store.syncPRsWithWorkoutsEnabled },
                    set: { store.setSyncPRsWithWorkouts($0) }
                )) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sync PRs with workouts")
                        Text("Off by default so manual PR tracking stays separate unless you want automatic updates.")
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                }
                .tint(AppTheme.accent)
            }

            AppCard {
                Text("Sample Data")
                    .font(.headline)
                Text("Reset the app back to starter exercises and example workouts for testing.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                SecondaryActionButton(title: "Reload Sample Data", systemImage: "arrow.counterclockwise") {
                    store.resetWithSampleData()
                }
            }

            AppCard {
                Text("What’s next")
                    .font(.headline)
                Text("The codebase is organized so premium upgrades, templates, and sync can plug in later without rewriting the app.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            AppCard {
                Text("Beta Feedback")
                    .font(.headline)
                Text("If something feels broken, confusing, or just off during a workout, send yourself a quick report and forward it to me. Including the app version helps me fix issues faster.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)

                settingRow(title: "App Version", value: appVersionLabel)

                ShareLink(item: bugReportTemplate) {
                    HStack {
                        Image(systemName: "ladybug.fill")
                        Text("Share Bug or Issue")
                            .fontWeight(.semibold)
                        Spacer()
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(AppTheme.cardSecondary)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func settingRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(value)
                .foregroundStyle(AppTheme.textSecondary)
        }
    }

    private var appVersionLabel: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
        return "\(version) (\(build))"
    }

    private var bugReportTemplate: String {
        """
        LiftLog Beta Bug or Issue Report

        App Version: \(appVersionLabel)
        Device: \(deviceModel)
        iOS: \(operatingSystemVersion)

        What happened:

        What I expected:

        Steps to reproduce:

        Notes:
        """
    }

    private var deviceModel: String {
        UIDevice.current.model
    }

    private var operatingSystemVersion: String {
        UIDevice.current.systemVersion
    }
}
