[English](README.md)

| | | |
|:---:|:---:|:---:|
| ![主界面](assets/screenshot-main.png) | ![设置面板](assets/screenshot-settings.png) | ![历史记录](assets/screenshot-history.png) |
| 余额总览 | 设置面板 | 历史记录 |

# DS-Fathom

*DeepSeek 余额监控* — 在菜单栏实时查看你的 DeepSeek API 账户余额

一款轻量的 macOS 菜单栏应用，实时显示你的 DeepSeek API 账户余额。

---

## 功能

- **实时余额显示** — 菜单栏直接显示总余额、充值余额、赠送余额
- **变化指示** — 余额增加显示绿色 ↑，减少显示红色 ↓，15 秒后自动淡出
- **余额过低通知** — 低于可配置阈值时，发送 macOS 原生通知
- **历史记录** — 每次变化自动记录快照，支持折线图 + 时间筛选（近1时 / 5时 / 1天 / 1周 / 1月 / 全部）
- **自定义刷新间隔** — 可选 10秒 / 1分钟 / 5分钟 / 15分钟 / 30分钟 / 1小时
- **开机自启** — 登录 Mac 时自动启动
- **钥匙串安全存储** — API Key 存储在 macOS 钥匙串中，不落盘明文

## 系统要求

- macOS 14.0+ (Sonoma)
- Apple Silicon 或 Intel
- 在 [platform.deepseek.com](https://platform.deepseek.com) 申请的 API Key

## 安装

### 下载

[![下载 DMG](https://img.shields.io/github/v/release/pj-workspace/DS-Fathom?label=%E4%B8%8B%E8%BD%BD%20DMG&color=blue)](https://github.com/pj-workspace/DS-Fathom/releases/latest)

从 [Releases 页面](https://github.com/pj-workspace/DS-Fathom/releases) 下载最新的 `DeepSeekBalance-x.x.x.dmg`，打开后将 `DS-Fathom.app` 拖入 `Applications` 文件夹即可。

### 从源码编译

```bash
git clone https://github.com/pj-workspace/DS-Fathom.git
cd DeepSeekBalance
./build.sh
cp -r DS-Fathom.app /Applications/
```

需要 Xcode Command Line Tools：

```bash
xcode-select --install
```

## 首次使用

1. 启动 `DS-Fathom.app`
2. 点击菜单栏图标 → **设置**
3. 输入你的 DeepSeek API Key（在 [platform.deepseek.com/api_keys](https://platform.deepseek.com/api_keys) 获取）
4. 点击 **保存**
5. 菜单栏立即显示余额

> 开机自启功能需要将 App 放在 `/Applications` 目录下才能生效。

## 配置项

| 设置 | 说明 |
|------|------|
| API Key | 存储在 macOS 钥匙串中 |
| 开机自启 | 登录时自动启动 |
| 刷新间隔 | 10秒 / 1分 / 5分 / 15分 / 30分 / 1小时 |
| 余额过低通知 | 设置阈值，低于时系统通知 |

## 项目结构

```
DS-Fathom/
├── Sources/DS-Fathom/
│   ├── DeepSeekBalanceApp.swift    # @main 入口 + MenuBarExtra + 下拉视图
│   ├── DeepSeekAPIService.swift    # 余额 API 客户端
│   ├── BalanceViewModel.swift      # 状态管理与业务逻辑
│   ├── SettingsView.swift          # 设置界面
│   ├── HistoryView.swift           # 历史记录与折线图
│   └── KeychainHelper.swift        # 钥匙串读写封装
├── assets/                         # README 截图
├── build.sh                        # 编译签名脚本
├── Package.swift                   # SPM 声明
├── README.md
├── README.zh.md
└── LICENSE
```

## 技术栈

- **Swift 6** + SwiftUI
- `MenuBarExtra` — macOS 原生菜单栏集成
- `Charts` — 余额历史折线图
- `Security` — 钥匙串 API Key 存储
- `ServiceManagement` — 开机自启
- `UserNotifications` — 余额过低通知

## 许可

MIT 协议 — 详见 [LICENSE](LICENSE)。

---

Made by [Jay Pan (pj-workspace)](https://github.com/pj-workspace)
