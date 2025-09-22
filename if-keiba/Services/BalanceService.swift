import Foundation

/// 日次・月次などの残高系列を表すポイント。
public struct BalanceSeriesPoint: Hashable {
    public let date: Date
    public let actualBalance: Int64
    public let ifBalance: Int64
    public let actualProfit: Int64
    public let ifProfit: Int64
    public let actualTotalStake: Int64
    public let actualTotalPayout: Int64
    public let ifTotalStake: Int64
    public let ifTotalPayout: Int64

    public init(
        date: Date,
        actualBalance: Int64,
        ifBalance: Int64,
        actualProfit: Int64,
        ifProfit: Int64,
        actualTotalStake: Int64,
        actualTotalPayout: Int64,
        ifTotalStake: Int64,
        ifTotalPayout: Int64
    ) {
        self.date = date
        self.actualBalance = actualBalance
        self.ifBalance = ifBalance
        self.actualProfit = actualProfit
        self.ifProfit = ifProfit
        self.actualTotalStake = actualTotalStake
        self.actualTotalPayout = actualTotalPayout
        self.ifTotalStake = ifTotalStake
        self.ifTotalPayout = ifTotalPayout
    }
}

/// 残高に関する概要値。
public struct BalanceSummary {
    public let finalActual: Int64
    public let finalIf: Int64

    public init(finalActual: Int64, finalIf: Int64) {
        self.finalActual = finalActual
        self.finalIf = finalIf
    }
}

/// レース・投票情報から残高系列を算出するサービス。
public final class BalanceService {
    private enum GroupingUnit {
        case day
        case month
        case year
    }

    private struct AggregatedChange {
        var actualNet: Int64 = 0
        var ifNet: Int64 = 0
        var actualStake: Int64 = 0
        var actualPayout: Int64 = 0
        var ifStake: Int64 = 0
        var ifPayout: Int64 = 0
    }

    private let calendar: Calendar

    public init(calendar: Calendar = Calendar(identifier: .gregorian)) {
        self.calendar = calendar
    }

    /// 日次の残高推移を算出します。
    /// - Parameters:
    ///   - races: 対象となるレース一覧。
    ///   - profile: 初期残高などの設定を保持するプロフィール。
    /// - Returns: 日次の残高ポイント列。
    func dailySeries(for races: [Race], profile: Profile) -> [BalanceSeriesPoint] {
        computeSeries(grouping: .day, races: races, profile: profile)
    }

    /// 月次の残高推移を算出します。
    /// - Parameters:
    ///   - races: 対象となるレース一覧。
    ///   - profile: 初期残高などの設定を保持するプロフィール。
    /// - Returns: 月次の残高ポイント列。
    func monthlySeries(for races: [Race], profile: Profile) -> [BalanceSeriesPoint] {
        computeSeries(grouping: .month, races: races, profile: profile)
    }

    /// 年次の残高推移を算出します。
    /// - Parameters:
    ///   - races: 対象となるレース一覧。
    ///   - profile: 初期残高などの設定を保持するプロフィール。
    /// - Returns: 年次の残高ポイント列。
    func yearlySeries(for races: [Race], profile: Profile) -> [BalanceSeriesPoint] {
        computeSeries(grouping: .year, races: races, profile: profile)
    }

    /// 総括値（最終残高など）を算出します。
    /// - Parameters:
    ///   - races: 対象となるレース一覧。
    ///   - profile: 初期残高などの設定を保持するプロフィール。
    /// - Returns: 最終的な残高サマリー。
    func summarize(races: [Race], profile: Profile) -> BalanceSummary {
        let dailyPoints = dailySeries(for: races, profile: profile)
        guard let last = dailyPoints.last else {
            return BalanceSummary(finalActual: profile.initialBalance, finalIf: profile.initialBalance)
        }
        return BalanceSummary(finalActual: last.actualBalance, finalIf: last.ifBalance)
    }

    // MARK: - Private

