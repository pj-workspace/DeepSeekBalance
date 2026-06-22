import SwiftUI
import Charts

// MARK: - Filter

enum HistoryFilter: String, CaseIterable {
    case oneHour = "近1时"
    case fiveHours = "近5时"
    case oneDay = "近1天"
    case oneWeek = "近1周"
    case oneMonth = "近1月"
    case all = "全部"

    var timeInterval: TimeInterval? {
        switch self {
        case .oneHour: return 3600
        case .fiveHours: return 18000
        case .oneDay: return 86400
        case .oneWeek: return 604800
        case .oneMonth: return 2592000
        case .all: return nil
        }
    }
}

// MARK: - History View

struct HistoryView: View {
    @ObservedObject var viewModel: BalanceViewModel
    let onBack: () -> Void
    @State private var filter: HistoryFilter = .all

    private var filteredHistory: [BalanceHistoryEntry] {
        let all = viewModel.history
        guard let interval = filter.timeInterval else { return all }
        return all.filter { $0.timestamp.timeIntervalSinceNow > -interval }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            header
            Divider()

            if viewModel.history.isEmpty {
                emptyState
            } else {
                // Filter bar
                Picker("筛选", selection: $filter) {
                    ForEach(HistoryFilter.allCases, id: \.self) { f in
                        Text(f.rawValue).tag(f)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                // Chart
                balanceChart
                    .padding(.horizontal, 4)

                Divider()

                // List
                historyList
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button { onBack() } label: {
                HStack(spacing: 4) {
                    Image(systemName: "chevron.left").font(.caption)
                    Text("返回").font(.subheadline)
                }
            }
            .buttonStyle(.plain).foregroundColor(.accentColor)

            Spacer()
            Text("历史记录").font(.headline)
            Spacer()

            Button { viewModel.clearHistory() } label: {
                Image(systemName: "trash").font(.caption)
            }
            .buttonStyle(.plain).foregroundColor(.red)
            .opacity(viewModel.history.isEmpty ? 0.3 : 1)
            .disabled(viewModel.history.isEmpty)
            .help("清除历史")
        }
        .padding(.horizontal, 16).padding(.vertical, 10)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer().frame(height: 40)
            Image(systemName: "clock.arrow.circlepath")
                .font(.title2).foregroundColor(.secondary.opacity(0.5))
            Text("暂无历史记录").font(.subheadline).foregroundColor(.secondary)
            Spacer().frame(height: 40)
        }
    }

    // MARK: - Chart

    private var balanceChart: some View {
        let data = filteredHistory
        guard data.count >= 2 else {
            return AnyView(
                HStack {
                    Spacer()
                    Text("数据不足，无法绘制图表")
                        .font(.caption).foregroundColor(.secondary)
                    Spacer()
                }
                .frame(height: 80)
            )
        }

        // Sample data if too many points
        let chartData: [BalanceHistoryEntry] = data.count > 100
            ? stride(from: 0, to: data.count, by: max(1, data.count / 100)).map { data[$0] }
            : data

        // Compute dynamic Y-axis domain with padding
        let values = chartData.compactMap { Double($0.totalBalance) }
        var yDomain: ClosedRange<Double>
        if let minVal = values.min(), let maxVal = values.max(), maxVal > minVal {
            let range = maxVal - minVal
            let padding = max(range * 0.2, 0.5)
            yDomain = (minVal - padding)...(maxVal + padding)
        } else {
            yDomain = 0...100
        }
        let avgVal = values.isEmpty ? 0 : values.reduce(0, +) / Double(values.count)

        let xCount: Int = {
            switch filter {
            case .oneHour: return 6
            case .fiveHours: return 6
            case .oneDay: return 5
            case .oneWeek: return 5
            case .oneMonth, .all: return 4
            }
        }()

        return AnyView(
            Chart(chartData.reversed()) { entry in
                if let value = Double(entry.totalBalance) {
                    // Average reference line
                    RuleMark(y: .value("平均", avgVal))
                        .foregroundStyle(.gray.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))

                    // Area fill
                    AreaMark(
                        x: .value("时间", entry.timestamp),
                        y: .value("余额", value)
                    )
                    .foregroundStyle(.blue.opacity(0.06).gradient)
                    .interpolationMethod(.catmullRom)

                    // Line
                    LineMark(
                        x: .value("时间", entry.timestamp),
                        y: .value("余额", value)
                    )
                    .foregroundStyle(.blue.gradient)
                    .interpolationMethod(.catmullRom)
                    .symbol {
                        Circle()
                            .strokeBorder(.blue, lineWidth: 1.5)
                            .frame(width: 5, height: 5)
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: xCount)) { value in
                    AxisValueLabel(format: xAxisFormat)
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                    AxisGridLine()
                        .foregroundStyle(.gray.opacity(0.12))
                    AxisValueLabel()
                }
            }
            .chartYScale(domain: yDomain)
            .chartLegend(.hidden)
            .frame(height: 150)
            .padding(.vertical, 4)
        )
    }

    private var xAxisFormat: Date.FormatStyle {
        switch filter {
        case .oneHour, .fiveHours, .oneDay:
            return .dateTime.hour().minute()
        case .oneWeek, .oneMonth, .all:
            return .dateTime.month().day()
        }
    }

    // MARK: - List

    private var historyList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(filteredHistory.prefix(30)) { entry in
                    HistoryRow(
                        entry: entry,
                        delta: viewModel.deltaSincePrevious(for: entry)
                    )
                    Divider().padding(.leading, 56)
                }
            }
            .padding(.vertical, 4)
        }
    }
}

// MARK: - History Row

struct HistoryRow: View {
    let entry: BalanceHistoryEntry
    let delta: Double?

    var body: some View {
        HStack(spacing: 10) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(entry.formattedTime)
                    .font(.caption).fontWeight(.medium).foregroundColor(.primary)
                Text(entry.formattedDate)
                    .font(.caption2).foregroundColor(.secondary)
            }
            .frame(width: 48, alignment: .trailing)

            Text("\(entry.totalBalance) \(entry.currency)")
                .font(.subheadline).fontWeight(.medium)
                .monospacedDigit()
                .frame(minWidth: 70, alignment: .trailing)

            Spacer()

            if let d = delta, abs(d) > 0.001 {
                HStack(spacing: 2) {
                    Image(systemName: d > 0 ? "arrow.up" : "arrow.down")
                        .font(.caption2)
                    Text(String(format: "%.2f", abs(d)))
                        .font(.caption).fontWeight(.medium).monospacedDigit()
                }
                .foregroundColor(d > 0 ? .green : .red)
                .frame(width: 64, alignment: .trailing)
            } else {
                Text("—")
                    .font(.caption).foregroundColor(.secondary)
                    .frame(width: 64, alignment: .trailing)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }
}
