import Foundation

/// 端数処理に利用する丸め規則。
public enum MoneyRoundingRule: Int16 {
    case nearest = 0
    case up = 1
    case down = 2
}

/// 金額に関する丸め処理を担当するユーティリティ。
public struct MoneyRounding {
    public init() {}

    /// 指定した丸め規則を使って `Decimal` 値を丸めます。
    /// - Parameters:
    ///   - amount: 丸め対象となる値。
    ///   - rule: 適用する丸め規則。
    /// - Returns: 丸め処理後の値（ダミー実装では入力値をそのまま返します）。
    public func round(amount: Decimal, rule: MoneyRoundingRule) -> Decimal {
        // TODO: 仕様に沿った丸め処理を実装する。
        return amount
    }

    /// 指定した丸め規則を使って `Double` 値を丸めます。
    /// - Parameters:
    ///   - amount: 丸め対象となる値。
    ///   - rule: 適用する丸め規則。
    /// - Returns: 丸め処理後の値（ダミー実装では入力値をそのまま返します）。
    public func round(amount: Double, rule: MoneyRoundingRule) -> Double {
        let decimalResult = round(amount: Decimal(amount), rule: rule)
        return NSDecimalNumber(decimal: decimalResult).doubleValue
    }

    /// 通貨金額を表す `Decimal` を丸め、整数（最小通貨単位）として返します。
    /// - Parameters:
    ///   - amount: 丸め対象となる金額。
    ///   - rule: 適用する丸め規則。
    /// - Returns: 丸め処理後の金額（ダミー実装では単純に整数変換した値を返します）。
    public func roundToCurrencyUnit(_ amount: Decimal, rule: MoneyRoundingRule) -> Int64 {
        let decimalResult = round(amount: amount, rule: rule)
        return NSDecimalNumber(decimal: decimalResult).int64Value
    }
}
