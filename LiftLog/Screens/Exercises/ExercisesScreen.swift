import SwiftUI

struct ExercisesScreen: View {
    @EnvironmentObject private var store: LiftLogStore
    @State private var searchText = ""

    var filteredExercises: [ExerciseDefinition] {
        if searchText.isEmpty { return store.sortedExercises }
        return store.sortedExercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        AppScreen(title: "Exercises") {
            if filteredExercises.isEmpty {
                EmptyStateCard(
                    title: "No exercises found",
                    subtitle: "Create one from a workout and it will show up here.",
                    systemImage: "magnifyingglass"
                )
            } else {
                ForEach(filteredExercises) { exercise in
                    NavigationLink {
                        ExerciseDetailScreen(exerciseID: exercise.id)
                    } label: {
                        AppCard {
                            HStack(alignment: .top) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundStyle(.white)
                                    CategoryPill(category: exercise.category)
                                    Text(store.lastPerformance(for: exercise.id)?.summaryText ?? "No history yet")
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.textSecondary)
                                    if !exercise.notes.isEmpty {
                                        Text(exercise.notes)
                                            .font(.caption)
                                            .foregroundStyle(AppTheme.textSecondary)
                                            .lineLimit(1)
                                    }
                                }
                                Spacer()
                                if exercise.isFavorite {
                                    Image(systemName: "star.fill")
                                        .foregroundStyle(.yellow)
                                }
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .searchable(text: $searchText, prompt: "Search exercises")
    }
}
