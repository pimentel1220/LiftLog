import SwiftUI

struct ActiveWorkoutScreen: View {
    @EnvironmentObject private var store: LiftLogStore
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingAddExercise = false

    var body: some View {
        AppScreen(title: "Workout") {
            if let workout = store.activeWorkout {
                AppCard {
                    Text("Started \(AppFormat.shortTime(workout.startedAt))")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                    TextField("Workout notes", text: Binding(
                        get: { store.activeWorkout?.notes ?? "" },
                        set: { store.updateActiveWorkoutNotes($0) }
                    ), axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(AppTheme.cardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }

                PrimaryActionButton(title: "Add Exercise", systemImage: "plus") {
                    isShowingAddExercise = true
                }

                if workout.exerciseLogs.isEmpty {
                    EmptyStateCard(
                        title: "Add your first exercise",
                        subtitle: "Pick an exercise and LiftLog will show what you used last time right away.",
                        systemImage: "dumbbell"
                    )
                } else {
                    ForEach(workout.exerciseLogs) { log in
                        ActiveExerciseCard(log: log)
                    }
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button("Close") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Finish") {
                    store.finishWorkout()
                    dismiss()
                }
                .fontWeight(.semibold)
                .disabled(store.activeWorkout?.exerciseLogs.isEmpty != false)
            }
        }
        .sheet(isPresented: $isShowingAddExercise) {
            AddExerciseSheet()
        }
    }
}

private struct ActiveExerciseCard: View {
    @EnvironmentObject private var store: LiftLogStore
    let log: WorkoutExerciseLog

    var body: some View {
        AppCard {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(log.exerciseName)
                        .font(.headline)
                    CategoryPill(category: log.category)
                }
                Spacer()
                Button {
                    store.deleteExerciseFromActiveWorkout(logID: log.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.9))
                }
            }

            LastTimeBanner(performance: store.lastPerformance(for: log.exerciseID))

            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            ForEach(log.sets) { set in
                SetEditorRow(logID: log.id, set: set)
            }

            HStack(spacing: 10) {
                SecondaryActionButton(title: "Repeat Last Set", systemImage: "arrow.triangle.2.circlepath") {
                    store.repeatPreviousSet(for: log.id)
                }
                SecondaryActionButton(title: "Add Set", systemImage: "plus") {
                    store.addSet(to: log.id)
                }
            }
        }
    }
}

private struct SetEditorRow: View {
    @EnvironmentObject private var store: LiftLogStore
    let logID: UUID
    let set: ExerciseSet

    var body: some View {
        VStack(spacing: 12) {
            weightSection
            repsSection
        }
        .padding(14)
        .background(AppTheme.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }

    private var weightSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Weight")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(AppTheme.textSecondary)
                Spacer()
                Button {
                    store.removeSet(logID: logID, setID: set.id)
                } label: {
                    Image(systemName: "trash")
                        .foregroundStyle(.red.opacity(0.9))
                }
            }

            HStack(spacing: 12) {
                LargeAdjustButton(systemImage: "minus", tint: .white.opacity(0.12)) {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: -5)
                }

                VStack(spacing: 4) {
                    Text(set.weight == 0 ? "Bodyweight" : "\(set.weight.formatted(.number.precision(.fractionLength(0...1))))")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                    Text(set.weight == 0 ? "No added weight" : "lb")
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                LargeAdjustButton(systemImage: "plus", tint: AppTheme.accent, foreground: .black) {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: 5)
                }
            }

            HStack(spacing: 8) {
                QuickValueChip(label: "Body", isActive: set.weight == 0) {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: -set.weight)
                }
                QuickValueChip(label: "-2.5") {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: -2.5)
                }
                QuickValueChip(label: "+2.5") {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: 2.5)
                }
                QuickValueChip(label: "+5") {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: 5)
                }
                QuickValueChip(label: "+10") {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: 10)
                }
            }
        }
    }

    private var repsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reps")
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 12) {
                LargeAdjustButton(systemImage: "minus", tint: .white.opacity(0.12)) {
                    store.updateSetReps(logID: logID, setID: set.id, delta: -1)
                }

                Text("\(set.reps)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .frame(maxWidth: .infinity)

                LargeAdjustButton(systemImage: "plus", tint: AppTheme.accent, foreground: .black) {
                    store.updateSetReps(logID: logID, setID: set.id, delta: 1)
                }
            }

            HStack(spacing: 8) {
                QuickValueChip(label: "6") {
                    store.updateSetReps(logID: logID, setID: set.id, to: 6)
                }
                QuickValueChip(label: "8") {
                    store.updateSetReps(logID: logID, setID: set.id, to: 8)
                }
                QuickValueChip(label: "10") {
                    store.updateSetReps(logID: logID, setID: set.id, to: 10)
                }
                QuickValueChip(label: "12") {
                    store.updateSetReps(logID: logID, setID: set.id, to: 12)
                }
                QuickValueChip(label: "15") {
                    store.updateSetReps(logID: logID, setID: set.id, to: 15)
                }
            }
        }
    }
}

