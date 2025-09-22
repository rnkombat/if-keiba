import Foundation

/// 日次・月次などの残高系列を表すポイント。
public struct BalanceSeriesPoint: Hashable {
    public let date: Date
    public let actualBalance: Int64
    public let ifBalance: Int64

    public init(date: Date, actualBalance: Int64, ifBalance: Int64) {
        self.date = date
        self.actualBalance = actualBalance
        self.ifBalance = ifBalance
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
    public init() {}

    /// 日次の残高推移を算出します。
    /// - Parameters:
    ///   - races: 対象となるレース一覧。
    ///   - profile: 初期残高などの設定を保持するプロフィール。
    /// - Returns: 日次の残高ポイント列（ダミー実装では空配列）。
    func dailySeries(for races: [Race], profile: Profile) -> [BalanceSeriesPoint] {
        // TODO: 実際の残高計算を実装する。
        return []
    }

    /// 月次の残高推移を算出します。
    /// - Parameters:
    ///   - races: 対象となるレース一覧。
    ///   - profile: 初期残高などの設定を保持するプロフィール。
    /// - Returns: 月次の残高ポイント列（ダミー実装では空配列）。
    func monthlySeries(for races: [Race], profile: Profile) -> [BalanceSeriesPoint] {
        // TODO: 実際の残高計算を実装する。
        return []
    }

    /// 年次の残高推移を算出します。
    /// - Parameters:
    ///   - races: 対象となるレース一覧。
    ///   - profile: 初期残高などの設定を保持するプロフィール。
    /// - Returns: 年次の残高ポイント列（ダミー実装では空配列）。
    func yearlySeries(for races: [Race], profile: Profile) -> [BalanceSeriesPoint] {
        // TODO: 実際の残高計算を実装する。
        return []
    }

    /// 総括値（最終残高など）を算出します。
    /// - Parameters:
    ///   - races: 対象となるレース一覧。
    ///   - profile: 初期残高などの設定を保持するプロフィール。
    /// - Returns: 最終的な残高サマリー（ダミー実装では初期値のみ）。
    func summarize(races: [Race], profile: Profile) -> BalanceSummary {
        // TODO: 実際の残高計算を実装する。
        return BalanceSummary(finalActual: profile.initialBalance, finalIf: profile.initialBalance)
    }
}
