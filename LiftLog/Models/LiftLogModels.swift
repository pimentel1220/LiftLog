import Foundation

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable, Hashable {
    case machines = "Machines"
    case freeWeights = "Free Weights"
    case cables = "Cables"
    case bodyweight = "Bodyweight"

    var id: String { rawValue }
    var iconName: String {
        switch self {
        case .machines: "rectangle.3.group.fill"
        case .freeWeights: "dumbbell.fill"
        case .cables: "link"
        case .bodyweight: "figure.strengthtraining.traditional"
        }
    }
}

enum AppTier: String, Codable, CaseIterable, Identifiable {
    case free
    case premium
    case adFree

    var id: String { rawValue }
}

enum WeightUnit: String, Codable, CaseIterable, Identifiable, Hashable {
    case pounds
    case kilograms

    var id: String { rawValue }

    var title: String {
        switch self {
        case .pounds: "Pounds"
        case .kilograms: "Kilograms"
        }
    }

    var shortLabel: String {
        switch self {
        case .pounds: "lb"
        case .kilograms: "kg"
        }
    }

    func displayWeight(fromStoredPounds pounds: Double) -> Double {
        switch self {
        case .pounds:
            pounds
        case .kilograms:
            pounds / 2.2046226218
        }
    }

    func storedPounds(fromDisplayWeight value: Double) -> Double {
        switch self {
        case .pounds:
            value
        case .kilograms:
            value * 2.2046226218
        }
    }
}

struct AppPreferences: Codable, Hashable {
    var syncPRsWithWorkouts = false
    var weightUnit: WeightUnit = .pounds

    enum CodingKeys: String, CodingKey {
        case syncPRsWithWorkouts
        case weightUnit
    }

    init(syncPRsWithWorkouts: Bool = false, weightUnit: WeightUnit = .pounds) {
        self.syncPRsWithWorkouts = syncPRsWithWorkouts
        self.weightUnit = weightUnit
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        syncPRsWithWorkouts = try container.decodeIfPresent(Bool.self, forKey: .syncPRsWithWorkouts) ?? false
        weightUnit = try container.decodeIfPresent(WeightUnit.self, forKey: .weightUnit) ?? .pounds
    }
}

struct ExerciseDefinition: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: ExerciseCategory
    var notes: String
    var isFavorite: Bool
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case notes
        case isFavorite
        case createdAt
        case updatedAt
    }

    init(id: UUID, name: String, category: ExerciseCategory, notes: String, isFavorite: Bool, createdAt: Date, updatedAt: Date? = nil) {
        self.id = id
        self.name = name
        self.category = category
        self.notes = notes
        self.isFavorite = isFavorite
        self.createdAt = createdAt
        self.updatedAt = updatedAt ?? createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        category = try container.decode(ExerciseCategory.self, forKey: .category)
        notes = try container.decode(String.self, forKey: .notes)
        isFavorite = try container.decode(Bool.self, forKey: .isFavorite)
        createdAt = try container.decode(Date.self, forKey: .createdAt)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? createdAt
    }
}

struct ExerciseSet: Identifiable, Codable, Hashable {
    var id: UUID
    var weight: Double
    var reps: Int

    static let empty = ExerciseSet(id: UUID(), weight: 0, reps: 10)
}

struct WorkoutExerciseLog: Identifiable, Codable, Hashable {
    var id: UUID
    var exerciseID: UUID
    var exerciseName: String
    var category: ExerciseCategory
    var notes: String
    var sets: [ExerciseSet]
}

struct Workout: Identifiable, Codable, Hashable {
    var id: UUID
    var startedAt: Date
    var endedAt: Date
    var exerciseLogs: [WorkoutExerciseLog]
    var notes: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt
        case endedAt
        case exerciseLogs
        case notes
        case updatedAt
    }

    init(id: UUID, startedAt: Date, endedAt: Date, exerciseLogs: [WorkoutExerciseLog], notes: String, updatedAt: Date? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.endedAt = endedAt
        self.exerciseLogs = exerciseLogs
        self.notes = notes
        self.updatedAt = updatedAt ?? endedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        endedAt = try container.decode(Date.self, forKey: .endedAt)
        exerciseLogs = try container.decode([WorkoutExerciseLog].self, forKey: .exerciseLogs)
        notes = try container.decode(String.self, forKey: .notes)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? endedAt
    }
}

