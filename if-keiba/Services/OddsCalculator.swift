import Foundation

/// オッズや増額Ifに関する算出ロジックを提供するサービス。
public struct OddsCalculator {
    public init() {}

    /// Actual の投資額とオッズから想定払戻金を算出します。
    /// - Parameters:
    ///   - stake: 投資額。
    ///   - odds: オッズ（未設定の場合は `nil`）。
    /// - Returns: 想定払戻金（ダミー実装では入力値を利用した単純計算）。
    public func calculatePayout(stake: Int64, odds: Double?) -> Int64 {
        guard let odds else { return stake }
        // TODO: 実際の計算仕様に合わせて実装する。
        return Int64(Double(stake) * odds)
    }

    /// If 投票の増額ロジックを適用した投資額を算出します。
    /// - Parameters:
    ///   - baseStake: 基準となる Actual 投資額。
    ///   - increaseRate: 増額率（1.0 で増額なし）。
    /// - Returns: 増額後の投資額（ダミー実装では単純な乗算結果）。
    public func calculateIncreasedStake(baseStake: Int64, increaseRate: Double) -> Int64 {
        // TODO: 仕様に沿った増額ロジックを実装する。
        return Int64(Double(baseStake) * increaseRate)
    }

    /// 払戻金と投資額から収益率を算出します。
    /// - Parameters:
    ///   - stake: 投資額。
    ///   - payout: 払戻金。
    /// - Returns: 収益率（ダミー実装では単純比率）。
    public func calculateReturnRate(stake: Int64, payout: Int64) -> Double {
        guard stake != 0 else { return 0 }
        // TODO: 仕様に沿った収益率計算を実装する。
        return Double(payout) / Double(stake)
    }
}
