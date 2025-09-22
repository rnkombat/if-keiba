import Foundation

struct HomeBalanceDataPoint: Identifiable, Equatable {
    let date: Date
    let actualBalance: Int64
    let ifBalance: Int64

    var id: Date { date }
}

struct HomeMonthlySummary {
    let month: Date
    let actualTotal: Int64
    let ifTotal: Int64

    var difference: Int64 {
        ifTotal - actualTotal
    }
}

final class HomeViewModel: ObservableObject {
    @Published private(set) var dailySeries: [HomeBalanceDataPoint]
    @Published private(set) var monthlySummary: HomeMonthlySummary

    init(currentDate: Date = .now) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents([.year, .month], from: currentDate)
        let startOfMonth = calendar.date(from: components) ?? currentDate

        var series: [HomeBalanceDataPoint] = []
        var actualRunning: Int64 = 100_000
        var ifRunning: Int64 = 100_000

        for dayOffset in 0..<10 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: startOfMonth) else { continue }

            let actualDelta = Int64(dayOffset * 1_200 - (dayOffset / 3) * 700)
            let ifDelta = Int64(dayOffset * 1_400 - (dayOffset / 4) * 500)

            actualRunning += actualDelta
            ifRunning += ifDelta

            let point = HomeBalanceDataPoint(
                date: date,
                actualBalance: actualRunning,
                ifBalance: ifRunning
            )
            series.append(point)
        }

        self.dailySeries = series
        let lastPoint = series.last ?? HomeBalanceDataPoint(date: startOfMonth, actualBalance: actualRunning, ifBalance: ifRunning)
        self.monthlySummary = HomeMonthlySummary(
            month: startOfMonth,
            actualTotal: lastPoint.actualBalance,
            ifTotal: lastPoint.ifBalance
        )
    }

    func nearestEntry(for date: Date) -> HomeBalanceDataPoint? {
        guard !dailySeries.isEmpty else { return nil }
        return dailySeries.min(by: { lhs, rhs in
            abs(lhs.date.timeIntervalSince(date)) < abs(rhs.date.timeIntervalSince(date))
        })
    }
}
