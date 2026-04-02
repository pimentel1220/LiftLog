import SwiftUI

struct HistoryScreen: View {
    @EnvironmentObject private var store: LiftLogStore

    private var groupedWorkouts: [(title: String, workouts: [Workout])] {
        let groups = Dictionary(grouping: store.recentWorkouts) { workout in
            AppFormat.monthYear(workout.startedAt)
        }

        return groups
            .map { (title: $0.key, workouts: $0.value.sorted { $0.startedAt > $1.startedAt }) }
            .sorted { lhs, rhs in
                (lhs.workouts.first?.startedAt ?? .distantPast) > (rhs.workouts.first?.startedAt ?? .distantPast)
            }
    }

    var body: some View {
        AppScreen(title: "History") {
            if store.recentWorkouts.isEmpty {
                EmptyStateCard(
                    title: "Your workouts will show up here",
                    subtitle: "Every finished workout gets saved automatically so you can come back and see what you lifted.",
                    systemImage: "clock.arrow.circlepath",
                    footnote: "Start with one exercise and this screen becomes your running gym log.",
                    actionTitle: store.hasActiveWorkout ? "Continue Workout" : "Start Workout"
                ) {
                    if !store.hasActiveWorkout {
                        store.startWorkout()
                    }
                }
            } else {
                Text("Most recent first")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)

                ForEach(groupedWorkouts, id: \.title) { group in
                    VStack(alignment: .leading, spacing: 12) {
                        Text(group.title)
                            .font(.headline)
                            .foregroundStyle(.white)

                        ForEach(group.workouts) { workout in
                            NavigationLink {
                                WorkoutDetailScreen(workout: workout)
                            } label: {
                                WorkoutHistoryCard(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

private struct WorkoutHistoryCard: View {
    let workout: Workout

    var body: some View {
        AppCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(AppFormat.shortDate(workout.startedAt))
                        .font(.headline)
                        .foregroundStyle(.white)
                    Text("\(workout.exerciseLogs.count) exercise\(workout.exerciseLogs.count == 1 ? "" : "s") logged")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Text(AppFormat.shortTime(workout.startedAt))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
            }

            ForEach(workout.exerciseLogs.prefix(3)) { log in
                HStack {
                    Text(log.exerciseName)
                        .foregroundStyle(.white)
                    Spacer()
                    Text(log.sets.last.map { "\(AppFormat.weight($0.weight)) x \($0.reps)" } ?? "No sets")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if workout.exerciseLogs.count > 3 {
                Text("+\(workout.exerciseLogs.count - 3) more exercise\(workout.exerciseLogs.count - 3 == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
            }
        }
    }
}

private struct WorkoutDetailScreen: View {
    let workout: Workout

    var body: some View {
        AppScreen(title: AppFormat.shortDate(workout.startedAt)) {
            AppCard {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Workout Summary")
                            .font(.headline)
                        Text("\(workout.exerciseLogs.count) exercise\(workout.exerciseLogs.count == 1 ? "" : "s")")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    Spacer()
                    Text(AppFormat.shortTime(workout.startedAt))
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            if !workout.notes.isEmpty {
                AppCard {
                    Text("Workout Notes")
                        .font(.headline)
                    Text(workout.notes)
                        .foregroundStyle(AppTheme.textSecondary)
                }
            }

            ForEach(workout.exerciseLogs) { log in
                AppCard {
                    Text(log.exerciseName)
                        .font(.headline)
                    CategoryPill(category: log.category)
                    if !log.notes.isEmpty {
                        Text(log.notes)
                            .font(.caption)
                            .foregroundStyle(AppTheme.textSecondary)
                    }
                    ForEach(Array(log.sets.enumerated()), id: \.element.id) { index, set in
                        HStack {
                            Text("Set \(index + 1)")
                                .foregroundStyle(AppTheme.textSecondary)
                            Spacer()
                            Text(AppFormat.weight(set.weight))
                            Text("x \(set.reps)")
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                        .font(.subheadline)
                    }
                }
            }
        }
    }
}
