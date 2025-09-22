import SwiftData
import SwiftUI

struct RaceDetailView: View {
    @Environment(\.modelContext) private var context
    @StateObject private var viewModel = RaceDetailViewModel()
    @Bindable var race: Race

    private var actualTickets: [Ticket] {
        race.tickets
            .filter { $0.kind == RaceTicketKind.actual.rawValue }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var ifTickets: [Ticket] {
        race.tickets
            .filter { $0.kind == RaceTicketKind.ifScenario.rawValue }
            .sorted { $0.createdAt > $1.createdAt }
    }

    private var titleText: String {
        if let name = race.name, !name.isEmpty {
            return name
        }
        return RaceDetailView.dateFormatter.string(from: race.date)
    }

    var body: some View {
        List {
            Section("レース情報") {
                DatePicker("日付", selection: $race.date, displayedComponents: .date)
                    .onChange(of: race.date) { _ in
                        viewModel.markRaceUpdated(race)
                    }
                TextField("レース名", text: Binding(
                    get: { race.name ?? "" },
                    set: { newValue in
                        race.name = newValue.isEmpty ? nil : newValue
                        viewModel.markRaceUpdated(race)
                    }
                ))
                TextField("メモ", text: Binding(
                    get: { race.memo ?? "" },
                    set: { newValue in
                        race.memo = newValue.isEmpty ? nil : newValue
                        viewModel.markRaceUpdated(race)
                    }
                ), axis: .vertical)
                .lineLimit(1...4)
            }

            ticketSection(title: "Actualチケット", tickets: actualTickets, kind: .actual)
            ticketSection(title: "Ifチケット", tickets: ifTickets, kind: .ifScenario)
        }
        .navigationTitle(titleText)
        .toolbar {
            ToolbarItemGroup(placement: .primaryAction) {
                Menu {
                    Button {
                        viewModel.presentTicketSheet(kind: .actual)
                    } label: {
                        Label("Actualチケット", systemImage: "checkmark.circle")
                    }
                    Button {
                        viewModel.presentTicketSheet(kind: .ifScenario)
                    } label: {
                        Label("Ifチケット", systemImage: "wand.and.stars")
                    }
                } label: {
                    Label("チケットを追加", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $viewModel.isPresentingTicketSheet) {
            AddTicketSheet(viewModel: viewModel, race: race)
                .presentationDetents([.medium, .large])
        }
    }

    @ViewBuilder
    private func ticketSection(title: String, tickets: [Ticket], kind: RaceTicketKind) -> some View {
        Section(title) {
            if tickets.isEmpty {
                ContentUnavailableView(
                    "チケットがありません",
                    systemImage: kind == .actual ? "ticket" : "wand.and.stars",
                    description: Text("追加ボタンから新しいチケットを登録してください")
                )
                .listRowSeparator(.hidden)
            } else {
                ForEach(tickets) { ticket in
                    TicketRow(ticket: ticket)
                }
                .onDelete { offsets in
                    viewModel.deleteTickets(at: offsets, from: tickets, in: race, context: context)
                }
            }
        }
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateStyle = .medium
        return formatter
    }()
}

private struct TicketRow: View {
    @Bindable var ticket: Ticket

    private var kind: RaceTicketKind {
        RaceTicketKind(rawValue: ticket.kind) ?? .actual
    }

    private var betTypeText: String {
        RaceTicketBetType(rawValue: ticket.betType)?.displayName ?? "種別: \(ticket.betType)"
    }

    private var stakeText: String {
        "賭金: \(ticket.stake, format: .number)"
    }

    private var payoutText: String? {
        guard let payout = ticket.payout else { return nil }
        return "払戻: \(payout, format: .number)"
    }

    private var oddsText: String? {
        guard let odds = ticket.odds else { return nil }
        return String(format: "オッズ: %.2f", odds)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Label(betTypeText, systemImage: kind.symbolName)
                    .font(.subheadline)
                Spacer()
                Text(stakeText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let payoutText {
                Text(payoutText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if let oddsText {
                Text(oddsText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            if !ticket.selectionsJSON.isEmpty {
                Text(ticket.selectionsJSON)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(3)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct AddTicketSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @ObservedObject var viewModel: RaceDetailViewModel
    var race: Race

    var body: some View {
        NavigationStack {
            Form {
                Section("チケット情報") {
                    Picker("種類", selection: $viewModel.ticketKind) {
                        ForEach(RaceTicketKind.allCases) { kind in
                            Text(kind.displayName).tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)

                    Picker("馬券種別", selection: $viewModel.betType) {
                        ForEach(RaceTicketBetType.allCases) { betType in
                            Text(betType.displayName).tag(betType)
                        }
                    }

                    TextField("選択（JSON）", text: $viewModel.selectionsJSON, axis: .vertical)
                        .lineLimit(1...4)
                    TextField("賭金", value: $viewModel.stake, format: .number)
                        .keyboardType(.numberPad)
                }
            }
            .navigationTitle(viewModel.ticketSheetTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewModel.dismissTicketSheet()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") {
                        viewModel.createTicket(for: race, context: context)
                        dismiss()
                    }
                    .disabled(!viewModel.canCreateTicket)
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
    let race = Race(date: .now, name: "有馬記念", memo: "年末のグランプリ")
    context.insert(race)
    _ = Ticket(
        race: race,
        kind: RaceTicketKind.actual.rawValue,
        betType: RaceTicketBetType.exacta.rawValue,
        selectionsJSON: "[\"5-7\"]",
        stake: 2000,
        payout: 6400,
        odds: 3.2
    )
    _ = Ticket(
        race: race,
        kind: RaceTicketKind.ifScenario.rawValue,
        betType: RaceTicketBetType.trifecta.rawValue,
        selectionsJSON: "[\"5-7-9\"]",
        stake: 1200
    )
    try? context.save()
    return NavigationStack {
        RaceDetailView(race: race)
    }
    .modelContainer(container)
}