private struct LargeAdjustButton: View {
    let systemImage: String
    let tint: Color
    var foreground: Color = .white
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.title2.weight(.bold))
                .frame(width: 52, height: 52)
                .background(tint)
                .foregroundStyle(foreground)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct QuickValueChip: View {
    let label: String
    var isActive = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(isActive ? AppTheme.accent : AppTheme.accentMuted)
                .foregroundStyle(isActive ? .black : AppTheme.accent)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct CategoryFilterPill: View {
    let category: ExerciseCategory
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Label(category.rawValue, systemImage: category.iconName)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(isSelected ? AppTheme.accent : AppTheme.cardSecondary)
                .foregroundStyle(isSelected ? .black : .white)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct ExerciseTemplateTile: View {
    let template: ExerciseTemplate
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: template.category.iconName)
                        .foregroundStyle(AppTheme.accent)
                    Spacer()
                }
                Text(template.name)
                    .font(.subheadline.weight(.semibold))
                    .multilineTextAlignment(.leading)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(AppTheme.textSecondary)
                    .lineLimit(2)
            }
            .padding(14)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .topLeading)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct AddExerciseSheet: View {
    @EnvironmentObject private var store: LiftLogStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var newExerciseName = ""
    @State private var selectedCategory: ExerciseCategory = .machines
    @State private var notes = ""

    private var templates: [ExerciseTemplate] {
        let base = ExerciseCatalog.templates(for: selectedCategory)
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var savedExercises: [ExerciseDefinition] {
        let base = store.exercises(for: selectedCategory)
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    VStack(alignment: .leading, spacing: 12) {
                        TextField("Search machines or exercises", text: $searchText)
                            .textFieldStyle(.plain)
                            .padding(14)
                            .background(AppTheme.card)
                            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(ExerciseCategory.allCases) { category in
                                    CategoryFilterPill(category: category, isSelected: selectedCategory == category) {
                                        selectedCategory = category
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        Text(selectedCategory == .machines ? "Popular Machines" : "Quick Picks")
                            .font(.headline)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                            ForEach(templates) { template in
                                ExerciseTemplateTile(template: template, subtitle: template.starterNotes) {
                                    let exercise = store.ensureExercise(from: template)
                                    store.addExerciseToActiveWorkout(exercise: exercise)
                                    dismiss()
                                }
                            }
                        }
                    }

                    if !savedExercises.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your Saved \(selectedCategory.rawValue)")
                                .font(.headline)
                            ForEach(savedExercises) { exercise in
                                Button {
                                    store.addExerciseToActiveWorkout(exercise: exercise)
                                    dismiss()
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(exercise.name)
                                                .foregroundStyle(.white)
                                            Text(store.lastPerformance(for: exercise.id)?.summaryText ?? exercise.notes)
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textSecondary)
                                                .lineLimit(2)
                                        }
                                        Spacer()
                                        Image(systemName: "plus.circle.fill")
                                            .foregroundStyle(AppTheme.accent)
                                    }
                                    .padding(14)
                                    .background(AppTheme.card)
                                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    AppCard {
                        Text("Create Custom Exercise")
                            .font(.headline)
                        TextField("Exercise name", text: $newExerciseName)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(AppTheme.cardSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        TextField("Seat setting, machine level, handle position", text: $notes, axis: .vertical)
                            .textFieldStyle(.plain)
                            .padding(12)
                            .background(AppTheme.cardSecondary)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Button("Create and Add") {
                            let exercise = store.createExercise(name: newExerciseName, category: selectedCategory, notes: notes)
                            store.addExerciseToActiveWorkout(exercise: exercise)
                            dismiss()
                        }
                        .disabled(newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
            }
            .padding(20)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Add Exercise")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}
