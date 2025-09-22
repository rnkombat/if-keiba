import Foundation
import Combine

struct ReportsMonthlySummary: Identifiable, Equatable {
    let month: Date
    let actualTotal: Int64
    let ifTotal: Int64
    let actualChange: Int64
    let ifChange: Int64

    var id: Date { month }

    var difference: Int64 {
        ifTotal - actualTotal
    }
}

struct ReportsCumulativeSummary: Equatable {
    let initialBalance: Int64
    let actualTotal: Int64
    let actualPlusIfTotal: Int64

    var actualChange: Int64 { actualTotal - initialBalance }
    var actualPlusIfChange: Int64 { actualPlusIfTotal - initialBalance }
    var difference: Int64 { actualPlusIfTotal - actualTotal }
}

@MainActor
final class ReportsViewModel: ObservableObject {
    @Published private(set) var monthlySummaries: [ReportsMonthlySummary] = []
    @Published private(set) var cumulativeSummary: ReportsCumulativeSummary?

    private let balanceService: BalanceService

    init(balanceService: BalanceService = BalanceService()) {
        self.balanceService = balanceService
    }

    func update(races: [Race], profile: Profile?) {
        guard let profile else {
            monthlySummaries = []
            cumulativeSummary = nil
            return
        }

        let monthlyPoints = balanceService.monthlySeries(for: races, profile: profile)
        let summary = balanceService.summarize(races: races, profile: profile)
        cumulativeSummary = ReportsCumulativeSummary(
            initialBalance: profile.initialBalance,
            actualTotal: summary.finalActual,
            actualPlusIfTotal: summary.finalIf
        )

        guard !monthlyPoints.isEmpty else {
            monthlySummaries = []
            return
        }

        var summaries: [ReportsMonthlySummary] = []
        summaries.reserveCapacity(monthlyPoints.count)

        var previousActual = profile.initialBalance
        var previousIf = profile.initialBalance

        for point in monthlyPoints {
            let actualChange = point.actualBalance - previousActual
            let ifChange = point.ifBalance - previousIf
            let summary = ReportsMonthlySummary(
                month: point.date,
                actualTotal: point.actualBalance,
                ifTotal: point.ifBalance,
                actualChange: actualChange,
                ifChange: ifChange
            )
            summaries.append(summary)
            previousActual = point.actualBalance
            previousIf = point.ifBalance
        }

        monthlySummaries = summaries.sorted { $0.month > $1.month }
    }
}
