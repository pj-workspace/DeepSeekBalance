import SwiftUI
import ServiceManagement

@main
struct DeepSeekBalanceApp: App {
    @StateObject private var viewModel = BalanceViewModel()

    var body: some Scene {
        MenuBarExtra {
            DropdownView(viewModel: viewModel)
        } label: {
            HStack(spacing: 3) {
                Text(viewModel.balanceText)
                    .monospacedDigit()
                Group {
                    if let change = viewModel.balanceChange {
                        Text(change.arrow)
                            .foregroundColor(change.isIncrease ? .green : .red)
                        Text(change.formattedAmount)
                            .foregroundColor(change.isIncrease ? .green : .red)
                            .monospacedDigit()
                    }
                }
                .frame(width: 52, alignment: .leading)
                .opacity(viewModel.balanceChange != nil ? 1 : 0)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

struct DropdownView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @AppStorage("lowBalanceNotificationEnabled") private var notifyEnabled = false
    @State private var showSettings = false
    @State private var showHistory = false

    var body: some View {
        Group {
            if showHistory {
                HistoryView(viewModel: viewModel, onBack: { showHistory = false })
                    .transition(.opacity)
            } else if showSettings {
                SettingsView(viewModel: viewModel, isPresented: $showSettings)
                    .transition(.opacity)
            } else {
                dropdownContent
                    .transition(.opacity)
            }
        }
        .frame(width: showSettings ? 480 : showHistory ? 420 : 260)
        .frame(minHeight: showSettings ? 520 : showHistory ? 420 : 260)
        .animation(.easeInOut(duration: 0.15), value: showSettings)
        .animation(.easeInOut(duration: 0.15), value: showHistory)
    }

    // MARK: - Dropdown Content

    private var dropdownContent: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack {
                Image(systemName: "brain.head.profile")
                    .foregroundColor(.accentColor)
                Text("DeepSeek Balance")
                    .font(.headline)
                    .foregroundColor(.primary)
                Spacer()
                if viewModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.7)
                        .controlSize(.small)
                }
            }

            Divider()

            // Error
            if let error = viewModel.errorMessage {
                HStack {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            // Balances
            BalanceRow(label: "总余额", value: viewModel.totalBalance, currency: viewModel.currency)
            BalanceRow(label: "充值余额", value: viewModel.toppedUpBalance, currency: viewModel.currency)
            BalanceRow(label: "赠送余额", value: viewModel.grantedBalance, currency: viewModel.currency)

            // Notification status
            if notifyEnabled, let th = viewModel.parsedThreshold {
                HStack {
                    Image(systemName: "bell.badge.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                    Text("低于 ¥\(th, specifier: "%.2f") 时通知")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            Divider()

            // Actions
            HStack {
                Button { viewModel.refresh() } label: {
                    Label("刷新", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .help("立即刷新")

                Spacer()

                Button { showHistory = true } label: {
                    Label("历史", systemImage: "clock.arrow.circlepath")
                }
                .buttonStyle(.plain)
                .font(.subheadline)

                Button { showSettings = true } label: {
                    Label("设置", systemImage: "gearshape")
                }
                .buttonStyle(.plain)
                .font(.subheadline)

                Button { NSApplication.shared.terminate(nil) } label: {
                    Label("退出", systemImage: "xmark.circle")
                }
                .buttonStyle(.plain)
                .font(.subheadline)
                .foregroundColor(.red)
            }
        }
        .padding()
    }
}

struct BalanceRow: View {
    let label: String
    let value: String
    let currency: String

    var body: some View {
        HStack {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Spacer()
            Text("\(value) \(currency)")
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundColor(.primary)
        }
    }
}
