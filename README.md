# SlackMenuBadge

`SlackMenuBadge` 是一个轻量级 macOS Menu Bar 工具，用来把 Slack 的未读状态同步到系统右上角菜单栏。

它不修改 Slack 本身，而是读取 Slack 已经显示在 Dock 上的未读 badge，再把状态映射到 Menu Bar。目标就是补上 Slack 官方客户端在 macOS 上缺失的“菜单栏未读提醒”这一层体验。

## 功能

- 在 macOS 右上角 Menu Bar 显示 Slack 状态。
- 实时轮询 Slack 的 Dock 未读 badge。
- 有未读消息时显示数字。
- 没有未读消息时只显示 Slack 图标，不显示数字。
- Slack 未运行时仍保留菜单栏入口。
- 权限未就绪时显示 `?`，并提供打开系统设置的入口。

当前实现的行为接近微信的菜单栏提醒逻辑，但实现方式更轻量。

## 工作原理

Slack 官方 macOS 客户端没有提供一个稳定的本地接口给第三方读取未读数。

这个项目当前采用的方案是：

1. 确认 Slack 是否正在运行。
2. 通过 macOS Accessibility 访问 `Dock` 进程的 UI 元素。
3. 找到 Slack 在 Dock 中对应的图标。
4. 读取 Dock item 的 `AXStatusLabel`。
5. 将这个值显示到 Menu Bar。

这意味着它依赖：

- macOS 的 `Accessibility` 权限
- 当前版本 Slack 在 Dock 上的 badge 表现
- 当前版本 macOS 的 Dock 可访问性结构

这不是 Slack 官方 API 级别的稳定集成，但对个人桌面工具来说是一个足够轻、足够直接的工程方案。

## 效果说明

- 有未读：菜单栏显示 `Slack 图标 + 数字`
- 无未读：菜单栏只显示 `Slack 图标`
- 无权限：菜单栏显示 `Slack 图标 + ?`
- Slack 未启动：菜单栏只显示 `Slack 图标`

## 系统要求

- macOS 13 或更高版本
- Swift 6 toolchain
- 已安装 Slack for macOS

## 快速开始

### 1. 直接运行

```bash
swift run SlackMenuBadge
```

### 2. 打包成 `.app`

```bash
./scripts/package_app.sh
```

默认会生成：

```text
~/Downloads/SlackMenuBadge.app
```

## 如何使用

### 首次运行

1. 启动 Slack。
2. 启动 `SlackMenuBadge`。
3. 观察菜单栏是否出现 Slack 图标。

### 菜单项

应用当前提供这些菜单项：

- `Refresh Now`
- `Open Slack`
- `Accessibility Setup`
- `Quit SlackMenuBadge`

## 权限设置

这个工具必须拿到 `Accessibility` 权限，否则无法读取 Dock 上 Slack 的未读 badge。

### 授权步骤

1. 打开 `System Settings`
2. 进入 `Privacy & Security`
3. 打开 `Accessibility`
4. 给 `SlackMenuBadge` 打开权限
5. 完全退出 `SlackMenuBadge`
6. 重新启动 `SlackMenuBadge`

### 权限是否生效的判断

- 如果菜单栏显示数字，说明权限已生效
- 如果菜单栏显示 `?`，通常说明权限还没真正对当前进程生效

### 常见问题

如果你已经勾选了权限，但还是显示 `?`，通常按下面顺序处理即可：

1. 退出 `SlackMenuBadge`
2. 在 `Accessibility` 设置里关闭再重新打开权限
3. 重新启动 `SlackMenuBadge`
4. 还不行的话，把 `SlackMenuBadge` 从权限列表里移除，再重新打开 app 让系统重新授权

## 项目结构

```text
.
├── AppResources/
│   ├── AppIcon.svg
│   ├── Info.plist
│   ├── slack-icon.png
│   ├── slack-icon.svg
│   └── slack.svg
├── scripts/
│   └── package_app.sh
├── Sources/
│   └── main.swift
├── Package.swift
└── README.md
```

## 开发说明

### 本地开发

直接运行：

```bash
swift run
```

或显式执行：

```bash
swift run SlackMenuBadge
```

### 构建

```bash
swift build
```

### 发布包

```bash
./scripts/package_app.sh
```

### 核心代码位置

- 菜单栏应用入口：`Sources/main.swift`
- 未读读取逻辑：`SlackUnreadProvider`
- app 打包脚本：`scripts/package_app.sh`
- app Finder 图标：`AppResources/AppIcon.svg`
- 菜单栏图标资源：`AppResources/slack-icon.png`

## 如何继续开发

如果你要继续迭代这个项目，建议按下面几个方向扩展。

### 1. 提升未读读取稳定性

当前方案依赖 AppleScript + `System Events` + Dock UI 层级。

可继续优化的方向：

- 改成更细的 AX API 检测，减少对 AppleScript 文本返回的依赖
- 区分“权限缺失”和“Dock 数据暂时不可用”
- 增加 Slack 进程名、bundle id、窗口状态的兼容判断

### 2. 增强权限引导

目前权限处理已经可用，但仍偏工程化。

可以继续做：

- 启动时主动检测权限状态
- 在无权限时弹出更明确的引导
- 在授权后自动提示用户重启应用

### 3. 优化菜单栏 UI

当前 UI 已经满足核心需求，但还可以继续打磨：

- 更像微信的红点 / 徽标表现
- 图标和数字间距进一步微调
- 更丰富的 tooltip 和状态文案

### 4. 增加开机自启动

这是最自然的下一步能力。可以考虑：

- 使用 `SMAppService`
- 增加菜单项控制开机启动开关

### 5. 提供更规范的安装方式

当前是脚本打包模式。后续可以考虑：

- 生成可分发的 Release 包
- 签名与公证
- Homebrew Cask 或安装脚本

## 已知限制

- 强依赖 `Accessibility` 权限
- 强依赖 Slack 当前的 Dock badge 实现
- 如果 Slack 或 macOS 改了相关 UI 结构，可能需要适配
- 当前轮询间隔是 5 秒，不是事件驱动
- 当前默认只支持标准 Slack macOS 客户端

## 图标与资源

- 菜单栏图标基于 Slack 图形资源制作
- Finder app 图标改为仓库内的黑白 SVG 版本，并在打包时转换为 `icns`

参考入口：

- [Slack Media Kit](https://slack.com/media-kit)

## 后续建议

如果你准备把这个项目长期维护下去，推荐下一步优先做：

1. 开机自启动
2. 更稳的权限检测
3. 原生 AX API 替换部分 AppleScript
4. 正式签名和公证

