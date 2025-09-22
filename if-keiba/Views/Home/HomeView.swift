import SwiftData
import SwiftUI
import Charts

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()
    @State private var selectedEntry: HomeBalanceDataPoint?
    @State private var chartKind: ChartKind = .balance
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

    private enum ChartKind: String, CaseIterable, Identifiable {
        case balance
        case profit
        case returnRate

        var id: String { rawValue }

        var title: String {
            switch self {
            case .balance:
                return "日次残高"
            case .profit:
                return "日次収支"
            case .returnRate:
                return "回収率"
            }
        }

        var pickerLabel: String {
            switch self {
            case .balance:
                return "残高"
            case .profit:
                return "収支"
            case .returnRate:
                return "回収率"
            }
        }
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
        .onChange(of: chartKind) { _ in
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
            Text(chartKind.title)
                .font(.headline)

            Picker("", selection: $chartKind) {
                ForEach(ChartKind.allCases) { kind in
                    Text(kind.pickerLabel).tag(kind)
                }
            }
            .pickerStyle(.segmented)

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
                        switch chartKind {
                        case .balance:
                            LineMark(
                                x: .value("日付", point.date),
                                y: .value("Actual", point.actualBalance)
                            )
                            .foregroundStyle(by: .value("系列", "Actual"))
                            .interpolationMethod(.linear)

                            LineMark(
                                x: .value("日付", point.date),
                                y: .value("Actual + If", point.ifBalance)
                            )
                            .foregroundStyle(by: .value("系列", "Actual + If"))
                            .interpolationMethod(.linear)
                        case .profit:
                            LineMark(
                                x: .value("日付", point.date),
                                y: .value("Actual", point.actualProfit)
                            )
                            .foregroundStyle(by: .value("系列", "Actual"))
                            .interpolationMethod(.linear)

                            LineMark(
                                x: .value("日付", point.date),
                                y: .value("Actual + If", point.ifProfit)
                            )
                            .foregroundStyle(by: .value("系列", "Actual + If"))
                            .interpolationMethod(.linear)
                        case .returnRate:
                            if let actualRate = point.actualReturnRate {
                                LineMark(
                                    x: .value("日付", point.date),
                                    y: .value("Actual", actualRate)
                                )
                                .foregroundStyle(by: .value("系列", "Actual"))
                                .interpolationMethod(.linear)
                            }

                            if let ifRate = point.ifReturnRate {
                                LineMark(
                                    x: .value("日付", point.date),
                                    y: .value("Actual + If", ifRate)
                                )
                                .foregroundStyle(by: .value("系列", "Actual + If"))
                                .interpolationMethod(.linear)
                            }
                        }
                    }

                    if let selectedEntry {
                        RuleMark(x: .value("日付", selectedEntry.date))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [3]))
                            .foregroundStyle(.secondary)
                            .annotation(position: .topLeading) {
                                tooltipView(for: selectedEntry)
                            }

                        switch chartKind {
                        case .balance:
                            PointMark(
                                x: .value("日付", selectedEntry.date),
                                y: .value("Actual", selectedEntry.actualBalance)
                            )
                            .foregroundStyle(Color.blue)
                            .symbolSize(70)

                            PointMark(
                                x: .value("日付", selectedEntry.date),
                                y: .value("Actual + If", selectedEntry.ifBalance)
                            )
                            .foregroundStyle(Color.green)
                            .symbolSize(70)
                        case .profit:
                            PointMark(
                                x: .value("日付", selectedEntry.date),
                                y: .value("Actual", selectedEntry.actualProfit)
                            )
                            .foregroundStyle(Color.blue)
                            .symbolSize(70)

                            PointMark(
                                x: .value("日付", selectedEntry.date),
                                y: .value("Actual + If", selectedEntry.ifProfit)
                            )
                            .foregroundStyle(Color.green)
                            .symbolSize(70)
                        case .returnRate:
                            if let actualRate = selectedEntry.actualReturnRate {
                                PointMark(
                                    x: .value("日付", selectedEntry.date),
                                    y: .value("Actual", actualRate)
                                )
                                .foregroundStyle(Color.blue)
                                .symbolSize(70)
                            }

                            if let ifRate = selectedEntry.ifReturnRate {
                                PointMark(
                                    x: .value("日付", selectedEntry.date),
                                    y: .value("Actual + If", ifRate)
                                )
                                .foregroundStyle(Color.green)
                                .symbolSize(70)
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        if chartKind == .returnRate, let rate = value.as(Double.self) {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                Text(rate, format: .percent.precision(.fractionLength(0...1)))
                                    .monospacedDigit()
                            }
                        } else {
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel()
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 5))
                }
                .chartForegroundStyleScale([
                    "Actual": Color.blue,
                    "Actual + If": Color.green
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

            switch chartKind {
            case .balance:
                seriesRow(label: "Actual", valueText: formattedCurrency(entry.actualBalance), color: .blue)
                seriesRow(label: "Actual + If", valueText: formattedCurrency(entry.ifBalance), color: .green)
            case .profit:
                seriesRow(label: "Actual", valueText: formattedCurrency(entry.actualProfit), color: .blue)
                seriesRow(label: "Actual + If", valueText: formattedCurrency(entry.ifProfit), color: .green)
            case .returnRate:
                seriesRow(label: "Actual", valueText: formattedPercent(entry.actualReturnRate), color: .blue)
                seriesRow(label: "Actual + If", valueText: formattedPercent(entry.ifReturnRate), color: .green)
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)
        )
    }

    private func formattedCurrency(_ value: Int64) -> String {
        value.formatted(.currency(code: "JPY"))
    }

    private func formattedPercent(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value.formatted(.percent.precision(.fractionLength(0...1)))
    }

    private func seriesRow(label: String, valueText: String, color: Color) -> some View {
        HStack(spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()

            Text(valueText)
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
                Text("Actual + If")
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
