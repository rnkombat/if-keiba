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
                    .onChange(of: race.date) {
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
        .sheet(isPresented: $viewModel.isPresentingIncreaseSheet) {
            IncreaseIfSheet(viewModel: viewModel, race: race)
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
                    TicketRow(ticket: ticket) { ticket in
                        viewModel.presentTicketEditor(for: ticket)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button {
                            viewModel.presentTicketEditor(for: ticket)
                        } label: {
                            Label("編集", systemImage: "pencil")
                        }
                        .tint(.orange)

                        if kind == .actual {
                            Button {
                                viewModel.presentIncreaseSheet(for: ticket)
                            } label: {
                                Label("Ifへ複製", systemImage: "wand.and.stars")
                            }
                            .tint(.indigo)
                        }
                    }
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
    var onEdit: ((Ticket) -> Void)? = nil

    private var kind: RaceTicketKind {
        RaceTicketKind(rawValue: ticket.kind) ?? .actual
    }

    private var betTypeText: String {
        RaceTicketBetType(rawValue: ticket.betType)?.displayName ?? "種別: \(ticket.betType)"
    }

    private var stakeText: String {
        "賭金: \(ticket.stake.formatted(.number))"

    }

    private var payoutText: String? {
        guard let payout = ticket.payout else { return nil }
        return "払戻: \(payout.formatted(.number))"
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
        .contentShape(Rectangle())
        .onTapGesture {
            onEdit?(ticket)
        }
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
                    TextField(payoutFieldLabel, value: $viewModel.payout, format: .number)
                        .keyboardType(.numberPad)
                    TextField(oddsFieldLabel, value: $viewModel.odds, format: .number.precision(.fractionLength(2)))
                        .keyboardType(.decimalPad)
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
                    Button(viewModel.isEditingTicket ? "更新" : "保存") {
                        if viewModel.saveTicket(for: race, context: context) {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canSaveTicket)
                }
            }
        }
    }

    private var payoutFieldLabel: String {
        viewModel.ticketKind == .actual ? "払戻金" : "想定払戻金"
    }

    private var oddsFieldLabel: String {
        viewModel.ticketKind == .actual ? "オッズ" : "想定オッズ"
    }
}

private struct IncreaseIfSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @ObservedObject var viewModel: RaceDetailViewModel
    var race: Race

    private var baseTicket: Ticket? { viewModel.increaseBaseTicket }
    private var preview: OddsCalculator.IncreasedIfCalculation? { viewModel.increasePreview }

    var body: some View {
        NavigationStack {
            Form {
                if let baseTicket {
                    Section("Actualチケット") {
                        HStack {
                            Text("賭金")
                            Spacer()
                            Text("\(baseTicket.stake, format: .number)")
                        }
                        if let payout = baseTicket.payout {
                            HStack {
                                Text("払戻")
                                Spacer()
                                Text("\(payout, format: .number)")
                            }
                        } else {
                            HStack {
                                Text("払戻")
                                Spacer()
                                Text("未入力")
                                    .foregroundStyle(.secondary)
                            }
                        }
                        if let odds = baseTicket.odds {
                            HStack {
                                Text("オッズ")
                                Spacer()
                                Text(odds, format: .number.precision(.fractionLength(2)))
                            }
                        }
                    }

                    Section("増額設定") {
                        TextField("増額額", value: $viewModel.increaseDelta, format: .number)
                            .keyboardType(.numberPad)
                            .onChange(of: viewModel.increaseDelta) {
                                viewModel.ensureValidIncreaseDelta()
                            }
                        Stepper(value: $viewModel.increaseDelta, in: 0...1_000_000, step: 100) {
                            Text("現在の増額: \(viewModel.increaseDelta, format: .number)")
                        }
                    }

                    if let preview {
                        Section("Ifプレビュー") {
                            HStack {
                                Text("賭金")
                                Spacer()
                                Text("\(preview.stake, format: .number)")
                            }
                            if let payout = preview.payout {
                                HStack {
                                    Text("払戻")
                                    Spacer()
                                    Text("\(payout, format: .number)")
                                }
                            } else {
                                HStack {
                                    Text("払戻")
                                    Spacer()
                                    Text("計算不可")
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if let ratio = preview.ratio {
                                HStack {
                                    Text("倍率")
                                    Spacer()
                                    Text(ratio, format: .number.precision(.fractionLength(2)))
                                }
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "Actualチケットが見つかりません",
                        systemImage: "questionmark.circle",
                        description: Text("もう一度操作をやり直してください。")
                    )
                    .listRowSeparator(.hidden)
                }
            }
            .navigationTitle("Ifへ複製（増額）")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        viewModel.dismissIncreaseSheet()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("作成") {
                        if viewModel.createIncreasedIf(for: race, context: context) {
                            dismiss()
                        }
                    }
                    .disabled(!viewModel.canCreateIncreasedIf)
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