    private func computeSeries(grouping: GroupingUnit, races: [Race], profile: Profile) -> [BalanceSeriesPoint] {
        let groupedChanges = aggregateChanges(grouping: grouping, races: races)
        let initialBalance = profile.initialBalance

        guard let range = determineDateRange(grouping: grouping, races: races, groupedChanges: groupedChanges) else {
            let referenceDate = normalize(date: profile.createdAt, grouping: grouping)
            return [
                BalanceSeriesPoint(
                    date: referenceDate,
                    actualBalance: initialBalance,
                    ifBalance: initialBalance,
                    actualProfit: 0,
                    ifProfit: 0,
                    actualTotalStake: 0,
                    actualTotalPayout: 0,
                    ifTotalStake: 0,
                    ifTotalPayout: 0
                )
            ]
        }

        var results: [BalanceSeriesPoint] = []
        results.reserveCapacity(groupedChanges.count + 1)

        var runningActualNet: Int64 = 0
        var runningIfNet: Int64 = 0
        var runningActualStake: Int64 = 0
        var runningActualPayout: Int64 = 0
        var runningIfStake: Int64 = 0
        var runningIfPayout: Int64 = 0

        var current = range.start
        while current <= range.end {
            let delta = groupedChanges[current] ?? AggregatedChange()
            runningActualNet += delta.actualNet
            runningIfNet += delta.ifNet
            runningActualStake += delta.actualStake
            runningActualPayout += delta.actualPayout
            runningIfStake += delta.ifStake
            runningIfPayout += delta.ifPayout

            let actualBalance = initialBalance + runningActualNet
            let ifBalance = initialBalance + runningActualNet + runningIfNet
            let actualProfit = runningActualNet
            let ifProfit = runningActualNet + runningIfNet

            results.append(
                BalanceSeriesPoint(
                    date: current,
                    actualBalance: actualBalance,
                    ifBalance: ifBalance,
                    actualProfit: actualProfit,
                    ifProfit: ifProfit,
                    actualTotalStake: runningActualStake,
                    actualTotalPayout: runningActualPayout,
                    ifTotalStake: runningIfStake,
                    ifTotalPayout: runningIfPayout
                )
            )

            guard let next = increment(date: current, grouping: grouping) else { break }
            current = next
        }

        return results
    }

    private func aggregateChanges(grouping: GroupingUnit, races: [Race]) -> [Date: AggregatedChange] {
        var changes: [Date: AggregatedChange] = [:]

        for race in races {
            let normalizedDate = normalize(date: race.date, grouping: grouping)
            var change = changes[normalizedDate] ?? AggregatedChange()

            for ticket in race.tickets {
                let net = (ticket.payout ?? 0) - ticket.stake
                let payoutValue = ticket.payout ?? 0
                switch ticket.kind {
                case 0: // Actual
                    change.actualNet += net
                    change.actualStake += ticket.stake
                    change.actualPayout += payoutValue
                case 1: // If
                    change.ifNet += net
                    change.ifStake += ticket.stake
                    change.ifPayout += payoutValue
                default:
                    continue
                }
            }

            changes[normalizedDate] = change
        }

        return changes
    }

    private func normalize(date: Date, grouping: GroupingUnit) -> Date {
        switch grouping {
        case .day:
            return calendar.startOfDay(for: date)
        case .month:
            var components = calendar.dateComponents([.year, .month], from: date)
            components.day = 1
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        case .year:
            var components = calendar.dateComponents([.year], from: date)
            components.month = 1
            components.day = 1
            return calendar.date(from: components) ?? calendar.startOfDay(for: date)
        }
    }

    private func increment(date: Date, grouping: GroupingUnit) -> Date? {
        switch grouping {
        case .day:
            return calendar.date(byAdding: .day, value: 1, to: date)
        case .month:
            return calendar.date(byAdding: .month, value: 1, to: date)
        case .year:
            return calendar.date(byAdding: .year, value: 1, to: date)
        }
    }

    private struct DateRange {
        let start: Date
        let end: Date
    }

    private func determineDateRange(grouping: GroupingUnit, races: [Race], groupedChanges: [Date: AggregatedChange]) -> DateRange? {
        if let minChange = groupedChanges.keys.min(), let maxChange = groupedChanges.keys.max() {
            return DateRange(start: minChange, end: maxChange)
        }

        guard let reference = races.map({ normalize(date: $0.date, grouping: grouping) }).min() else {
            return nil
        }

        return DateRange(start: reference, end: reference)
    }
}
