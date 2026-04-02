import SwiftUI

struct PRScreen: View {
    @EnvironmentObject private var store: LiftLogStore
    @State private var isShowingAddPR = false

    var body: some View {
        AppScreen(title: "PRs") {
            if store.hasActiveWorkout {
                ActiveWorkoutBanner {
                    store.resumeActiveWorkout()
                }
            }

            AppCard {
                Text("PR Tracker")
                    .font(.headline)
                Text("Keep separate max lifts here, even if they are not part of your logged workout sets.")
                    .font(.subheadline)
                    .foregroundStyle(AppTheme.textSecondary)
                PrimaryActionButton(title: "Add PR", systemImage: "plus") {
                    isShowingAddPR = true
                }
            }

            if store.sortedPRRecords.isEmpty {
                EmptyStateCard(
                    title: "No PRs yet",
                    subtitle: "Add a max lift like Bench Press \(store.formattedDisplayWeight(store.quickPRWeightSuggestions[store.quickPRWeightSuggestions.count / 2])) and keep all your PRs in one place.",
                    systemImage: "trophy"
                )
            } else {
                ForEach(store.sortedPRRecords) { record in
                    AppCard {
                        HStack(alignment: .top) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text(record.name)
                                    .font(.headline)
                                Text("Set on \(AppFormat.shortDate(record.date))")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                                if !record.notes.isEmpty {
                                    Text(record.notes)
                                        .font(.caption)
                                        .foregroundStyle(AppTheme.textSecondary)
                                }
                            }
                            Spacer()
                            VStack(alignment: .trailing, spacing: 8) {
                                Text(store.formattedWeight(record.weight))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(.yellow)
                                Button(role: .destructive) {
                                    store.deletePRRecord(record.id)
                                } label: {
                                    Image(systemName: "trash")
                                        .foregroundStyle(.red.opacity(0.9))
                                }
                            }
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $isShowingAddPR) {
            AddPRSheet()
        }
    }
}

private struct AddPRSheet: View {
    @EnvironmentObject private var store: LiftLogStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExerciseID: UUID?
    @State private var name = ""
    @State private var weight = ""
    @State private var date = Date()
    @State private var notes = ""
    @State private var isShowingExercisePicker = false

    private var searchQuery: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 14) {
                            Text("PR details")
                                .font(.headline)

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Exercise")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)

                                Button {
                                    isShowingExercisePicker = true
                                } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: "magnifyingglass")
                                            .foregroundStyle(AppTheme.accent)
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(searchQuery.isEmpty ? "Choose exercise" : name)
                                                .font(.subheadline.weight(.semibold))
                                                .foregroundStyle(.white)
                                            Text(searchQuery.isEmpty ? "Tap to pick from your list" : "Tap to change")
                                                .font(.caption)
                                                .foregroundStyle(AppTheme.textSecondary)
                                        }
                                        Spacer()
                                        Image(systemName: "chevron.right")
                                            .font(.caption.weight(.semibold))
                                            .foregroundStyle(AppTheme.textSecondary)
                                    }
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 14)
                                    .background(AppTheme.cardSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                                }
                                .buttonStyle(.plain)

                                TextField("Or type a custom lift", text: Binding(
                                    get: { name },
                                    set: { newValue in
                                        if newValue != name {
                                            selectedExerciseID = nil
                                        }
                                        name = newValue
                                    }
                                ))
                                    .textInputAutocapitalization(.words)
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 12)
                                    .background(AppTheme.cardSecondary)
                                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                            }

                            VStack(alignment: .leading, spacing: 8) {
                                Text("Max weight")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(AppTheme.textSecondary)
                                HStack(spacing: 12) {
                                    Button {
                                        adjustWeight(by: -5)
                                    } label: {
                                        Image(systemName: "minus")
                                            .font(.headline.weight(.bold))
                                            .frame(width: 44, height: 44)
                                            .background(AppTheme.cardSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }

                                    TextField("0", text: $weight)
                                        .keyboardType(.decimalPad)
                                        .font(.system(size: 28, weight: .bold, design: .rounded))
                                        .multilineTextAlignment(.center)
                                        .padding(.vertical, 10)
                                        .frame(maxWidth: .infinity)
                                        .background(AppTheme.cardSecondary)
                                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

                                    Text(store.weightUnit.shortLabel)
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(AppTheme.textSecondary)

                                    Button {
                                        adjustWeight(by: 5)
                                    } label: {
                                        Image(systemName: "plus")
                                            .font(.headline.weight(.bold))
                                            .frame(width: 44, height: 44)
                                            .background(AppTheme.cardSecondary)
                                            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                                    }
                                }

                                HStack(spacing: 8) {
                                    ForEach(store.quickPRWeightSuggestions, id: \.self) { quickWeight in
                                        Button(store.formattedDisplayWeight(quickWeight)) {
                                            weight = AppFormat.editableWeight(
                                                store.weightUnit.storedPounds(fromDisplayWeight: quickWeight),
                                                unit: store.weightUnit
                                            )
                                        }
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                        .background(AppTheme.cardSecondary)
                                        .clipShape(Capsule())
                                    }
                                }
                            }

                            DatePicker("Date", selection: $date, displayedComponents: .date)
                            TextField("Optional note", text: $notes, axis: .vertical)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Add PR")
            .sheet(isPresented: $isShowingExercisePicker) {
                PRExercisePickerSheet { selection in
                    selectedExerciseID = selection.exerciseID
                    name = selection.name
                    if weight.isEmpty, let suggestedWeight = selection.suggestedWeight {
                        weight = store.editableWeight(suggestedWeight)
                    }
                }
                .environmentObject(store)
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        store.addPRRecord(
                            exerciseID: selectedExerciseID,
                            name: name,
                            weight: store.weightUnit.storedPounds(fromDisplayWeight: Double(weight) ?? 0),
                            date: date,
                            notes: notes
                        )
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Double(weight) ?? 0) <= 0)
                }
            }
        }
    }

    private func adjustWeight(by delta: Double) {
        let currentWeight = Double(weight) ?? 0
        let nextWeight = max(0, currentWeight + delta)
        weight = AppFormat.editableWeight(
            store.weightUnit.storedPounds(fromDisplayWeight: nextWeight),
            unit: store.weightUnit
        )
    }
}

