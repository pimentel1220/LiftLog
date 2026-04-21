import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var store: LiftLogStore
    @EnvironmentObject private var premiumManager: PremiumManager
    @State private var isWorkoutPresented = false

    var body: some View {
        TabView {
            NavigationStack {
                HomeScreen()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationStack {
                ExercisesScreen()
            }
            .tabItem {
                Label("Exercises", systemImage: "dumbbell.fill")
            }

            NavigationStack {
                HistoryScreen()
            }
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }

            NavigationStack {
                PRScreen()
            }
            .tabItem {
                Label("PRs", systemImage: "trophy.fill")
            }

            NavigationStack {
                ProgressScreen()
            }
            .tabItem {
                Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
            }
        }
        .tint(AppTheme.accent)
        .fullScreenCover(isPresented: $isWorkoutPresented) {
            NavigationStack {
                ActiveWorkoutScreen()
            }
        }
        .onAppear {
            isWorkoutPresented = store.hasActiveWorkout && store.shouldPresentActiveWorkout
        }
        .onChange(of: store.shouldPresentActiveWorkout) { _, shouldPresent in
            if shouldPresent && store.hasActiveWorkout {
                isWorkoutPresented = true
            }
        }
        .onChange(of: isWorkoutPresented) { _, isPresented in
            if !isPresented, store.activeWorkout?.exerciseLogs.isEmpty == true {
                store.discardActiveWorkout()
            } else if !isPresented {
                store.shouldPresentActiveWorkout = false
            }
        }
        .alert("Premium unlocked", isPresented: $premiumManager.shouldShowBetaRewardMessage) {
            Button("Nice") {
                premiumManager.markBetaRewardMessageShown()
            }
        } message: {
            Text("Thanks for being an early tester. You've unlocked Premium for free.")
        }
    }
}
