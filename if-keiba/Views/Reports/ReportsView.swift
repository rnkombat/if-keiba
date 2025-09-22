import SwiftData
import SwiftUI

struct ReportsView: View {
    @StateObject private var viewModel = ReportsViewModel()
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
            }
            .listStyle(.insetGrouped)
            .navigationTitle("月次レポート")
        }
        .task(id: dataSignature) {
            await MainActor.run {
                viewModel.update(races: races, profile: profiles.first)
            }
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
                title: "If",
                total: summary.ifTotal,
                change: summary.ifChange,
                accent: .green
            )
        }
        .padding(.vertical, 8)
    }

    private func valueRow(title: String, total: Int64, change: Int64, accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 8) {
                Circle()
                    .fill(accent)
                    .frame(width: 8, height: 8)
                Text(title)
                Spacer()
                Text(total.formatted(.currency(code: "JPY")))
                    .monospacedDigit()
            }

            let formattedChange = change.formatted(.currency(code: "JPY"))
            let prefix: String
            if change > 0 {
                prefix = "+"
            } else if change < 0 {
                prefix = ""
            } else {
                prefix = "±"
            }
            Text("前月比 \(prefix)\(formattedChange)")
                .font(.caption)
                .foregroundStyle(change == 0 ? Color.secondary : (change > 0 ? Color.green : Color.red))
                .monospacedDigit()
        }
    }
}

#Preview {
    ReportsView()
        .modelContainer(for: [Profile.self, Race.self, Ticket.self], inMemory: true)
}
