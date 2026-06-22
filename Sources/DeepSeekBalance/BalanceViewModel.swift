import Foundation
import SwiftUI
import UserNotifications
import ServiceManagement

// MARK: - Refresh Interval

enum RefreshIntervalOption: String, CaseIterable, Identifiable {
    case tenSec = "10 秒"
    case oneMin = "1 分钟"
    case fiveMin = "5 分钟"
    case fifteenMin = "15 分钟"
    case thirtyMin = "30 分钟"
    case oneHour = "1 小时"

    var id: String { rawValue }

    var seconds: TimeInterval {
        switch self {
        case .tenSec: return 10
        case .oneMin: return 60
        case .fiveMin: return 300
        case .fifteenMin: return 900
        case .thirtyMin: return 1800
        case .oneHour: return 3600
        }
    }

    static var `default`: RefreshIntervalOption { .fiveMin }

    static func from(index: Int) -> RefreshIntervalOption {
        guard index >= 0, index < allCases.count else { return .default }
        return allCases[index]
    }

    var index: Int {
        Self.allCases.firstIndex { $0.id == self.id } ?? 1
    }
}

// MARK: - Balance Change

struct BalanceChange: Equatable {
    let amount: Double
    let isIncrease: Bool

    var arrow: String { isIncrease ? "↑" : "↓" }
    var sign: String { isIncrease ? "+" : "-" }
    var formatted: String { "\(arrow) \(sign)\(String(format: "%.2f", abs(amount)))" }
    var formattedAmount: String { "\(sign)\(String(format: "%.2f", abs(amount)))" }
}

// MARK: - Balance History Entry

struct BalanceHistoryEntry: Codable, Identifiable, Equatable {
    let id: String
    let timestamp: Date
    let totalBalance: String
    let toppedUpBalance: String
    let grantedBalance: String
    let currency: String

    var formattedTime: String {
        let df = DateFormatter()
        df.dateFormat = "HH:mm:ss"
        return df.string(from: timestamp)
    }

    var formattedDate: String {
        let df = DateFormatter()
        df.dateFormat = "MM-dd"
        return df.string(from: timestamp)
    }
}

// MARK: - UserDefaults Keys

enum SettingsKey {
    static let refreshIntervalIndex = "refreshIntervalIndex"
    static let lowBalanceThreshold = "lowBalanceThreshold"
    static let lowBalanceNotificationEnabled = "lowBalanceNotificationEnabled"
}

// MARK: - ViewModel

@MainActor
final class BalanceViewModel: ObservableObject {
    @Published var totalBalance = "--"
    @Published var toppedUpBalance = "--"
    @Published var grantedBalance = "--"
    @Published var currency = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showSettings = false
    @Published var hasKeyConfigured = false
    @Published var notificationGranted = false
    @Published var balanceChange: BalanceChange? = nil
    @Published var history: [BalanceHistoryEntry] = []

    enum Page: String { case main, settings, history }
    @Published var activePage: Page = .main

    var menuBarText: String {
        if isLoading { return " ⟳ " }
        if errorMessage != nil { return " ⚠ " }
        guard !totalBalance.isEmpty, totalBalance != "--", !currency.isEmpty else { return " -- " }

        let base = "\(totalBalance) \(currency)"
        if let change = balanceChange {
            return "\(base)  \(change.arrow)\(String(format: "%.2f", abs(change.amount)))"
        }
        return base
    }

    var parsedThreshold: Double? {
        guard UserDefaults.standard.bool(forKey: SettingsKey.lowBalanceNotificationEnabled) else { return nil }
        let val = UserDefaults.standard.double(forKey: SettingsKey.lowBalanceThreshold)
        return val > 0 ? val : nil
    }

    private var refreshTask: Task<Void, Never>?
    private var clearChangeTask: Task<Void, Never>?
    private var timer: Timer?
    private var hasNotifiedLowBalance = false
    private var previousBalance: Double?
    private let historyKey = "balanceHistory"
    private let maxHistoryCount = 50

    var balanceText: String {
        if isLoading { return "⟳" }
        if errorMessage != nil { return "⚠︎" }
        guard !totalBalance.isEmpty, totalBalance != "--" else { return "-- \(currency)" }
        return "\(totalBalance) \(currency)"
    }

    private var apiKey: String {
        KeychainHelper.read() ?? ""
    }

    // MARK: - Init

    init() {
        hasKeyConfigured = KeychainHelper.read() != nil
        history = loadHistory()
        requestNotificationPermission()
        startAutoRefresh()
        refresh()
    }

    // MARK: - Public

    func refresh() {
        refreshTask?.cancel()
        refreshTask = Task { [weak self] in
            await self?.performRefresh()
        }
    }

    func saveAPIKey(_ key: String) {
        let saved = KeychainHelper.save(key)
        hasKeyConfigured = saved && !key.isEmpty
        if saved { refresh() }
    }

    func clearAPIKey() {
        KeychainHelper.delete()
        hasKeyConfigured = false
        totalBalance = "--"
        toppedUpBalance = "--"
        grantedBalance = "--"
        currency = ""
        errorMessage = "请设置 API Key"
    }

