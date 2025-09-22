import SwiftData
import SwiftUI

struct RacesListView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = RacesListViewModel()

    @Query(
        FetchDescriptor<Race>(
            sortBy: [
                SortDescriptor(\Race.date, order: .reverse),
                SortDescriptor(\Race.createdAt, order: .reverse)
            ]
        ),
        animation: .default
    ) private var races: [Race]

    var body: some View {
        NavigationStack {
            List {
                if races.isEmpty {
                    ContentUnavailableView(
                        "レースがありません",
                        systemImage: "flag.checkered",
                        description: Text("右上のボタンからレースを追加してください")
                    )
                    .listRowSeparator(.hidden)
                } else {
                    ForEach(races) { race in
                        NavigationLink(destination: RaceDetailView(race: race)) {
                            RacesListRow(race: race)
                        }
                    }
                    .onDelete { offsets in
                        viewModel.deleteRaces(at: offsets, from: races, context: context)
                    }
                }
            }
            .navigationTitle("Races")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !races.isEmpty {
                        EditButton()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        viewModel.startAddRace()
                    } label: {
                        Label("レースを追加", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $viewModel.isPresentingAddRace) {
                AddRaceSheet(viewModel: viewModel)
                    .presentationDetents([.medium, .large])
            }
        }
    }
}

private struct RacesListRow: View {
    @Bindable var race: Race

    private var actualCount: Int {
        race.tickets.filter { $0.kind == RaceTicketKind.actual.rawValue }.count
    }

    private var ifCount: Int {
        race.tickets.filter { $0.kind == RaceTicketKind.ifScenario.rawValue }.count
    }

    private var dateText: String {
        Self.dateFormatter.string(from: race.date)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(race.name?.isEmpty == false ? race.name! : "無題のレース")
                .font(.headline)
            HStack(alignment: .firstTextBaseline) {
                Label(dateText, systemImage: "calendar")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("Actual: \(actualCount)  If: \(ifCount)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if let memo = race.memo, !memo.isEmpty {
                Text(memo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 6)
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        return formatter
    }()
}

private struct AddRaceSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @ObservedObject var viewModel: RacesListViewModel

    var body: some View {
        NavigationStack {
            Form {
                Section("開催情報") {
                    DatePicker("日付", selection: $viewModel.draftDate, displayedComponents: .date)
                    TextField("レース名", text: $viewModel.draftName)
                    TextField("メモ", text: $viewModel.draftMemo, axis: .vertical)
                        .lineLimit(1...3)
                }
            }
            .navigationTitle("レースを追加")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewModel.cancelAddRace()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.createRace(using: context)
                        dismiss()
                    }
                    .disabled(!viewModel.canCreateRace)
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Profile.self, Race.self, Ticket.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let context = ModelContext(container)
    let race = Race(date: .now, name: "サンプルレース", memo: "テスト用のメモ")
    context.insert(race)
    _ = Ticket(
        race: race,
        kind: RaceTicketKind.actual.rawValue,
        betType: RaceTicketBetType.win.rawValue,
        selectionsJSON: "[\"1\"]",
        stake: 1000
    )
    _ = Ticket(
        race: race,
        kind: RaceTicketKind.ifScenario.rawValue,
        betType: RaceTicketBetType.place.rawValue,
        selectionsJSON: "[\"3\"]",
        stake: 1500
    )
    try? context.save()
    return NavigationStack {
        RacesListView()
    }
    .modelContainer(container)
}
