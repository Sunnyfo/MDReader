# MD Reader — Windows 版

一个**纯本地**的 Markdown 阅读器：双击 `.md` 文件即可阅读，支持目录、全文搜索、暗色模式、拖拽打开、最近文件。
**不联网、不上传**，所有解析都在你自己的电脑上完成。

> 说明：本版本用「PowerShell 本地服务 + 系统默认浏览器」实现，**无需安装、无需联网下载任何东西**，在 Windows 10 / 11 上直接可用。
> 如果你想要「内嵌窗口、不弹浏览器」的真正编译型 `.exe`（基于 WebView2），见文末「进阶：编译内嵌窗口版」。

---

## 一、快速开始

1. 把本文件夹（整个 `MDReader-Windows` 目录）解压到任意位置，例如 `D:\MDReader-Windows\`。
2. **首次使用，做一次性设置**（二选一）：
   - **推荐（管理员）**：右键 `install.bat` → 「以管理员身份运行」。它会注册本地端口权限并把 `.md` 关联到本程序。
   - **不想要管理员**：直接双击 `associate.bat`（仅写入当前用户的文件关联，无需管理员；若双击 `.md` 提示端口权限错误，再按下方「端口权限」处理）。
3. 之后：
   - **双击任意 `.md` 文件** → 自动用 MD Reader 打开。
   - 或双击 `MDReader.bat` → 打开一个空白阅读器，点左上角「打开」选择文件，或直接把 `.md` 拖进窗口。

---

## 二、功能

- 顶部工具栏：「打开」「打开文件夹」「搜索（Ctrl/⌘+K）」「暗色切换」「目录折叠」「退出」。
- 左侧目录自动生成，点击跳转；全文搜索支持上一个/下一个（↑/↓）。
- 拖拽 `.md` 进窗口即可打开；最近打开的文件会记录在左侧。
- 暗色模式跟随系统，也可手动切换，选择会被记住。
- 窗口右上角「✕」退出会同时关闭本地服务进程。

---

## 三、工作原理 & 隐私

- `MDReader.bat` 以**隐藏窗口**启动 `MDReader.ps1`：后者在 `127.0.0.1:18999` 起一个本地 HTTP 服务，把 `reader.html` 提供给你的**默认浏览器**（Edge / Chrome / Firefox 均可）。
- 文档内容只在本地读取与渲染，**不会发送任何网络请求**。关闭窗口后本地服务自动停止。
- 文件关联写入 `HKEY_CURRENT_USER`（当前用户），不影响其他用户、不需要管理员。

---

## 四、常见问题

**Q：双击 `.md` 报错 / 浏览器空白？**
A：多半是本地端口权限。以管理员身份运行一次 `install.bat` 即可（它会执行 `netsh http add urlacl url=http://127.0.0.1:18999/ user=Everyone`）。

**Q：我把文件夹移动了位置，双击 `.md` 失效？**
A：关联里记录的是旧路径。重新运行一次 `associate.bat`（或 `install.bat`）即可刷新。

**Q：想换默认浏览器？**
A：本程序用系统「默认浏览器」打开阅读页，在 Windows 设置里改默认浏览器即可。

**Q：杀毒软件报警？**
A：本程序只是 PowerShell 脚本 + 本地服务，行为透明。如被拦截，请把 `MDReader-Windows` 目录加入白名单。

---

## 五、进阶：编译「内嵌窗口」的真正 `.exe`（WebView2）

当前版本借浏览器渲染。若你想要**不弹浏览器、内嵌窗口**的体验，可用 [Neutralinojs](https://neutralino.js.org/) 把它编译成真正的 Windows `.exe`（基于系统自带的 Edge WebView2）：

1. 进入 `neutralino-src/` 目录（已内置适配好的 `app/index.html`、`app/js/main.js`、`neutralino.config.json`）。
2. 安装 Node.js 与 `@neutralinojs/neu`：`npm install -g @neutralinojs/neu`
3. 联网执行：`neu build --target win_x64`（会自动下载 Windows 运行时并打包）。
4. 产物在 `dist/MDReader.exe`，双击即用，无需浏览器。
5. 想要安装包（含开始菜单、卸载、文件关联）：用仓库里的 NSIS 脚本（或 `neu build` 后自行打包）即可生成标准 `.exe` 安装程序。

> 注：这一步需要**能访问 GitHub 下载** Neutralino 运行时的网络环境（编译在本机进行，不影响已发布的脚本版）。

---

## 六、文件清单

| 文件 | 作用 |
| --- | --- |
| `reader.html` | 阅读器页面（已内联 marked.js，含目录/搜索/暗色等） |
| `MDReader.ps1` | 本地 HTTP 服务 + 文件关联逻辑 |
| `MDReader.bat` | 启动器（隐藏运行 PowerShell，可接收 `.md` 路径） |
| `associate.bat` | 仅做文件关联（无需管理员） |
| `install.bat` | 管理员一次性安装（端口权限 + 文件关联） |
| `build_reader.py` | 由 macOS 版模板生成 `reader.html` 的脚本（可复现） |
| `neutralino-src/` | 进阶：编译内嵌窗口 `.exe` 的工程源码 |
