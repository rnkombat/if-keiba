// if-keiba/if-keiba/Services/CSVExporter.swift
import Foundation

struct CSVExportResult {
    let racesCSV: String
    let ticketsCSV: String
}

final class CSVExporter {
    // Race/Ticket はアプリ内型（internal）なので、ここも internal（デフォルト）で揃える
    func exportRaces(_ races: [Race]) -> String {
        var rows: [String] = ["raceId,date,name,memo,createdAt,updatedAt"]
        let df = ISO8601DateFormatter()
        for r in races {
            let id = r.id.uuidString
            let date = df.string(from: r.date)
            let name = (r.name ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let memo = (r.memo ?? "").replacingOccurrences(of: "\"", with: "\"\"")
            let created = df.string(from: r.createdAt)
            let updated = df.string(from: r.updatedAt)
            rows.append("\(id),\(date),\"\(name)\",\"\(memo)\",\(created),\(updated)")
        }
        return rows.joined(separator: "\n")
    }

    func exportTickets(_ tickets: [Ticket]) -> String {
        var rows: [String] = ["ticketId,raceId,kind,betType,stake,payout,odds,linkedActualId,selectionsJson,createdAt,updatedAt"]
        let df = ISO8601DateFormatter()
        for t in tickets {
            let id = t.id.uuidString
            let raceId = t.race?.id.uuidString ?? ""
            let kind = t.kind
            let betType = t.betType
            let stake = t.stake
            let payout = t.payout.map(String.init) ?? ""
            let odds = t.odds.map { String(format: "%.2f", $0) } ?? ""
            let linked = t.linkedActualId?.uuidString ?? ""
            let sel = t.selectionsJSON.replacingOccurrences(of: "\"", with: "\"\"")
            let created = df.string(from: t.createdAt)
            let updated = df.string(from: t.updatedAt)
            rows.append("\(id),\(raceId),\(kind),\(betType),\(stake),\(payout),\(odds),\(linked),\"\(sel)\",\(created),\(updated)")
        }
        return rows.joined(separator: "\n")
    }

    func exportAll(races: [Race], tickets: [Ticket]) -> CSVExportResult {
        CSVExportResult(
            racesCSV: exportRaces(races),
            ticketsCSV: exportTickets(tickets)
        )
    }
}
