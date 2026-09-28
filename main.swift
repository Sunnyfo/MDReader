import Cocoa
import WebKit

// MARK: - 中文右键菜单

/// WKWebView 默认右键菜单是英文的（因为 App 未声明中文本地化）。
/// 这里重写 willOpenMenu，把菜单项标题逐个替换成中文，功能（target/action）保持不变。
final class LocalizedWebView: WKWebView {

    private static let zhMap: [String: String] = [
        "Copy": "拷贝",
        "Cut": "剪切",
        "Paste": "粘贴",
        "Delete": "删除",
        "Select All": "全选",
        "Copy Link": "拷贝链接",
        "Copy Link Address": "拷贝链接地址",
        "Copy Image": "拷贝图像",
        "Copy Image Address": "拷贝图像地址",
        "Copy Image URL": "拷贝图像地址",
        "Save Image": "存储图像",
        "Save Image As…": "存储图像为…",
        "Save Image As...": "存储图像为…",
        "Add Image to Photos": "添加到「照片」",
        "Open Link": "打开链接",
        "Open Link in New Window": "在新窗口打开链接",
        "Open Link in New Tab": "在新标签页打开链接",
        "Open Image": "打开图像",
        "Open Image in New Window": "在新窗口打开图像",
        "Open Media in New Window": "在新窗口打开媒体",
        "Download Linked File": "下载链接文件",
        "Download Image": "下载图像",
        "Reload": "重新加载",
        "Back": "后退",
        "Forward": "前进",
        "Services": "服务",
        "Font": "字体",
        "Speech": "语音",
        "Start Speaking": "开始朗读",
        "Stop Speaking": "停止朗读",
        "Translate": "翻译",
        "Translate Selection": "翻译所选内容",
        "Search with Google": "用 Google 搜索",
        "Search Web": "在网页中搜索",
        "Inspect Element": "检查元素",
        "Show Writing Tools": "显示书写工具",
        "Writing Tools": "书写工具",
        "Proofread": "校对",
        "Rewrite": "重写",
        "Friendly": "友好",
        "Professional": "专业",
        "Concise": "简洁",
        "Summary": "摘要",
        "Key Points": "要点",
        "List": "列表",
        "Table": "表格",
        "Compose": "撰写",
        "Copy Selection": "拷贝所选内容",
        "Look Up": "查询"
    ]

    override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
        super.willOpenMenu(menu, with: event)
        LocalizedWebView.localize(menu)
    }

    private static func localize(_ menu: NSMenu) {
        for item in menu.items {
            if let sub = item.submenu { localize(sub) }
            let title = item.title
            if title.isEmpty { continue }
            if let hit = zhMap[title] { item.title = hit; continue }
            // 动态标题：Look Up “xx” / Search with xx
            if let r = title.range(of: "Look Up") {
                item.title = "查询" + title[r.upperBound...]
            } else if let r = title.range(of: "Search with ") {
                item.title = "用 " + title[r.upperBound...] + " 搜索"
            }
        }
    }
}

// MARK: - 应用主体

final class AppDelegate: NSObject, NSApplicationDelegate, WKNavigationDelegate, WKScriptMessageHandler {

    var window: NSWindow!
    var webView: LocalizedWebView!
    var pendingPath: String?
    var pageLoaded = false
    var didLoadFile = false

    // MARK: 启动

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApplication.shared.setActivationPolicy(.regular)
        buildMainMenu()

        let frame = NSRect(x: 0, y: 0, width: 1100, height: 760)
        window = NSWindow(contentRect: frame,
                          styleMask: [.titled, .closable, .miniaturizable, .resizable],
                          backing: .buffered,
                          defer: false)
        window.title = "MD Reader"
        window.center()
        window.setFrameAutosaveName("MDReaderWindow")
        window.minSize = NSSize(width: 620, height: 420)

        let controller = WKUserContentController()
        controller.add(self, name: "native")

        let config = WKWebViewConfiguration()
        config.userContentController = controller

        webView = LocalizedWebView(frame: frame, configuration: config)
        webView.navigationDelegate = self
        webView.autoresizingMask = [.width, .height]
        window.contentView = webView
        window.makeKeyAndOrderFront(nil)

        if let url = Bundle.main.url(forResource: "reader", withExtension: "html") {
            webView.loadFileURL(url, allowingReadAccessTo: url.deletingLastPathComponent())
        }

