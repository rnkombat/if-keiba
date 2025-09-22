import Foundation

/// 端数処理に利用する丸め規則。
public enum MoneyRoundingRule: Int16, CaseIterable {
    case nearest = 0
    case up = 1
    case down = 2

    /// 画面表示向けの名称。
    public var displayName: String {
        switch self {
        case .nearest:
            return "四捨五入"
        case .up:
            return "切り上げ"
        case .down:
            return "切り捨て"
        }
    }

    fileprivate var roundingMode: NSDecimalNumber.RoundingMode {
        switch self {
        case .nearest:
            return .plain
        case .up:
            return .up
        case .down:
            return .down
        }
    }
}

/// 金額に関する丸め処理を担当するユーティリティ。
public struct MoneyRounding {
    public init() {}

    /// 指定した丸め規則を使って `Decimal` 値を丸めます。
    /// - Parameters:
    ///   - amount: 丸め対象となる値。
    ///   - rule: 適用する丸め規則。
    /// - Returns: 丸め処理後の値。
    public func round(amount: Decimal, rule: MoneyRoundingRule) -> Decimal {
        var mutableAmount = amount
        var result = Decimal()
        NSDecimalRound(&result, &mutableAmount, 0, rule.roundingMode)
        return result
    }

    /// 指定した丸め規則を使って `Double` 値を丸めます。
    /// - Parameters:
    ///   - amount: 丸め対象となる値。
    ///   - rule: 適用する丸め規則。
    /// - Returns: 丸め処理後の値。
    public func round(amount: Double, rule: MoneyRoundingRule) -> Double {
        let decimalResult = round(amount: Decimal(amount), rule: rule)
        return NSDecimalNumber(decimal: decimalResult).doubleValue
    }

    /// 通貨金額を表す `Decimal` を丸め、整数（最小通貨単位）として返します。
    /// - Parameters:
    ///   - amount: 丸め対象となる金額。
    ///   - rule: 適用する丸め規則。
    /// - Returns: 丸め処理後の金額。
    public func roundToCurrencyUnit(_ amount: Decimal, rule: MoneyRoundingRule) -> Int64 {
        let decimalResult = round(amount: amount, rule: rule)
        return NSDecimalNumber(decimal: decimalResult).int64Value
    }
}