private struct PRExercisePickerSheet: View {
    @EnvironmentObject private var store: LiftLogStore
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedCategory: ExerciseCategory?

    let onSelect: (PRExerciseSelection) -> Void

    private var searchQuery: String {
        searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var filteredSavedExercises: [ExerciseDefinition] {
        store.sortedExercises.filter { exercise in
            matchesSearch(exercise.name) && matchesCategory(exercise.category)
        }
    }

    private var filteredTemplates: [ExerciseTemplate] {
        ExerciseCatalog.templates.filter { template in
            matchesSearch(template.name) && matchesCategory(template.category)
        }
    }

    private var suggestedTemplates: [ExerciseTemplate] {
        filteredTemplates.filter { template in
            !store.sortedExercises.contains {
                $0.category == template.category && $0.name.caseInsensitiveCompare(template.name) == .orderedSame
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    AppCard {
                        VStack(alignment: .leading, spacing: 12) {
                            TextField("Search exercises", text: $searchText)
                                .textInputAutocapitalization(.words)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 12)
                                .background(AppTheme.cardSecondary)
                                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))

                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    PRCategoryChip(title: "All", isSelected: selectedCategory == nil) {
                                        selectedCategory = nil
                                    }

                                    ForEach(ExerciseCategory.allCases) { category in
                                        PRCategoryChip(title: category.rawValue, isSelected: selectedCategory == category) {
                                            selectedCategory = category
                                        }
                                    }
                                }
                            }
                        }
                    }

                    if !filteredSavedExercises.isEmpty {
                        AppCard {
                            Text("Your exercises")
                                .font(.headline)

                            VStack(spacing: 10) {
                                ForEach(filteredSavedExercises) { exercise in
                                    PRExerciseChoiceRow(
                                        title: exercise.name,
                                        subtitle: exercise.category.rawValue
                                    ) {
                                        onSelect(
                                            PRExerciseSelection(
                                                exerciseID: exercise.id,
                                                name: exercise.name,
                                                suggestedWeight: store.lastPerformance(for: exercise.id)?.weight
                                            )
                                        )
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }

                    if !suggestedTemplates.isEmpty {
                        AppCard {
                            Text("Popular choices")
                                .font(.headline)

                            VStack(spacing: 10) {
                                ForEach(suggestedTemplates) { template in
                                    PRExerciseChoiceRow(
                                        title: template.name,
                                        subtitle: template.category.rawValue
                                    ) {
                                        onSelect(PRExerciseSelection(exerciseID: nil, name: template.name, suggestedWeight: nil))
                                        dismiss()
                                    }
                                }
                            }
                        }
                    }

                    if filteredSavedExercises.isEmpty && suggestedTemplates.isEmpty {
                        EmptyStateCard(
                            title: "No matches",
                            subtitle: "Try another search or type a custom exercise in the PR form.",
                            systemImage: "magnifyingglass"
                        )
                    }
                }
                .padding(20)
            }
            .background(AppTheme.background.ignoresSafeArea())
            .navigationTitle("Choose Exercise")
        }
    }

    private func matchesSearch(_ value: String) -> Bool {
        searchQuery.isEmpty || value.localizedCaseInsensitiveContains(searchQuery)
    }

    private func matchesCategory(_ category: ExerciseCategory) -> Bool {
        selectedCategory == nil || selectedCategory == category
    }
}

private struct PRCategoryChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(isSelected ? Color.black : .white)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(isSelected ? Color.white : AppTheme.cardSecondary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

private struct PRExerciseChoiceRow: View {
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(AppTheme.textSecondary)
                }
                Spacer()
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(AppTheme.accent)
            }
            .padding(14)
            .background(AppTheme.cardSecondary)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

private struct PRExerciseSelection {
    let exerciseID: UUID?
    let name: String
    let suggestedWeight: Double?
}
