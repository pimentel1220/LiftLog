import SwiftUI

struct ActiveWorkoutScreen: View {
    @EnvironmentObject private var store: LiftLogStore
    @Environment(\.dismiss) private var dismiss
    @State private var isShowingAddExercise = false
    @State private var isShowingNotes = false

    var body: some View {
        AppScreen(title: "Workout") {
            if let workout = store.activeWorkout {
                WorkoutSummaryCard(
                    startedAt: workout.startedAt,
                    exerciseCount: workout.exerciseLogs.count,
                    notes: Binding(
                        get: { store.activeWorkout?.notes ?? "" },
                        set: { store.updateActiveWorkoutNotes($0) }
                    ),
                    isShowingNotes: $isShowingNotes
                )

                PrimaryActionButton(title: "Add Exercise", systemImage: "plus") {
                    isShowingAddExercise = true
                }

                if workout.exerciseLogs.isEmpty {
                    EmptyStateCard(
                        title: "Add your first exercise",
                        subtitle: "Choose an exercise, log a set, and LiftLog will start remembering your last lift right away.",
                        systemImage: "dumbbell",
                        footnote: "Your workout saves automatically on this device while you log.",
                        actionTitle: "Choose Exercise"
                    ) {
                        isShowingAddExercise = true
                    }
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

private struct WorkoutSummaryCard: View {
    let startedAt: Date
    let exerciseCount: Int
    @Binding var notes: String
    @Binding var isShowingNotes: Bool

    var body: some View {
        AppCard {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Started \(AppFormat.shortTime(startedAt))")
                        .font(.headline)
                    Text(exerciseCount == 0 ? "No exercises yet" : "\(exerciseCount) exercise\(exerciseCount == 1 ? "" : "s") in this workout")
                        .font(.subheadline)
                        .foregroundStyle(AppTheme.textSecondary)
                }

                Spacer()

                Button(isShowingNotes ? "Hide Notes" : "Notes") {
                    isShowingNotes.toggle()
                }
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(AppTheme.cardSecondary)
                .clipShape(Capsule())
            }

            if isShowingNotes {
                TextField("Optional workout notes", text: $notes, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(12)
                    .background(AppTheme.cardSecondary)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }

            Text("Changes save automatically while you log. Tap Finish when you're done to move this workout into History.")
                .font(.caption)
                .foregroundStyle(AppTheme.textSecondary)
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
                        .font(.title3.weight(.bold))
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
                    .font(.footnote)
                    .foregroundStyle(AppTheme.textSecondary)
            }

            VStack(spacing: 10) {
                ForEach(Array(log.sets.enumerated()), id: \.element.id) { index, set in
                    SetEditorRow(
                        logID: log.id,
                        setNumber: index + 1,
                        set: set
                    )
                }
            }

            HStack(spacing: 10) {
                WorkoutQuickActionButton(title: "Repeat Last Set", systemImage: "arrow.triangle.2.circlepath") {
                    store.repeatPreviousSet(for: log.id)
                }
                WorkoutQuickActionButton(title: "Add Blank Set", systemImage: "plus") {
                    store.addEmptySet(to: log.id)
                }
            }
        }
    }
}

private struct SetEditorRow: View {
    @EnvironmentObject private var store: LiftLogStore
    let logID: UUID
    let setNumber: Int
    let set: ExerciseSet

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Set \(setNumber)")
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
                CompactMetricEditor(
                    title: "Weight",
                    value: set.weight == 0 ? "Body" : AppFormat.editableWeight(set.weight),
                    subtitle: set.weight == 0 ? "bodyweight" : "lb",
                    decrement: { store.updateSetWeight(logID: logID, setID: set.id, delta: -5) },
                    increment: { store.updateSetWeight(logID: logID, setID: set.id, delta: 5) }
                )

                CompactMetricEditor(
                    title: "Reps",
                    value: "\(set.reps)",
                    subtitle: "target",
                    decrement: { store.updateSetReps(logID: logID, setID: set.id, delta: -1) },
                    increment: { store.updateSetReps(logID: logID, setID: set.id, delta: 1) }
                )
            }

            HStack(spacing: 8) {
                QuickValueChip(label: "Body", isActive: set.weight == 0) {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: -set.weight)
                }
                QuickValueChip(label: "+5") {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: 5)
                }
                QuickValueChip(label: "+10") {
                    store.updateSetWeight(logID: logID, setID: set.id, delta: 10)
                }
                QuickValueChip(label: "8 reps") {
                    store.updateSetReps(logID: logID, setID: set.id, to: 8)
                }
                QuickValueChip(label: "12 reps") {
                    store.updateSetReps(logID: logID, setID: set.id, to: 12)
                }
            }
        }
        .padding(14)
        .background(AppTheme.cardSecondary)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
    }
}

private struct CompactMetricEditor: View {
    let title: String
    let value: String
    let subtitle: String
    let decrement: () -> Void
    let increment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(AppTheme.textSecondary)

