import Foundation

/// CSV 出力の結果を表す構造体。
public struct CSVExportResult {
    public let racesCSV: String
    public let ticketsCSV: String

    public init(racesCSV: String, ticketsCSV: String) {
        self.racesCSV = racesCSV
        self.ticketsCSV = ticketsCSV
    }
}

/// SwiftData で管理しているデータを CSV 形式に変換するエクスポータ。
public struct CSVExporter {
    public init() {}

    /// レース情報を CSV 文字列に変換します。
    /// - Parameter races: 書き出し対象のレース一覧。
    /// - Returns: 仕様に沿った CSV 文字列（ダミー実装ではヘッダーのみ）。
    public func exportRaces(_ races: [Race]) -> String {
        // TODO: レース情報のシリアライズを実装する。
        return "raceId,date,name,memo,createdAt,updatedAt\n"
    }

    /// 投票情報を CSV 文字列に変換します。
    /// - Parameter tickets: 書き出し対象の投票一覧。
    /// - Returns: 仕様に沿った CSV 文字列（ダミー実装ではヘッダーのみ）。
    public func exportTickets(_ tickets: [Ticket]) -> String {
        // TODO: 投票情報のシリアライズを実装する。
        return "ticketId,raceId,kind,betType,stake,payout,odds,linkedActualId,selectionsJson,createdAt,updatedAt\n"
    }

    /// レース・投票の CSV をまとめて生成します。
    /// - Parameters:
    ///   - races: レース一覧。
    ///   - tickets: 投票一覧。
    /// - Returns: 各 CSV の文字列をまとめた結果。
    public func exportAll(races: [Race], tickets: [Ticket]) -> CSVExportResult {
        let racesCSV = exportRaces(races)
        let ticketsCSV = exportTickets(tickets)
        return CSVExportResult(racesCSV: racesCSV, ticketsCSV: ticketsCSV)
    }
}
