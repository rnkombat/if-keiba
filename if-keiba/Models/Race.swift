// if-keiba/if-keiba/Models/Race.swift
import Foundation
import SwiftData

@Model
final class Race {
    @Attribute(.unique) var id: UUID
    var date: Date
    var name: String?
    var memo: String?
    // 片側だけに付ける（ここに付ける想定）
    @Relationship(deleteRule: .cascade, inverse: \Ticket.race)
    var tickets: [Ticket] = []
    var createdAt: Date
    var updatedAt: Date

    init(date: Date, name: String? = nil, memo: String? = nil, now: Date = .now) {
        self.id = UUID()
        self.date = date
        self.name = name
        self.memo = memo
        self.createdAt = now
        self.updatedAt = now
    }
}
