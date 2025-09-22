import Foundation
import SwiftData

@MainActor
final class RacesListViewModel: ObservableObject {
    @Published var isPresentingAddRace = false
    @Published var draftDate: Date = .now
    @Published var draftName: String = ""
    @Published var draftMemo: String = ""

    var canCreateRace: Bool {
        true
    }

    func startAddRace() {
        draftDate = .now
        draftName = ""
        draftMemo = ""
        isPresentingAddRace = true
    }

    func cancelAddRace() {
        isPresentingAddRace = false
    }

    func createRace(using context: ModelContext) {
        let trimmedName = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedMemo = draftMemo.trimmingCharacters(in: .whitespacesAndNewlines)
        let now = Date()
        let race = Race(
            date: draftDate,
            name: trimmedName.isEmpty ? nil : trimmedName,
            memo: trimmedMemo.isEmpty ? nil : trimmedMemo,
            now: now
        )
        context.insert(race)
        try? context.save()
        isPresentingAddRace = false
    }

    func deleteRaces(at offsets: IndexSet, from races: [Race], context: ModelContext) {
        for index in offsets {
            guard races.indices.contains(index) else { continue }
            context.delete(races[index])
        }
        try? context.save()
    }
}
