import SwiftUI

struct ProgressScreen: View {
    @EnvironmentObject private var store: LiftLogStore

    var stats: [ExerciseStat] {
        Array(store.exerciseStats().prefix(6))
    }

    var body: some View {
        AppScreen(title: "Progress") {
            if stats.isEmpty {
                EmptyStateCard(
                    title: "Progress will show up here",
                    subtitle: "Finish a few workouts and LiftLog will surface personal bests and recent trends.",
                    systemImage: "chart.bar.fill"
                )
            } else {
                AppCard {
                    Text("Personal Bests")
                        .font(.headline)
                    ForEach(stats) { stat in
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(stat.name)
                                Spacer()
                                Text(AppFormat.weight(stat.maxWeight))
                                    .fontWeight(.semibold)
                            }
                            ProgressBar(value: stat.recentWeight, maxValue: max(stat.maxWeight, 1))
                            Text("Recent: \(AppFormat.weight(stat.recentWeight))")
                                .font(.caption)
                                .foregroundStyle(AppTheme.textSecondary)
                        }
                    }
                }

                AppCard {
                    Text("Recent Trends")
                        .font(.headline)
                    ForEach(stats) { stat in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(stat.name)
                                Text("\(stat.totalReps) total reps logged")
                                    .font(.caption)
                                    .foregroundStyle(AppTheme.textSecondary)
                            }
                            Spacer()
                            Text(AppFormat.weight(stat.maxWeight))
                                .foregroundStyle(AppTheme.accent)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }
        }
    }
}

private struct ProgressBar: View {
    let value: Double
    let maxValue: Double

    var body: some View {
        GeometryReader { geometry in
            let width = max(geometry.size.width * CGFloat(value / maxValue), 12)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.cardSecondary)
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(AppTheme.accent)
                    .frame(width: width)
            }
        }
        .frame(height: 12)
    }
}
