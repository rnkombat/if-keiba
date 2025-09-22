import Foundation
import SwiftData

@MainActor
final class SettingsViewModel: ObservableObject {
    enum OddsInputMode: Int16, CaseIterable, Identifiable {
        case manual = 0
        case oddsBased = 1

        var id: Int16 { rawValue }

        var displayName: String {
            switch self {
            case .manual:
                return "手入力"
            case .oddsBased:
                return "オッズ方式"
            }
        }
    }

    struct AlertInfo: Identifiable {
        let id = UUID()
        let title: String
        let message: String
    }

    struct ExportedFiles {
        let racesURL: URL
        let ticketsURL: URL
    }

    enum SettingsError: LocalizedError {
        case failedToLocateDocuments
        case failedToEncodeCSV

        var errorDescription: String? {
            switch self {
            case .failedToLocateDocuments:
                return "Documentsフォルダを取得できませんでした。"
            case .failedToEncodeCSV:
                return "CSVデータのエンコードに失敗しました。"
            }
        }
    }

    @Published var initialBalance: Int = 0
    @Published var payday: Int? = nil
    @Published var monthlyFreeBudget: Int = 0
    @Published var roundingRule: MoneyRoundingRule = .nearest
    @Published var oddsMode: OddsInputMode = .manual

    @Published private(set) var isSaving = false
    @Published private(set) var isExporting = false
    @Published var alertInfo: AlertInfo?
    @Published private(set) var lastExportedFiles: ExportedFiles?

    private let csvExporter: CSVExporter

    init(csvExporter: CSVExporter = CSVExporter()) {
        self.csvExporter = csvExporter
    }

    func configure(with profile: Profile?) {
        guard let profile else {
            initialBalance = 0
            payday = nil
            monthlyFreeBudget = 0
            roundingRule = .nearest
            oddsMode = .manual
            return
        }

        initialBalance = Int(clamping: profile.initialBalance)
        payday = profile.payday
        monthlyFreeBudget = Int(clamping: profile.monthlyFreeBudget)
        roundingRule = MoneyRoundingRule(rawValue: profile.roundingRule) ?? .nearest
        oddsMode = OddsInputMode(rawValue: profile.oddsMode) ?? .manual
    }

    var validationMessage: String? {
        if initialBalance < 0 {
            return "初期残高は0以上で入力してください"
        }
        if monthlyFreeBudget < 0 {
            return "月自由枠は0以上で入力してください"
        }
        if let payday, !(1...31).contains(payday) {
            return "給料日は1〜31の範囲で指定してください"
        }
        return nil
    }

    var canSave: Bool {
        validationMessage == nil
    }

    func save(using context: ModelContext, profile: Profile?) {
        guard canSave else {
            alertInfo = AlertInfo(title: "保存できません", message: validationMessage ?? "入力内容を確認してください。")
            return
        }

        isSaving = true
        let now = Date()

        do {
            let sanitizedInitial = Int64(max(0, initialBalance))
            let sanitizedMonthly = Int64(max(0, monthlyFreeBudget))
            let sanitizedPayday = payday
            let roundingRaw = roundingRule.rawValue
            let oddsRaw = oddsMode.rawValue

            if let profile {
                profile.initialBalance = sanitizedInitial
                profile.monthlyFreeBudget = sanitizedMonthly
                profile.payday = sanitizedPayday
                profile.roundingRule = roundingRaw
                profile.oddsMode = oddsRaw
                profile.updatedAt = now
            } else {
                let newProfile = Profile(
                    initialBalance: sanitizedInitial,
                    payday: sanitizedPayday,
                    monthlyFreeBudget: sanitizedMonthly,
                    oddsMode: oddsRaw,
                    roundingRule: roundingRaw,
                    now: now
                )
                context.insert(newProfile)
            }

            try context.save()

            alertInfo = AlertInfo(title: "保存しました", message: "プロフィール設定を更新しました。")
        } catch {
            alertInfo = AlertInfo(title: "保存に失敗しました", message: error.localizedDescription)
        }

        isSaving = false
    }

    func exportToDocuments(races: [Race], tickets: [Ticket]) {
        isExporting = true

        do {
            let exportResult = csvExporter.exportAll(races: races, tickets: tickets)

            guard let racesData = exportResult.racesCSV.data(using: .utf8),
                  let ticketsData = exportResult.ticketsCSV.data(using: .utf8) else {
                throw SettingsError.failedToEncodeCSV
            }

            guard let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
                throw SettingsError.failedToLocateDocuments
            }

            let timestamp = Self.fileDateFormatter.string(from: Date())
            let racesURL = documentsURL.appendingPathComponent("races-\(timestamp).csv")
            let ticketsURL = documentsURL.appendingPathComponent("tickets-\(timestamp).csv")

            try racesData.write(to: racesURL, options: .atomic)
            try ticketsData.write(to: ticketsURL, options: .atomic)

            lastExportedFiles = ExportedFiles(racesURL: racesURL, ticketsURL: ticketsURL)
            alertInfo = AlertInfo(title: "書き出し完了", message: "DocumentsフォルダにCSVを出力しました。")
        } catch {
            lastExportedFiles = nil
            if let settingsError = error as? SettingsError {
                alertInfo = AlertInfo(title: "書き出し失敗", message: settingsError.localizedDescription)
            } else {
                alertInfo = AlertInfo(title: "書き出し失敗", message: error.localizedDescription)
            }
        }

        isExporting = false
    }

    private static let fileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
}
