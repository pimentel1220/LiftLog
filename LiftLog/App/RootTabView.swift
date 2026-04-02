import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var store: LiftLogStore

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
        .fullScreenCover(isPresented: workoutCoverBinding) {
            NavigationStack {
                ActiveWorkoutScreen()
            }
        }
    }

    private var workoutCoverBinding: Binding<Bool> {
        Binding(
            get: { store.activeWorkout != nil },
            set: { isPresented in
                if !isPresented, store.activeWorkout?.exerciseLogs.isEmpty == true {
                    store.discardActiveWorkout()
                }
            }
        )
    }
}