        NSApplication.shared.activate(ignoringOtherApps: true)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }

    /// 从 Finder 双击 / 默认打开方式进入时，系统会调用这里
    func application(_ sender: NSApplication, openFile filename: String) -> Bool {
        pendingPath = filename
        if pageLoaded {
            let path = pendingPath
            pendingPath = nil
            if let path = path { loadPath(path) }
        }
        return true
    }

    // MARK: 菜单栏

    private func buildMainMenu() {
        let mainMenu = NSMenu()

        // 应用菜单
        let appItem = NSMenuItem()
        mainMenu.addItem(appItem)
        let appMenu = NSMenu()
        appItem.submenu = appMenu
        appMenu.addItem(withTitle: "关于 MD Reader",
                        action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "隐藏 MD Reader",
                        action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        appMenu.addItem(withTitle: "退出 MD Reader",
                        action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")

        // 文件
        let fileItem = NSMenuItem()
        mainMenu.addItem(fileItem)
        let fileMenu = NSMenu(title: "文件")
        fileItem.submenu = fileMenu
        let openItem = NSMenuItem(title: "打开…", action: #selector(openDocument(_:)), keyEquivalent: "o")
        openItem.target = self
        fileMenu.addItem(openItem)
        fileMenu.addItem(.separator())
        fileMenu.addItem(withTitle: "关闭窗口",
                         action: #selector(NSWindow.performClose(_:)), keyEquivalent: "w")

        // 编辑
        let editItem = NSMenuItem()
        mainMenu.addItem(editItem)
        let editMenu = NSMenu(title: "编辑")
        editItem.submenu = editMenu
        editMenu.addItem(withTitle: "拷贝", action: Selector(("copy:")), keyEquivalent: "c")
        editMenu.addItem(withTitle: "全选", action: Selector(("selectAll:")), keyEquivalent: "a")
        editMenu.addItem(.separator())
        let findItem = NSMenuItem(title: "查找…", action: #selector(focusSearch(_:)), keyEquivalent: "f")
        findItem.target = self
        editMenu.addItem(findItem)

        // 显示
        let viewItem = NSMenuItem()
        mainMenu.addItem(viewItem)
        let viewMenu = NSMenu(title: "显示")
        viewItem.submenu = viewMenu
        let foldItem = NSMenuItem(title: "折叠 / 展开目录", action: #selector(toggleSidebar(_:)), keyEquivalent: "l")
        foldItem.target = self
        viewMenu.addItem(foldItem)
        let themeItem = NSMenuItem(title: "切换深色 / 浅色", action: #selector(toggleTheme(_:)), keyEquivalent: "d")
        themeItem.target = self
        viewMenu.addItem(themeItem)

        NSApplication.shared.mainMenu = mainMenu
    }

    @objc private func openDocument(_ sender: Any?) { promptOpen() }
    @objc private func focusSearch(_ sender: Any?) {
        eval("var s=document.getElementById('search');if(s){s.focus();s.select();}")
    }
    @objc private func toggleSidebar(_ sender: Any?) {
        eval("var b=document.getElementById('sideBtn');if(b){b.click();}")
    }
    @objc private func toggleTheme(_ sender: Any?) {
        eval("var b=document.getElementById('themeBtn');if(b){b.click();}")
    }
    private func eval(_ js: String) { webView.evaluateJavaScript(js, completionHandler: nil) }

    // MARK: 网页加载

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        pageLoaded = true
        if let path = pendingPath {
            pendingPath = nil
            loadPath(path)
        } else {
            // 系统投递 openFile 的时机可能略晚于页面加载完成，
            // 留一段宽限期，确认真的没有文件才弹打开面板。
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) { [weak self] in
                guard let self = self else { return }
                if self.pendingPath == nil && !self.didLoadFile {
                    self.promptOpen()
                }
            }
        }
    }

    func loadPath(_ path: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else { return }
        didLoadFile = true
        let text = decode(data)
        let name = (path as NSString).lastPathComponent
        let payload: [String] = [text, name, path]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: payload),
              let json = String(data: jsonData, encoding: .utf8) else { return }

        eval("window.__mdLoad(" + json + ")")
        window.title = name
        NSDocumentController.shared.noteNewRecentDocumentURL(URL(fileURLWithPath: path))
    }

    /// 先按 UTF-8 解，失败再按 GB18030，最后兜底 Latin-1
    func decode(_ data: Data) -> String {
        if let s = String(data: data, encoding: .utf8) { return s }
        let gbk = CFStringConvertEncodingToNSStringEncoding(
            CFStringEncoding(CFStringEncodings.GB_18030_2000.rawValue))
        if gbk != kCFStringEncodingInvalidId,
           let s = String(data: data, encoding: String.Encoding(rawValue: gbk)) { return s }
        return String(data: data, encoding: .isoLatin1) ?? ""
    }

    func promptOpen() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["md", "markdown", "mdown", "mkd", "txt"]
        panel.message = "选择一个 Markdown 文件"
        panel.prompt = "打开"
        if panel.runModal() == .OK, let url = panel.url {
            loadPath(url.path)
        }
    }

    // MARK: JS -> 原生

    func userContentController(_ controller: WKUserContentController,
                               didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let type = dict["type"] as? String else { return }
        DispatchQueue.main.async {
            switch type {
            case "open":
                self.promptOpen()
            case "reveal":
                if let path = dict["path"] as? String {
                    NSWorkspace.shared.activateFileViewerSelecting([URL(fileURLWithPath: path)])
                }
            default:
                break
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
