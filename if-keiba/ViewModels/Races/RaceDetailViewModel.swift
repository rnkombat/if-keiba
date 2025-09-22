import Foundation
import SwiftData
import Combine

@MainActor
final class RaceDetailViewModel: ObservableObject {
    @Published var isPresentingTicketSheet = false
    @Published var ticketKind: RaceTicketKind = .actual
    @Published var betType: RaceTicketBetType = .win
    @Published var selectionsJSON: String = "[]"
    @Published var stake: Int = 1000
    @Published var payout: Int?
    @Published var odds: Double?
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
    @Published private(set) var editingTicket: Ticket?

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
        let base: String
        switch ticketKind {
        case .actual:
            base = "Actualチケット"
        case .ifScenario:
            base = "Ifチケット"
        }
        return isEditingTicket ? "\(base)を編集" : "\(base)を追加"
    }

    var isEditingTicket: Bool { editingTicket != nil }

    var canSaveTicket: Bool {
        sanitizedStake > 0
            && sanitizedPayoutIsValid
            && sanitizedOddsIsValid
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
        editingTicket = nil
        resetTicketForm()
        isPresentingTicketSheet = true
    }

    func dismissTicketSheet() {
        isPresentingTicketSheet = false
        editingTicket = nil
        resetTicketForm()
    }

    func presentIncreaseSheet(for ticket: Ticket) {
        increaseBaseTicket = ticket
        increaseDelta = 0
        isPresentingIncreaseSheet = true
    }

    func presentTicketEditor(for ticket: Ticket) {
        editingTicket = ticket
        ticketKind = RaceTicketKind(rawValue: ticket.kind) ?? .actual
        betType = RaceTicketBetType(rawValue: ticket.betType) ?? .win
        selectionsJSON = ticket.selectionsJSON
        stake = Int(ticket.stake)
        payout = ticket.payout.flatMap { Int($0) }
        odds = ticket.odds
        isPresentingTicketSheet = true
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
        payout = nil
        odds = nil
    }

    func markRaceUpdated(_ race: Race) {
        race.updatedAt = .now
    }

    @discardableResult
    func saveTicket(for race: Race, context: ModelContext) -> Bool {
        guard canSaveTicket else { return false }
        let success: Bool
        if let editingTicket {
            success = updateTicket(
                editingTicket,
                for: race,
                context: context
            )
        } else {
            success = createTicket(for: race, context: context)
        }
        if success {
            editingTicket = nil
            resetTicketForm()
            isPresentingTicketSheet = false
        }
        return success
    }

    private func createTicket(for race: Race, context: ModelContext) -> Bool {
        let now = Date()
        let ticket = Ticket(
            race: race,
            kind: ticketKind.rawValue,
            betType: betType.rawValue,
            selectionsJSON: sanitizedSelections,
            stake: sanitizedStake,
            payout: sanitizedPayout,
            odds: sanitizedOdds,
            now: now
        )
        context.insert(ticket)
        race.updatedAt = now
        ticket.updatedAt = now
        do {
            try context.save()
            return true
        } catch {
            return false
        }
    }

    private func updateTicket(_ ticket: Ticket, for race: Race, context: ModelContext) -> Bool {
        let now = Date()
        ticket.kind = ticketKind.rawValue
        ticket.betType = betType.rawValue
        ticket.selectionsJSON = sanitizedSelections
        ticket.stake = sanitizedStake
        ticket.payout = sanitizedPayout
        ticket.odds = sanitizedOdds
        ticket.updatedAt = now
        ticket.race = race
        race.updatedAt = now
        do {
            try context.save()
            return true
        } catch {
            return false
        }
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

    private var sanitizedStake: Int64 {
        Int64(max(0, stake))
    }

    private var sanitizedSelections: String {
        let trimmed = selectionsJSON.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? "[]" : trimmed
    }

    private var sanitizedPayout: Int64? {
        guard let payout else { return nil }
        return payout >= 0 ? Int64(payout) : nil
    }

    private var sanitizedOdds: Double? {
        guard let odds else { return nil }
        return odds > 0 ? odds : nil
    }

    private var sanitizedPayoutIsValid: Bool {
        payout == nil || payout! >= 0
    }

    private var sanitizedOddsIsValid: Bool {
        odds == nil || odds! > 0
    }
}
