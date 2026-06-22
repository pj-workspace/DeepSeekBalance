# DeepSeek Balance

A lightweight macOS menu bar app that displays your DeepSeek API account balance in real-time.

一款轻量的 macOS 菜单栏应用，实时显示你的 DeepSeek API 账户余额。

---

## Features / 功能

- **Real-time Balance Display** — Shows total / topped-up / granted balance in the menu bar
- **Balance Change Indicator** — Green ↑ for increase, Red ↓ for decrease, auto-fades after 15s
- **Low Balance Notification** — Native macOS notification when balance drops below a configurable threshold
- **Balance History** — Records snapshots on every change with a line chart and filterable list (1h / 5h / 1d / 1w / 1m / All)
- **Custom Refresh Interval** — 10s / 1min / 5min / 15min / 30min / 1h
- **Launch at Login** — Auto-starts when you log in to macOS
- **Keychain Security** — API key stored in macOS Keychain, no plaintext on disk

| 实时余额显示 | 余额变化指示 | 
|:---:|:---:|
| 总/充值/赠送余额 | 绿色 ↑ / 红色 ↓ |
| **余额过低通知** | **历史记录 + 折线图** |
| 低于阈值时系统通知 | 时间筛选 + 趋势图 |

## Screenshots / 截图

| Main Dashboard | Settings | History & Chart |
|:---:|:---:|:---:|
| ![main](assets/screenshot-main.png) | ![settings](assets/screenshot-settings.png) | ![history](assets/screenshot-history.png) |
| Balance overview, notification status, and actions | API key, launch at login, refresh interval, alerts | Time filter, line chart, change history list |

## Requirements / 系统要求

- macOS 14.0+ (Sonoma)
- Apple Silicon or Intel
- DeepSeek API Key (from [platform.deepseek.com](https://platform.deepseek.com))

## Installation / 安装

### Option 1: Download pre-built .app

Download the latest `DeepSeekBalance.app` from [Releases](../../releases), move it to `/Applications`.

### Option 2: Build from source

```bash
git clone https://github.com/pj-workspace/DeepSeekBalance.git
cd DeepSeekBalance
./build.sh
cp -r DeepSeekBalance.app /Applications/
```

The build script requires **Xcode Command Line Tools**:

```bash
xcode-select --install
```

## First Run / 首次使用

1. Launch DeepSeekBalance.app
2. Click the menu bar → click **设置 (Settings)**
3. Enter your DeepSeek API Key (from [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys))
4. Click **保存 (Save)**
5. The menu bar now shows your balance — done!

| 步骤 | 说明 |
|:---:|:---|
| 1 | 启动 App，点击菜单栏 `$` 图标 |
| 2 | 下拉菜单 →「设置」 |
| 3 | 输入 API Key →「保存」 |
| 4 | 菜单栏实时显示余额 |

> 💡 For "Launch at Login" to work, place the app in `/Applications` first.

## Configuration / 配置

| Setting | Description | 说明 |
|---------|-------------|------|
| API Key | Stored in macOS Keychain | 存储在钥匙串中 |
| Launch at Login | Auto-start on macOS login | 开机自启 |
| Refresh Interval | 10s / 1min / 5min / 15min / 30min / 1h | 刷新间隔 |
| Low Balance Alert | Threshold + native notification | 余额过低通知 |

## Project Structure / 项目结构

```
DeepSeekBalance/
├── Sources/
│   └── DeepSeekBalance/     # Swift source files
│       ├── DeepSeekBalanceApp.swift    # @main app entry + MenuBarExtra
│       ├── DeepSeekAPIService.swift    # DeepSeek API client
│       ├── BalanceViewModel.swift      # State management + business logic
│       ├── SettingsView.swift          # Settings UI
│       ├── HistoryView.swift           # History chart & list
│       └── KeychainHelper.swift        # macOS Keychain wrapper
├── assets/                  # README screenshots
├── build.sh                 # Build script
├── Package.swift             # Swift Package manifest (reference)
└── README.md
```

## Tech Stack / 技术栈

- **Swift 6** with SwiftUI
- `MenuBarExtra` — macOS native menu bar
- `Charts` framework — line chart
- `Security` framework — Keychain access
- `ServiceManagement` — Launch at login
- `UserNotifications` — Low balance alerts

## License / 许可

MIT License — see [LICENSE](LICENSE).

---

Made by [Jay Pan (pj-workspace)](https://github.com/pj-workspace)
