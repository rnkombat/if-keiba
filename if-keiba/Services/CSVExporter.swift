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
    private let dateFormatter: ISO8601DateFormatter
    private let doubleFormatter: NumberFormatter

    public init(
        dateFormatter: ISO8601DateFormatter? = nil,
        doubleFormatter: NumberFormatter? = nil
    ) {
        self.dateFormatter = dateFormatter ?? Self.makeDateFormatter()
        self.doubleFormatter = doubleFormatter ?? Self.makeDoubleFormatter()
    }

    /// レース情報を CSV 文字列に変換します。
    /// - Parameter races: 書き出し対象のレース一覧。
    /// - Returns: 仕様に沿った CSV 文字列。
    public func exportRaces(_ races: [Race]) -> String {
        let header = "raceId,date,name,memo,createdAt,updatedAt"
        let sortedRaces = races.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                if lhs.createdAt == rhs.createdAt {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.createdAt < rhs.createdAt
            }
            return lhs.date < rhs.date
        }

        let rows = sortedRaces.map { race -> String in
            let rawFields: [String] = [
                race.id.uuidString,
                format(date: race.date),
                race.name ?? "",
                race.memo ?? "",
                format(date: race.createdAt),
                format(date: race.updatedAt)
            ]
            return rawFields.map(escape).joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n") + "\n"
    }

    /// 投票情報を CSV 文字列に変換します。
    /// - Parameter tickets: 書き出し対象の投票一覧。
    /// - Returns: 仕様に沿った CSV 文字列。
    public func exportTickets(_ tickets: [Ticket]) -> String {
        let header = "ticketId,raceId,kind,betType,stake,payout,odds,linkedActualId,selectionsJson,createdAt,updatedAt"
        let sortedTickets = tickets.sorted { lhs, rhs in
            if lhs.createdAt == rhs.createdAt {
                return lhs.id.uuidString < rhs.id.uuidString
            }
            return lhs.createdAt < rhs.createdAt
        }

        let rows = sortedTickets.map { ticket -> String in
            let rawFields: [String] = [
                ticket.id.uuidString,
                ticket.race?.id.uuidString ?? "",
                String(ticket.kind),
                String(ticket.betType),
                String(ticket.stake),
                ticket.payout.map(String.init) ?? "",
                ticket.odds.flatMap(format(double:)) ?? "",
                ticket.linkedActualId?.uuidString ?? "",
                ticket.selectionsJSON,
                format(date: ticket.createdAt),
                format(date: ticket.updatedAt)
            ]
            return rawFields.map(escape).joined(separator: ",")
        }

        return ([header] + rows).joined(separator: "\n") + "\n"
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

    // MARK: - Private Helpers

    private static func makeDateFormatter() -> ISO8601DateFormatter {
        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }

    private static func makeDoubleFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 6
        formatter.usesGroupingSeparator = false
        return formatter
    }

    private func format(date: Date) -> String {
        dateFormatter.string(from: date)
    }

    private func format(double value: Double) -> String? {
        doubleFormatter.string(from: NSNumber(value: value))
    }

    private func escape(_ value: String) -> String {
        guard value.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" || $0 == "\r" }) else {
            return value
        }
        var escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        escaped = "\"" + escaped + "\""
        return escaped
    }
}
