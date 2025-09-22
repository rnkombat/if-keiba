import Foundation

/// SwiftUIの `.task(id:)` などで使用するための集計データ変更検知用シグネチャ。
struct BalanceDataSignature: Equatable {
    struct RaceSignature: Equatable {
        struct TicketSignature: Equatable {
            let id: UUID
            let kind: Int16
            let stake: Int64
            let payout: Int64?
            let odds: Double?
            let linkedActualId: UUID?
            let updatedAt: Date
        }

        let id: UUID
        let date: Date
        let updatedAt: Date
        let ticketSignatures: [TicketSignature]
    }

    let profileID: UUID?
    let profileInitialBalance: Int64?
    let profileUpdatedAt: Date?
    let profileMonthlyFreeBudget: Int64?
    let profilePayday: Int?
    let profileOddsMode: Int16?
    let profileRoundingRule: Int16?
    let raceSignatures: [RaceSignature]

    init(profile: Profile?, races: [Race]) {
        profileID = profile?.id
        profileInitialBalance = profile?.initialBalance
        profileUpdatedAt = profile?.updatedAt
        profileMonthlyFreeBudget = profile?.monthlyFreeBudget
        profilePayday = profile?.payday
        profileOddsMode = profile?.oddsMode
        profileRoundingRule = profile?.roundingRule

        raceSignatures = races
            .map { race in
                RaceSignature(
                    id: race.id,
                    date: race.date,
                    updatedAt: race.updatedAt,
                    ticketSignatures: race.tickets
                        .sorted { $0.id.uuidString < $1.id.uuidString }
                        .map { ticket in
                            RaceSignature.TicketSignature(
                                id: ticket.id,
                                kind: ticket.kind,
                                stake: ticket.stake,
                                payout: ticket.payout,
                                odds: ticket.odds,
                                linkedActualId: ticket.linkedActualId,
                                updatedAt: ticket.updatedAt
                            )
                        }
                )
            }
            .sorted { lhs, rhs in
                if lhs.date == rhs.date {
                    return lhs.id.uuidString < rhs.id.uuidString
                }
                return lhs.date < rhs.date
            }
    }
}
