import SwiftData
import SwiftUI

struct ReportsView: View {
    private enum DisplayMode: Hashable {
        case monthly
        case cumulative
    }

    @StateObject private var viewModel = ReportsViewModel()
    @State private var displayMode: DisplayMode = .monthly
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
        NavigationStack {
            List {
                Section {
                    Picker("表示", selection: $displayMode) {
                        Text("月次").tag(DisplayMode.monthly)
                        Text("累計").tag(DisplayMode.cumulative)
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
                .listRowBackground(Color.clear)

                switch displayMode {
                case .monthly:
                    if viewModel.monthlySummaries.isEmpty {
                        ContentUnavailableView(
                            "月次データがありません",
                            systemImage: "calendar.badge.exclamationmark",
                            description: Text("レースとチケットを登録すると集計が表示されます")
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    } else {
                        Section("月次サマリー") {
                            ForEach(viewModel.monthlySummaries) { summary in
                                ReportsMonthlyRow(summary: summary)
                            }
                        }
                    }
                case .cumulative:
                    if let summary = viewModel.cumulativeSummary {
                        Section("累計サマリー") {
                            ReportsCumulativeSummaryView(summary: summary)
                        }
                    } else {
                        ContentUnavailableView(
                            "累計データがありません",
                            systemImage: "chart.line.uptrend.xyaxis",
                            description: Text("レースとチケットを登録すると集計が表示されます")
                        )
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(displayMode == .monthly ? "月次レポート" : "累計レポート")
        }
        .task(id: dataSignature) {
            // ReportsViewModel は @MainActor。ViewBuilder 内ではないので通常呼びでOK。
            viewModel.update(races: races, profile: profiles.first)
        }
    }
}

private struct ReportsMonthlyRow: View {
    let summary: ReportsMonthlySummary

    private var monthFormatter: Date.FormatStyle {
        Date.FormatStyle()
            .year()
            .month(.wide)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(summary.month, format: monthFormatter)
                    .font(.headline)
                Spacer()
                Text(summary.difference.formatted(.currency(code: "JPY")))
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(summary.difference >= 0 ? Color.green : Color.red)
            }

            valueRow(
                title: "Actual",
                total: summary.actualTotal,
                change: summary.actualChange,
                accent: .blue
            )

            valueRow(
                title: "Actual + If",
                total: summary.ifTotal,
                change: summary.ifChange,
                accent: .green
            )
        }
        .padding(.vertical, 8)
    }

    private func valueRow(title: String, total: Int64, change: Int64, accent: Color) -> some View {
        // ← ここで文字列と色を計算しておくのがポイント（ViewBuilder外）
        let formattedTotal = total.formatted(.currency(code: "JPY"))
        let formattedChange = change.formatted(.currency(code: "JPY"))
        let prefix = change > 0 ? "+" : (change < 0 ? "" : "±")
        let changeColor: Color = change == 0 ? .secondary : (change > 0 ? .green : .red)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                Text(title)
                Spacer()
                Text(formattedTotal)
                    .monospacedDigit()
            }

            Text("前月比 \(prefix)\(formattedChange)")
                .font(.caption)
                .foregroundStyle(changeColor)
                .monospacedDigit()
        }
    }
}

private struct ReportsCumulativeSummaryView: View {
    let summary: ReportsCumulativeSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("累計")
                    .font(.headline)
                Spacer()
                Text(summary.difference.formatted(.currency(code: "JPY")))
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(summary.difference >= 0 ? Color.green : Color.red)
            }

            valueRow(
                title: "Actual",
                total: summary.actualTotal,
                change: summary.actualChange,
                accent: .blue
            )

            valueRow(
                title: "Actual + If",
                total: summary.actualPlusIfTotal,
                change: summary.actualPlusIfChange,
                accent: .green
            )
        }
        .padding(.vertical, 8)
    }

    private func valueRow(title: String, total: Int64, change: Int64, accent: Color) -> some View {
        let formattedTotal = total.formatted(.currency(code: "JPY"))
        let formattedChange = change.formatted(.currency(code: "JPY"))
        let prefix = change > 0 ? "+" : (change < 0 ? "" : "±")
        let changeColor: Color = change == 0 ? .secondary : (change > 0 ? .green : .red)

        return VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                Text(title)
                Spacer()
                Text(formattedTotal)
                    .monospacedDigit()
            }

            Text("初期比 \(prefix)\(formattedChange)")
                .font(.caption)
                .foregroundStyle(changeColor)
                .monospacedDigit()
        }
    }
}

#Preview {
    ReportsView()
        .modelContainer(for: [Profile.self, Race.self, Ticket.self], inMemory: true)
}
