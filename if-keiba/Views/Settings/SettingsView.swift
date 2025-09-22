import SwiftData
import SwiftUI

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @StateObject private var viewModel = SettingsViewModel()

    @Query(
        FetchDescriptor<Profile>(
            sortBy: [
                SortDescriptor(\Profile.createdAt, order: .forward)
            ],
            fetchLimit: 1
        )
    ) private var profiles: [Profile]

    @Query(
        FetchDescriptor<Race>(
            sortBy: [
                SortDescriptor(\Race.date, order: .forward)
            ]
        )
    ) private var races: [Race]

    @Query(
        FetchDescriptor<Ticket>(
            sortBy: [
                SortDescriptor(\Ticket.createdAt, order: .forward)
            ]
        )
    ) private var tickets: [Ticket]

    private var profile: Profile? { profiles.first }

    private var profileSignature: ProfileSignature {
        ProfileSignature(profile: profile)
    }

    var body: some View {
        NavigationStack {
            Form {
                profileSection

                if let validation = viewModel.validationMessage {
                    Section { Text(validation).foregroundColor(.red) }
                }

                exportSection

                if let exported = viewModel.lastExportedFiles {
                    Section("直近の書き出し") {
                        ExportDestinationView(exportedFiles: exported)
                    }
                }
            }
            .navigationTitle("設定")
            .toolbar { toolbarContent }
        }
        .task(id: profileSignature) {
            viewModel.configure(with: profile)
        }
        .alert(item: $viewModel.alertInfo) { info in
            Alert(
                title: Text(info.title),
                message: Text(info.message),
                dismissButton: .default(Text("OK"))
            )
        }
    }

    private var profileSection: some View {
        Section("プロフィール") {
            TextField(
                "初期残高",
                value: $viewModel.initialBalance,
                format: .number
            )
            .keyboardType(.numberPad)

            Picker("給料日", selection: $viewModel.payday) {
                Text("未設定").tag(Int?.none)
                ForEach(1...31, id: \.self) { day in
                    Text("\(day)日").tag(Optional(day))
                }
            }

            TextField(
                "月自由枠",
                value: $viewModel.monthlyFreeBudget,
                format: .number
            )
            .keyboardType(.numberPad)

            Picker("端数処理", selection: $viewModel.roundingRule) {
                ForEach(MoneyRoundingRule.allCases, id: \.self) { rule in
                    Text(rule.displayName).tag(rule)
                }
            }

            Picker("オッズモード", selection: $viewModel.oddsMode) {
                ForEach(SettingsViewModel.OddsInputMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
        }
    }

    private var exportSection: some View {
        Section("CSV 出力") {
            Button {
                viewModel.exportToDocuments(races: races, tickets: tickets)
            } label: {
                Label("CSVを書き出す", systemImage: "square.and.arrow.down")
            }
            .disabled(viewModel.isExporting)

            if viewModel.isExporting {
                ProgressView()
                    .progressViewStyle(.circular)
            }
        }
    }

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            if viewModel.isSaving {
                ProgressView()
            } else {
                Button("保存") {
                    viewModel.save(using: modelContext, profile: profile)
                }
                .disabled(!viewModel.canSave)
            }
        }
    }
}

private struct ExportDestinationView: View {
    let exportedFiles: SettingsViewModel.ExportedFiles

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(exportedFiles.racesURL.lastPathComponent, systemImage: "doc")
            Label(exportedFiles.ticketsURL.lastPathComponent, systemImage: "doc")
            Text("Documents フォルダをご確認ください。")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ProfileSignature: Equatable {
    let id: UUID?
    let updatedAt: Date?
    let initialBalance: Int64?
    let monthlyFreeBudget: Int64?
    let payday: Int?
    let oddsMode: Int16?
    let roundingRule: Int16?

    init(profile: Profile?) {
        id = profile?.id
        updatedAt = profile?.updatedAt
        initialBalance = profile?.initialBalance
        monthlyFreeBudget = profile?.monthlyFreeBudget
        payday = profile?.payday
        oddsMode = profile?.oddsMode
        roundingRule = profile?.roundingRule
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [Profile.self, Race.self, Ticket.self], inMemory: true)
}
