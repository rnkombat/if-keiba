// if-keiba/if-keiba/Models/Profile.swift
import Foundation
import SwiftData

@Model
final class Profile {
    @Attribute(.unique) var id: UUID
    var initialBalance: Int64
    var payday: Int?
    var monthlyFreeBudget: Int64
    var oddsMode: Int16      // 0: 手入力, 1: オッズ方式
    var roundingRule: Int16  // 0: 四捨五入, 1: 切上, 2: 切捨
    var createdAt: Date
    var updatedAt: Date

    init(initialBalance: Int64 = 0,
         payday: Int? = nil,
         monthlyFreeBudget: Int64 = 0,
         oddsMode: Int16 = 0,
         roundingRule: Int16 = 0,
         now: Date = .now) {
        self.id = UUID()
        self.initialBalance = initialBalance
        self.payday = payday
        self.monthlyFreeBudget = monthlyFreeBudget
        self.oddsMode = oddsMode
        self.roundingRule = roundingRule
        self.createdAt = now
        self.updatedAt = now
    }
}