    /// Call when refresh interval changes
    func restartAutoRefresh() {
        startAutoRefresh()
    }

    /// Reset low-balance notification flag (called when threshold changes)
    func resetNotificationFlag() {
        hasNotifiedLowBalance = false
    }

    // MARK: - Login Item

    static func updateLoginItem(enabled: Bool) {
        if enabled {
            try? SMAppService.mainApp.register()
        } else {
            try? SMAppService.mainApp.unregister()
        }
    }

    // MARK: - History

    func clearHistory() {
        saveHistory([])
        history = []
    }

    func deltaSincePrevious(for entry: BalanceHistoryEntry) -> Double? {
        guard let idx = history.firstIndex(of: entry),
              idx + 1 < history.count,
              let current = Double(entry.totalBalance),
              let previous = Double(history[idx + 1].totalBalance) else {
            return nil
        }
        return current - previous
    }

    private func loadHistory() -> [BalanceHistoryEntry] {
        guard let data = UserDefaults.standard.data(forKey: historyKey),
              let entries = try? JSONDecoder().decode([BalanceHistoryEntry].self, from: data)
        else { return [] }
        return entries
    }

    private func saveHistory(_ entries: [BalanceHistoryEntry]) {
        guard let data = try? JSONEncoder().encode(entries) else { return }
        UserDefaults.standard.set(data, forKey: historyKey)
    }

    // MARK: - Private

    private func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { [weak self] granted, _ in
            Task { @MainActor in
                self?.notificationGranted = granted
            }
        }
    }

    private func performRefresh() async {
        let key = self.apiKey
        guard !key.isEmpty else {
            errorMessage = "请设置 API Key"
            return
        }

        isLoading = true
        errorMessage = nil

        var success = false

        do {
            let balance = try await DeepSeekAPIService.shared.fetchBalance(apiKey: key)
            try Task.checkCancellation()

            if let info = balance.balanceInfos.first {
                totalBalance = info.totalBalance
                toppedUpBalance = info.toppedUpBalance
                grantedBalance = info.grantedBalance
                currency = info.currency

                // Track balance change
                if let current = Double(info.totalBalance) {
                    if let prev = previousBalance, abs(current - prev) > 0.001 {
                        let delta = current - prev
                        balanceChange = BalanceChange(amount: delta, isIncrease: delta > 0)
                        clearChangeTask?.cancel()
                        clearChangeTask = Task { [weak self] in
                            try? await Task.sleep(nanoseconds: 15_000_000_000)
                            await MainActor.run {
                                self?.balanceChange = nil
                            }
                        }
                    }
                    previousBalance = current
                }

                // Record history (skip if balance unchanged)
                let shouldRecord: Bool = {
                    guard let lastEntry = loadHistory().first else { return true }
                    return lastEntry.totalBalance != info.totalBalance
                }()
                if shouldRecord {
                    let entry = BalanceHistoryEntry(
                        id: UUID().uuidString,
                        timestamp: Date(),
                        totalBalance: info.totalBalance,
                        toppedUpBalance: info.toppedUpBalance,
                        grantedBalance: info.grantedBalance,
                        currency: info.currency
                    )
                    var entries = loadHistory()
                    entries.insert(entry, at: 0)
                    if entries.count > maxHistoryCount {
                        entries = Array(entries.prefix(maxHistoryCount))
                    }
                    saveHistory(entries)
                    history = entries
                }
            }

            errorMessage = nil
            success = true
        } catch _ as DecodingError {
        errorMessage = "数据解析失败"
        } catch {
            try? Task.checkCancellation()
            errorMessage = error.localizedDescription
        }

        isLoading = false

        // Check low balance notification
        if success {
            checkLowBalance()
        }
    }

    private func checkLowBalance() {
        guard UserDefaults.standard.bool(forKey: SettingsKey.lowBalanceNotificationEnabled) else { return }
        guard notificationGranted else { return }

        let threshold = UserDefaults.standard.double(forKey: SettingsKey.lowBalanceThreshold)
        guard threshold > 0 else { return }

        guard let current = Double(totalBalance), current < threshold else {
            // Balance recovered, reset notification flag
            hasNotifiedLowBalance = false
            return
        }

        // Already notified for this low period
        guard !hasNotifiedLowBalance else { return }
        hasNotifiedLowBalance = true

        let content = UNMutableNotificationContent()
        content.title = "DeepSeek 余额不足"
        content.body = "当前余额 ¥\(String(format: "%.2f", current))，低于阈值 ¥\(String(format: "%.2f", threshold))"
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "low-balance-\(UUID().uuidString)",
            content: content,
            trigger: nil
        )

        UNUserNotificationCenter.current().add(request)
    }

    private func startAutoRefresh() {
        timer?.invalidate()

        let idx = UserDefaults.standard.integer(forKey: SettingsKey.refreshIntervalIndex)
        let interval = RefreshIntervalOption.from(index: idx)

        timer = Timer.scheduledTimer(withTimeInterval: interval.seconds, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refresh()
            }
        }
    }

    deinit {
        timer?.invalidate()
        refreshTask?.cancel()
        clearChangeTask?.cancel()
    }
}
