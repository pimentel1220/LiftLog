import SwiftUI

struct SettingsScreen: View {
    @EnvironmentObject private var store: LiftLogStore

    var body: some View {
        AppScreen(title: "Settings") {
            AppCard {
                Text("App")
                    .font(.headline)
                settingRow(title: "Storage", value: "Local on this device")
                settingRow(title: "Plan", value: store.tier.rawValue.capitalized)
                settingRow(title: "Cloud Sync", value: "Ready for v2")
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
}
