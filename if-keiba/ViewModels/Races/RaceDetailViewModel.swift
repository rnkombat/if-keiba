import Foundation
import SwiftData

@MainActor
final class RaceDetailViewModel: ObservableObject {
    @Published var isPresentingTicketSheet = false
    @Published var ticketKind: RaceTicketKind = .actual
    @Published var betType: RaceTicketBetType = .win
    @Published var selectionsJSON: String = "[]"
    @Published var stake: Int = 1000

    var ticketSheetTitle: String {
        switch ticketKind {
        case .actual:
            return "Actualチケット"
        case .ifScenario:
            return "Ifチケット"
        }
    }

    var canCreateTicket: Bool {
        stake > 0
    }

    func presentTicketSheet(kind: RaceTicketKind) {
        ticketKind = kind
        resetTicketForm()
        isPresentingTicketSheet = true
    }

    func dismissTicketSheet() {
        isPresentingTicketSheet = false
        resetTicketForm()
    }

    func resetTicketForm() {
        betType = .win
        selectionsJSON = "[]"
        stake = 1000
    }

    func markRaceUpdated(_ race: Race) {
        race.updatedAt = .now
    }

    func createTicket(for race: Race, context: ModelContext) {
        guard canCreateTicket else { return }
        let now = Date()
        let sanitizedSelections = selectionsJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        let ticket = Ticket(
            race: race,
            kind: ticketKind.rawValue,
            betType: betType.rawValue,
            selectionsJSON: sanitizedSelections.isEmpty ? "[]" : sanitizedSelections,
            stake: Int64(stake),
            now: now
        )
        context.insert(ticket)
        race.updatedAt = now
        ticket.updatedAt = now
        try? context.save()
        resetTicketForm()
        isPresentingTicketSheet = false
    }

    func deleteTickets(at offsets: IndexSet, from tickets: [Ticket], in race: Race, context: ModelContext) {
        let now = Date()
        for index in offsets {
            guard tickets.indices.contains(index) else { continue }
            context.delete(tickets[index])
        }
        race.updatedAt = now
        try? context.save()
    }
}
