import SwiftData
import SwiftUI
import Charts

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedEntry: HomeBalanceDataPoint?
    @Query(
        FetchDescriptor<Race>(
            sortBy: [
                SortDescriptor(\Race.date, order: .forward)
            ]
        )
    ) private var races: [Race]
    @Query(
        FetchDescriptor<Profile>(
            sortBy: [
                SortDescriptor(\Profile.createdAt, order: .forward)
            ]
        )
    ) private var profiles: [Profile]

    private var dataSignature: BalanceDataSignature {
        BalanceDataSignature(profile: profiles.first, races: races)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                summarySection
                chartSection
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(Color(.systemGroupedBackground))
        .task(id: dataSignature) {
            await MainActor.run {
                viewModel.update(races: races, profile: profiles.first)
                selectedEntry = nil
            }
        }
        .onChange(of: viewModel.dailySeries) { _ in
            selectedEntry = nil
        }
    }

    private var summarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("今月サマリー")
                .font(.headline)
            if let summary = viewModel.monthlySummary {
                HomeSummaryCard(summary: summary)
            } else {
                ContentUnavailableView(
                    "データがありません",
                    systemImage: "chart.line.uptrend.xyaxis",
                    description: Text("レースとチケットを登録するとサマリーが表示されます")
                )
                .frame(maxWidth: .infinity)
            }
        }
    }

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("日次残高")
                .font(.headline)
            if viewModel.dailySeries.isEmpty {
                ContentUnavailableView(
                    "チャートが表示できません",
                    systemImage: "chart.xyaxis.line",
                    description: Text("集計対象のチケットが登録されると推移が表示されます")
                )
                .frame(maxWidth: .infinity)
            } else {
                Chart {
                    ForEach(viewModel.dailySeries) { point in
                        LineMark(
                            x: .value("日付", point.date),
                            y: .value("Actual", point.actualBalance)
                        )
                        .foregroundStyle(by: .value("系列", "Actual"))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("日付", point.date),
                            y: .value("If", point.ifBalance)
                        )
                        .foregroundStyle(by: .value("系列", "If"))
                        .interpolationMethod(.catmullRom)
                    }

                    if let selectedEntry {
                        RuleMark(x: .value("日付", selectedEntry.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                            .foregroundStyle(.secondary)
                            .annotation(position: .topLeading) {
                                tooltipView(for: selectedEntry)
                            }

                        PointMark(
                            x: .value("日付", selectedEntry.date),
                            y: .value("Actual", selectedEntry.actualBalance)
                        )
                        .foregroundStyle(Color.blue)
                        .symbolSize(70)

                        PointMark(
                            x: .value("日付", selectedEntry.date),
                            y: .value("If", selectedEntry.ifBalance)
                        )
                        .foregroundStyle(Color.green)
                        .symbolSize(70)
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .chartForegroundStyleScale([
                    "Actual": Color.blue,
                    "If": Color.green
                ])
                .chartLegend(position: .bottom, alignment: .center)
                .frame(height: 260)
                .chartOverlay { proxy in
                    GeometryReader { geometry in
                        Rectangle().fill(Color.clear).contentShape(Rectangle())
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        let plotAreaFrame = geometry[proxy.plotAreaFrame]
                                        guard plotAreaFrame.contains(value.location) else {
                                            selectedEntry = nil
                                            return
                                        }

                                        let xPosition = value.location.x - plotAreaFrame.origin.x
                                        if let date: Date = proxy.value(atX: xPosition),
                                           let nearest = viewModel.nearestEntry(for: date),
                                           selectedEntry != nearest {
                                            selectedEntry = nearest
                                        }
                                    }
                                    .onEnded { _ in
                                        selectedEntry = nil
                                    }
                            )
                    }
                }
            }
        }
    }

    private func tooltipView(for entry: HomeBalanceDataPoint) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(entry.date, format: Date.FormatStyle().month(.abbreviated).day())
                .font(.caption)
                .foregroundStyle(.secondary)

            seriesRow(label: "Actual", value: entry.actualBalance, color: .blue)
            seriesRow(label: "If", value: entry.ifBalance, color: .green)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
        )
    }

    private func seriesRow(label: String, value: Int64, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(value.formatted(.currency(code: "JPY")))
                .font(.caption)
                .monospacedDigit()
        }
    }
}

private struct HomeSummaryCard: View {
    let summary: HomeMonthlySummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(summary.month, format: Date.FormatStyle().year().month(.wide))
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Text("Actual")
                Spacer()
                Text(summary.actualTotal.formatted(.currency(code: "JPY")))
                    .monospacedDigit()
            }
            HStack {
                Text("If")
                Spacer()
                Text(summary.ifTotal.formatted(.currency(code: "JPY")))
                    .monospacedDigit()
            }
            Divider()
            HStack {
                Text("差分")
                Spacer()
                Text(summary.difference.formatted(.currency(code: "JPY")))
                    .monospacedDigit()
                    .foregroundStyle(summary.difference >= 0 ? Color.green : Color.red)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [Profile.self, Race.self, Ticket.self], inMemory: true)
        .frame(maxWidth: 400)
}
