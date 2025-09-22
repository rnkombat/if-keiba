import Foundation
import SwiftData

@MainActor
final class RaceDetailViewModel: ObservableObject {
    @Published var isPresentingTicketSheet = false
    @Published var ticketKind: RaceTicketKind = .actual
    @Published var betType: RaceTicketBetType = .win
    @Published var selectionsJSON: String = "[]"
    @Published var stake: Int = 1000
    @Published var isPresentingIncreaseSheet = false {
        didSet {
            if !isPresentingIncreaseSheet {
                increaseBaseTicket = nil
                increaseDelta = 0
            }
        }
    }
    @Published var increaseDelta: Int = 0
    @Published private(set) var increaseBaseTicket: Ticket?

    private let oddsCalculator: OddsCalculator
    private let moneyRounding: MoneyRounding
    private let roundingRule: MoneyRoundingRule

    init(
        oddsCalculator: OddsCalculator = OddsCalculator(),
        moneyRounding: MoneyRounding = MoneyRounding(),
        roundingRule: MoneyRoundingRule = .nearest
    ) {
        self.oddsCalculator = oddsCalculator
        self.moneyRounding = moneyRounding
        self.roundingRule = roundingRule
    }

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

    var increasePreview: OddsCalculator.IncreasedIfCalculation? {
        guard let base = increaseBaseTicket else { return nil }
        return oddsCalculator.calculateIncreasedIf(
            baseStake: base.stake,
            basePayout: base.payout,
            baseOdds: base.odds,
            deltaStake: sanitizedIncreaseDelta,
            roundingRule: roundingRule,
            rounding: moneyRounding
        )
    }

    var canCreateIncreasedIf: Bool {
        guard let preview = increasePreview else { return false }
        return preview.stake > 0 && increaseBaseTicket != nil
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

    func presentIncreaseSheet(for ticket: Ticket) {
        increaseBaseTicket = ticket
        increaseDelta = 0
        isPresentingIncreaseSheet = true
    }

    func dismissIncreaseSheet() {
        isPresentingIncreaseSheet = false
    }

    func ensureValidIncreaseDelta() {
        if increaseDelta < 0 {
            increaseDelta = 0
        }
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

    @discardableResult
    func createIncreasedIf(for race: Race, context: ModelContext) -> Bool {
        guard let base = increaseBaseTicket else { return false }
        guard let preview = oddsCalculator.calculateIncreasedIf(
            baseStake: base.stake,
            basePayout: base.payout,
            baseOdds: base.odds,
            deltaStake: sanitizedIncreaseDelta,
            roundingRule: roundingRule,
            rounding: moneyRounding
        ) else { return false }

        let now = Date()
        let newOdds: Double?
        if let odds = base.odds {
            newOdds = odds
        } else if base.payout != nil, let ratio = preview.ratio {
            newOdds = ratio
        } else {
            newOdds = nil
        }

        let ticket = Ticket(
            race: race,
            kind: RaceTicketKind.ifScenario.rawValue,
            betType: base.betType,
            selectionsJSON: base.selectionsJSON,
            stake: preview.stake,
            payout: preview.payout,
            odds: newOdds,
            linkedActualId: base.id,
            now: now
        )

        context.insert(ticket)
        race.updatedAt = now
        ticket.updatedAt = now
        try? context.save()
        isPresentingIncreaseSheet = false
        return true
    }

    private var sanitizedIncreaseDelta: Int64 {
        Int64(max(0, increaseDelta))
    }
}
