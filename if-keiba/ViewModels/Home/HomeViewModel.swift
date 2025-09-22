import Foundation
import Combine

struct HomeBalanceDataPoint: Identifiable, Equatable {
    let date: Date
    let actualBalance: Int64
    let ifBalance: Int64

    var id: Date { date }
}

struct HomeMonthlySummary: Equatable {
    let month: Date
    let actualTotal: Int64
    let ifTotal: Int64

    var difference: Int64 {
        ifTotal - actualTotal
    }
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published private(set) var dailySeries: [HomeBalanceDataPoint] = []
    @Published private(set) var monthlySummary: HomeMonthlySummary?

    private let balanceService: BalanceService
    private let calendar: Calendar

    init(balanceService: BalanceService = BalanceService(), calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.balanceService = balanceService
        self.calendar = calendar
    }

    func update(races: [Race], profile: Profile?) {
        guard let profile else {
            dailySeries = []
            monthlySummary = nil
            return
        }

        let dailyPoints = balanceService.dailySeries(for: races, profile: profile)
        dailySeries = dailyPoints.map { point in
            HomeBalanceDataPoint(date: point.date, actualBalance: point.actualBalance, ifBalance: point.ifBalance)
        }

        let targetMonth = calendar.dateComponents([.year, .month], from: Date())
        let monthAnchor = calendar.date(from: targetMonth) ?? Date()

        if let monthSpecific = dailyPoints.last(where: { calendar.isDate($0.date, equalTo: monthAnchor, toGranularity: .month) }) {
            monthlySummary = HomeMonthlySummary(
                month: monthSpecific.date,
                actualTotal: monthSpecific.actualBalance,
                ifTotal: monthSpecific.ifBalance
            )
        } else if let latest = dailyPoints.last {
            monthlySummary = HomeMonthlySummary(
                month: monthAnchor,
                actualTotal: latest.actualBalance,
                ifTotal: latest.ifBalance
            )
        } else {
            monthlySummary = HomeMonthlySummary(
                month: monthAnchor,
                actualTotal: profile.initialBalance,
                ifTotal: profile.initialBalance
            )
        }
    }

    func nearestEntry(for date: Date) -> HomeBalanceDataPoint? {
        guard !dailySeries.isEmpty else { return nil }
        return dailySeries.min(by: { lhs, rhs in
            abs(lhs.date.timeIntervalSince(date)) < abs(rhs.date.timeIntervalSince(date))
        })
    }
}
