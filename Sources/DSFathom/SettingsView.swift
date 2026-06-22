import SwiftUI
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var viewModel: BalanceViewModel
    @Binding var isPresented: Bool

    @State private var keyInput = ""
    @State private var keyVisible = false

    @AppStorage("launchAtLogin") private var launchAtLogin = false
    @AppStorage(SettingsKey.refreshIntervalIndex) private var refreshIntervalIndex = RefreshIntervalOption.default.index
    @AppStorage(SettingsKey.lowBalanceThreshold) private var lowBalanceThreshold = 10.0
    @AppStorage(SettingsKey.lowBalanceNotificationEnabled) private var lowBalanceNotificationEnabled = false

    var body: some View {
        VStack(spacing: 0) {
            // ===== Header =====
            HStack {
                Image(systemName: "gearshape.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                Text("设置")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button { isPresented = false } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("返回")
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            ScrollView {
                VStack(spacing: 20) {
                    // ===== Section: API Key =====
                    SettingsSection(label: "API Key", icon: "key.fill") {
                        HStack(spacing: 8) {
                            if keyVisible {
                                TextField("sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", text: $keyInput)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body.monospaced())
                            } else {
                                SecureField("sk-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", text: $keyInput)
                                    .textFieldStyle(.roundedBorder)
                                    .font(.body.monospaced())
                            }
                            Button { keyVisible.toggle() } label: {
                                Image(systemName: keyVisible ? "eye.slash" : "eye")
                                    .foregroundColor(.secondary)
                            }
                            .buttonStyle(.plain)
                        }

                        if viewModel.hasKeyConfigured {
                            Label("Key 已保存在钥匙串中", systemImage: "checkmark.circle.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }

                    // ===== Section: General =====
                    SettingsSection(label: "通用", icon: "folder") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("开机自启")
                                    .font(.subheadline)
                                Text("登录 Mac 时自动启动")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $launchAtLogin)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                                .onChange(of: launchAtLogin) { _, newValue in
                                    BalanceViewModel.updateLoginItem(enabled: newValue)
                                }
                        }
                    }

                    // ===== Section: Refresh =====
                    SettingsSection(label: "刷新", icon: "arrow.clockwise") {
                        HStack {
                            Text("刷新间隔")
                                .font(.subheadline)
                            Spacer()
                            Picker("", selection: $refreshIntervalIndex) {
                                ForEach(Array(RefreshIntervalOption.allCases.enumerated()), id: \.offset) { idx, opt in
                                    Text(opt.rawValue).tag(idx)
                                }
                            }
                            .pickerStyle(.menu)
                            .controlSize(.small)
                            .frame(width: 130)
                            .onChange(of: refreshIntervalIndex) { _, _ in
                                viewModel.restartAutoRefresh()
                            }
                        }
                    }

                    // ===== Section: Notifications =====
                    SettingsSection(label: "通知", icon: "bell.badge") {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("余额过低提醒")
                                    .font(.subheadline)
                                Text("余额低于阈值时发送通知")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: $lowBalanceNotificationEnabled)
                                .toggleStyle(.switch)
                                .controlSize(.small)
                        }

                        if lowBalanceNotificationEnabled {
                            HStack {
                                Text("低于")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                TextField("10.00", value: $lowBalanceThreshold, format: .number.precision(.fractionLength(2)))
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 80)
                                    .font(.body.monospacedDigit())
                                Text("CNY 时通知")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .onChange(of: lowBalanceThreshold) { _, _ in
                                viewModel.resetNotificationFlag()
                            }

                            if !viewModel.notificationGranted {
                                Label("请在系统设置中允许通知", systemImage: "exclamationmark.triangle.fill")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                        }
                    }
                }
                .padding(24)
            }

            Divider()

            // ===== Bottom Actions =====
            HStack(spacing: 12) {
                Button("清除 Key") {
                    viewModel.clearAPIKey()
                    keyInput = ""
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .tint(.red)
                .disabled(!viewModel.hasKeyConfigured)
                .controlSize(.small)

                Spacer()

                Button("取消") {
                    isPresented = false
                }
                .buttonStyle(.bordered)
                .controlSize(.small)

                Button("保存") {
                    viewModel.saveAPIKey(keyInput.trimmingCharacters(in: .whitespacesAndNewlines))
                    isPresented = false
                }
                .buttonStyle(.borderedProminent)
                .disabled(keyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .controlSize(.small)
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
        }
        .frame(width: 480, height: 520)
        .onAppear {
            keyInput = KeychainHelper.read() ?? ""
        }
    }
}

// MARK: - Settings Section Component

struct SettingsSection<Content: View>: View {
    let label: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(label, systemImage: icon)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
                .textCase(.uppercase)

            VStack(spacing: 12) {
                content
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color(.separatorColor).opacity(0.3), lineWidth: 1)
            )
        }
    }
}
