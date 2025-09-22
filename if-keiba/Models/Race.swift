import Foundation
import SwiftData

@Model
final class Race {
    @Attribute(.unique) var id: UUID
    var date: Date
    var name: String?
    var memo: String?
    @Relationship(deleteRule: .cascade, inverse: \Ticket.race) var tickets: [Ticket] = []
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
