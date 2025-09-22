// if-keiba/if-keiba/Models/Ticket.swift
import Foundation
import SwiftData

@Model
final class Ticket {
    @Attribute(.unique) var id: UUID
    var race: Race?                        // 片側が nil でも一応許容
    var kind: Int16                        // 0: Actual, 1: If
    var betType: Int16                     // 0: 単勝, 1: 複勝, ...
    var selectionsJSON: String             // 柔軟性のため JSON 文字列
    var stake: Int64
    var payout: Int64?
    var odds: Double?
    var linkedActualId: UUID?
    var createdAt: Date
    var updatedAt: Date

    init(race: Race?,
         kind: Int16,
         betType: Int16,
         selectionsJSON: String,
         stake: Int64,
         payout: Int64? = nil,
         odds: Double? = nil,
         linkedActualId: UUID? = nil,
         now: Date = .now) {
        self.id = UUID()
        self.race = race
        self.kind = kind
        self.betType = betType
        self.selectionsJSON = selectionsJSON
        self.stake = stake
        self.payout = payout
        self.odds = odds
        self.linkedActualId = linkedActualId
        self.createdAt = now
        self.updatedAt = now
    }
}
