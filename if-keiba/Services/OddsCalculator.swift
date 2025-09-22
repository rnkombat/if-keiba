import Foundation

/// オッズや増額Ifに関する算出ロジックを提供するサービス。
public struct OddsCalculator {
    public struct IncreasedIfCalculation {
        public let stake: Int64
        public let payout: Int64?
        public let ratio: Double?
        public let delta: Int64

        public init(stake: Int64, payout: Int64?, ratio: Double?, delta: Int64) {
            self.stake = stake
            self.payout = payout
            self.ratio = ratio
            self.delta = delta
        }
    }

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

    /// ActualチケットからIfチケットを増額複製する際の倍率を計算します。
    /// - Parameters:
    ///   - stake: Actualチケットの賭金。
    ///   - payout: Actualチケットの払戻金。
    ///   - odds: Actualチケットのオッズ。
    /// - Returns: 複製時に利用する倍率（情報が不足している場合は `nil`）。
    public func calculateIncreaseRatio(stake: Int64, payout: Int64?, odds: Double?) -> Double? {
        guard stake > 0 else { return nil }
        if let payout { return Double(payout) / Double(stake) }
        if let odds, odds > 0 { return odds }
        return nil
    }

    /// Actualチケットを増額してIfチケットを作成する際の結果を計算します。
    /// - Parameters:
    ///   - baseStake: Actualチケットの賭金。
    ///   - basePayout: Actualチケットの払戻金。
    ///   - baseOdds: Actualチケットのオッズ。
    ///   - deltaStake: 追加投資額。
    ///   - roundingRule: 端数処理規則。
    ///   - rounding: 丸め処理ユーティリティ。
    /// - Returns: 増額後の賭金と払戻金のプレビュー。
    public func calculateIncreasedIf(
        baseStake: Int64,
        basePayout: Int64?,
        baseOdds: Double?,
        deltaStake: Int64,
        roundingRule: MoneyRoundingRule,
        rounding: MoneyRounding = MoneyRounding()
    ) -> IncreasedIfCalculation? {
        guard baseStake > 0 else { return nil }
        let sanitizedDelta = max(0, deltaStake)
        let newStake = baseStake + sanitizedDelta

        let ratio = calculateIncreaseRatio(stake: baseStake, payout: basePayout, odds: baseOdds)
        var payoutResult: Int64?
        if let ratio {
            let stakeDecimal = Decimal(newStake)
            let ratioDecimal = Decimal(ratio)
            let expected = stakeDecimal * ratioDecimal
            payoutResult = rounding.roundToCurrencyUnit(expected, rule: roundingRule)
        }

        return IncreasedIfCalculation(stake: newStake, payout: payoutResult, ratio: ratio, delta: sanitizedDelta)
    }
}
