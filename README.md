# MDReader

零依赖、纯本地的 macOS Markdown 阅读器。双击 `.md` 文件即可打开，所有渲染在本地完成，**不联网、不上传**。

## 特性

- 双击 `.md` / `.markdown` / `.mdown` / `.mkd` 直接打开（可设为默认打开程序）
- 全中文界面，右键菜单也已中文化
- 实时 Markdown 渲染（`marked.js` 已内联进 HTML，**零外部依赖**，离线可用）
- 侧边目录（TOC）、全文搜索（`⌘/Ctrl+K`）、深色 / 浅色主题切换
- 最近打开记录、拖拽打开、一键在 Finder 中显示源文件
- **通用二进制**：同时支持 Apple Silicon（M1/M2/M3/M4）与 Intel Mac，要求 macOS 13.0+

## 下载与安装

从本仓库的 **Releases** 页面下载 `MDReader.dmg`，打开后把「MD Reader」拖到「应用程序」文件夹即可。

> ⚠️ 本应用使用免费的自签名（**未公证**）。首次打开若弹出"无法验证开发者"的提示，请**右键 → 打开**一次，之后即可双击正常启动。
> 如需把本应用设为 `.md` 文件的默认打开程序，仓库内附 `setdefault.swift`（需用 Xcode 命令行工具编译后运行）。

## 从源码构建

需要 macOS 13.0+ 与 Xcode 命令行工具（`xcode-select --install`）。

```bash
git clone <本仓库地址>
cd MDReader
bash build.sh
```

`build.sh` 会自动完成：

1. 把 `build/marked_min.js` 内联进 `reader_template.html` → 生成 `reader.html`
2. 分架构编译并 `lipo` 合并为通用二进制（arm64 + x86_64）
3. 组装 `.app` 并做临时自签名
4. 安装到 `/Applications/MDReader.app` 并产出 `MDReader.dmg`

> 提示：若仓库中未附带 `icon/MDReader.icns`，脚本会自动跳过图标步骤，应用仍可正常构建与运行（仅使用系统默认图标）。

## 目录结构

```
MDReader/
├── main.swift                      # AppKit + WKWebView 主程序（含中文右键菜单）
├── reader_template.html            # 阅读器页面模板（含 __MARKED_PLACEHOLDER__ 占位）
├── Info.plist                      # 应用描述 / 文件类型关联
├── build.sh                        # 一键构建脚本
├── setdefault.swift                # （可选）注册为 .md 默认打开程序
├── Resources/zh-Hans.lproj/        # 中文本地化
├── build/marked_min.js             # 内联的 marked.js v12（MIT）
└── icon/MDReader.icns              # 应用图标（可爱猫，可选）
```

## 许可证

本项目源代码以 **MIT 许可证**发布。内置的 `marked.js`（v12.0.2）为 Christopher Jeffrey 的作品，同样以 MIT 许可证授权。
