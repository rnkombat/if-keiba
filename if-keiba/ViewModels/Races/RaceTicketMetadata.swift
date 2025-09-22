import Foundation
import Combine

enum RaceTicketKind: Int16, CaseIterable, Identifiable {
    case actual = 0
    case ifScenario = 1

    var id: Int16 { rawValue }

    var displayName: String {
        switch self {
        case .actual:
            return "Actual"
        case .ifScenario:
            return "If"
        }
    }

    var symbolName: String {
        switch self {
        case .actual:
            return "checkmark.circle.fill"
        case .ifScenario:
            return "wand.and.stars"
        }
    }
}

enum RaceTicketBetType: Int16, CaseIterable, Identifiable {
    case win = 0
    case place = 1
    case quinella = 2
    case exacta = 3
    case trifecta = 4

    var id: Int16 { rawValue }

    var displayName: String {
        switch self {
        case .win:
            return "単勝"
        case .place:
            return "複勝"
        case .quinella:
            return "馬連"
        case .exacta:
            return "馬単"
        case .trifecta:
            return "三連単"
        }
    }
}
