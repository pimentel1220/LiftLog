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

struct ExerciseDefinition: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var category: ExerciseCategory
    var notes: String
    var isFavorite: Bool
    var createdAt: Date
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
}

struct WorkoutDraft: Identifiable, Codable, Hashable {
    var id: UUID
    var startedAt: Date
    var exerciseLogs: [WorkoutExerciseLog]
    var notes: String
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
    var name: String
    var weight: Double
    var date: Date
    var notes: String
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
    var exercises: [ExerciseDefinition]
    var workouts: [Workout]
    var activeWorkout: WorkoutDraft?
    var prRecords: [PRRecord]
    var tier: AppTier

    enum CodingKeys: String, CodingKey {
        case exercises
        case workouts
        case activeWorkout
        case prRecords
        case tier
    }

    init(exercises: [ExerciseDefinition], workouts: [Workout], activeWorkout: WorkoutDraft?, prRecords: [PRRecord], tier: AppTier) {
        self.exercises = exercises
        self.workouts = workouts
        self.activeWorkout = activeWorkout
        self.prRecords = prRecords
        self.tier = tier
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        exercises = try container.decode([ExerciseDefinition].self, forKey: .exercises)
        workouts = try container.decode([Workout].self, forKey: .workouts)
        activeWorkout = try container.decodeIfPresent(WorkoutDraft.self, forKey: .activeWorkout)
        prRecords = try container.decodeIfPresent([PRRecord].self, forKey: .prRecords) ?? []
        tier = try container.decodeIfPresent(AppTier.self, forKey: .tier) ?? .free
    }

    static let empty = PersistedAppState(exercises: [], workouts: [], activeWorkout: nil, prRecords: [], tier: .free)
}