            HStack(spacing: 10) {
                LargeAdjustButton(systemImage: "minus", tint: .white.opacity(0.12)) {
                    decrement()
                }

                VStack(spacing: 2) {
                    Text(value)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                .frame(maxWidth: .infinity)

                LargeAdjustButton(systemImage: "plus", tint: AppTheme.accent, foreground: .black) {
                    increment()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .font(.title3.weight(.bold))
                .frame(width: 44, height: 44)
                .background(tint)
                .foregroundStyle(foreground)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
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

private struct WorkoutQuickActionButton: View {
    let title: String
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                Spacer()
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
            .frame(maxWidth: .infinity)
            .background(AppTheme.cardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
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
            .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
            .background(AppTheme.card)
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct ExercisePickerRow: View {
    let title: String
    let subtitle: String
    var trailingIcon: String = "plus.circle.fill"
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: trailingIcon)
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(14)
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

    private var activeExerciseIDs: Set<UUID> {
        Set(store.activeWorkout?.exerciseLogs.map(\.exerciseID) ?? [])
    }

    private var savedExercises: [ExerciseDefinition] {
        let base = store.exercises(for: selectedCategory).filter { !activeExerciseIDs.contains($0.id) }
        guard !searchText.isEmpty else { return base }
        return base.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var favoriteExercises: [ExerciseDefinition] {
        let filtered = store.favoriteExercises.filter {
            $0.category == selectedCategory && !activeExerciseIDs.contains($0.id)
        }
        guard !searchText.isEmpty else { return filtered }
        return filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var recentExercises: [ExerciseDefinition] {
        let filtered = store.recentExercises(for: selectedCategory).filter { !activeExerciseIDs.contains($0.id) }
        guard !searchText.isEmpty else { return filtered }
        return filtered.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }

    private var availableTemplates: [ExerciseTemplate] {
        templates.filter { template in
            if let existing = store.findExercise(named: template.name, category: template.category) {
                return !activeExerciseIDs.contains(existing.id)
            }
            return true
        }
    }

    private var savedExerciseRemainder: [ExerciseDefinition] {
        let excludedIDs = Set(favoriteExercises.map(\.id) + recentExercises.map(\.id))
        return savedExercises.filter { !excludedIDs.contains($0.id) }
    }

    private var hasResults: Bool {
        !favoriteExercises.isEmpty || !recentExercises.isEmpty || !savedExerciseRemainder.isEmpty || !availableTemplates.isEmpty
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

                    if !favoriteExercises.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Favorites")
                                .font(.headline)
                            ForEach(favoriteExercises) { exercise in
                                ExercisePickerRow(
                                    title: exercise.name,
                                    subtitle: store.lastPerformance(for: exercise.id)?.summaryText ?? exercise.notes
                                ) {
                                    store.addExerciseToActiveWorkout(exercise: exercise)
                                    dismiss()
                                }
                            }
                        }
                    }

                    if !recentExercises.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Recent")
                                .font(.headline)
                            ForEach(recentExercises) { exercise in
                                ExercisePickerRow(
                                    title: exercise.name,
                                    subtitle: store.lastPerformance(for: exercise.id)?.summaryText ?? exercise.notes,
                                    trailingIcon: "clock.arrow.circlepath"
                                ) {
                                    store.addExerciseToActiveWorkout(exercise: exercise)
                                    dismiss()
                                }
                            }
                        }
                    }

                    if !savedExerciseRemainder.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Your \(selectedCategory.rawValue)")
                                .font(.headline)
                            ForEach(savedExerciseRemainder) { exercise in
                                ExercisePickerRow(
                                    title: exercise.name,
                                    subtitle: store.lastPerformance(for: exercise.id)?.summaryText ?? exercise.notes
                                ) {
                                    store.addExerciseToActiveWorkout(exercise: exercise)
                                    dismiss()
                                }
                            }
                        }
                    }

                    if !availableTemplates.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(selectedCategory == .machines ? "Quick Picks" : "Popular Choices")
                                .font(.headline)
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                ForEach(availableTemplates) { template in
                                    ExerciseTemplateTile(template: template, subtitle: template.starterNotes) {
                                        let exercise = store.ensureExercise(from: template)
                                        store.addExerciseToActiveWorkout(exercise: exercise)
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }

                    if !hasResults {
                        EmptyStateCard(
                            title: "Everything here is already in this workout",
                            subtitle: "Try another category, search for a different exercise, or create a custom one below.",
                            systemImage: "checkmark.circle"
                        )
                    }

                    AppCard {
                        Text("Create Custom Exercise")
                            .font(.headline)
                        Text("Use this for a machine or movement that is not already in your list.")
                            .font(.subheadline)
                            .foregroundStyle(AppTheme.textSecondary)
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
                        Button(store.findExercise(named: newExerciseName.trimmingCharacters(in: .whitespacesAndNewlines), category: selectedCategory) == nil ? "Create and Add" : "Add Existing Exercise") {
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