struct WorkoutDraft: Identifiable, Codable, Hashable {
    var id: UUID
    var startedAt: Date
    var exerciseLogs: [WorkoutExerciseLog]
    var notes: String
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case startedAt
        case exerciseLogs
        case notes
        case updatedAt
    }

    init(id: UUID, startedAt: Date, exerciseLogs: [WorkoutExerciseLog], notes: String, updatedAt: Date? = nil) {
        self.id = id
        self.startedAt = startedAt
        self.exerciseLogs = exerciseLogs
        self.notes = notes
        self.updatedAt = updatedAt ?? startedAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        startedAt = try container.decode(Date.self, forKey: .startedAt)
        exerciseLogs = try container.decode([WorkoutExerciseLog].self, forKey: .exerciseLogs)
        notes = try container.decode(String.self, forKey: .notes)
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? startedAt
    }
}

struct LastPerformance: Hashable {
    let weight: Double
    let reps: Int
    let date: Date

    var summaryText: String {
        "Last time: \(AppFormat.weight(weight)) x \(reps) on \(AppFormat.shortDate(date))"
    }
}

struct PersonalRecord: Hashable {
    let weight: Double
    let reps: Int
    let date: Date

    var summaryText: String {
        "\(AppFormat.weight(weight)) x \(reps)"
    }
}

struct PRRecord: Identifiable, Codable, Hashable {
    var id: UUID
    var exerciseID: UUID?
    var name: String
    var weight: Double
    var date: Date
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case exerciseID
        case name
        case weight
        case date
        case notes
        case createdAt
        case updatedAt
    }

    init(id: UUID, exerciseID: UUID? = nil, name: String, weight: Double, date: Date, notes: String, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.exerciseID = exerciseID
        self.name = name
        self.weight = weight
        self.date = date
        self.notes = notes
        self.createdAt = createdAt ?? date
        self.updatedAt = updatedAt ?? date
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        exerciseID = try container.decodeIfPresent(UUID.self, forKey: .exerciseID)
        name = try container.decode(String.self, forKey: .name)
        weight = try container.decode(Double.self, forKey: .weight)
        date = try container.decode(Date.self, forKey: .date)
        notes = try container.decode(String.self, forKey: .notes)
        createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt) ?? date
        updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt) ?? date
    }
}

struct ExerciseStat: Identifiable, Hashable {
    let exerciseID: UUID
    let name: String
    let maxWeight: Double
    let totalReps: Int
    let recentWeight: Double
    let personalRecord: PersonalRecord

    var id: UUID { exerciseID }
}

struct ExerciseTemplate: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: ExerciseCategory
    let starterNotes: String
}

struct PersistedAppState: Codable {
    static let currentSchemaVersion = 3

    var exercises: [ExerciseDefinition]
    var workouts: [Workout]
    var activeWorkout: WorkoutDraft?
    var prRecords: [PRRecord]
    var tier: AppTier
    var preferences: AppPreferences
    var schemaVersion: Int

    enum CodingKeys: String, CodingKey {
        case exercises
        case workouts
        case activeWorkout
        case prRecords
        case tier
        case preferences
        case schemaVersion
    }

    init(exercises: [ExerciseDefinition], workouts: [Workout], activeWorkout: WorkoutDraft?, prRecords: [PRRecord], tier: AppTier, preferences: AppPreferences = AppPreferences(), schemaVersion: Int = PersistedAppState.currentSchemaVersion) {
        self.exercises = exercises
        self.workouts = workouts
        self.activeWorkout = activeWorkout
        self.prRecords = prRecords
        self.tier = tier
        self.preferences = preferences
        self.schemaVersion = schemaVersion
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exercises = try container.decode([ExerciseDefinition].self, forKey: .exercises)
        workouts = try container.decode([Workout].self, forKey: .workouts)
        activeWorkout = try container.decodeIfPresent(WorkoutDraft.self, forKey: .activeWorkout)
        prRecords = try container.decodeIfPresent([PRRecord].self, forKey: .prRecords) ?? []
        tier = try container.decodeIfPresent(AppTier.self, forKey: .tier) ?? .free
        preferences = try container.decodeIfPresent(AppPreferences.self, forKey: .preferences) ?? AppPreferences()
        schemaVersion = try container.decodeIfPresent(Int.self, forKey: .schemaVersion) ?? 1
    }

    static let empty = PersistedAppState(exercises: [], workouts: [], activeWorkout: nil, prRecords: [], tier: .free)
}
