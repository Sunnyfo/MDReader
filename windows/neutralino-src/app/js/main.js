// MD Reader — Neutralino 桥接层
// 负责：双击 .md 时从命令行参数读取文件、打开文件对话框、退出、关联等
(function () {
  "use strict";

  async function loadPath(p) {
    try {
      var text = await Neutralino.filesystem.readFile(p);
      var name = p.split(/[\\/]/).pop();
      if (window.__mdLoad) window.__mdLoad([text, name, p]);
    } catch (e) {
      try { alert("读取失败：" + (e && e.message ? e.message : e)); } catch (_) {}
    }
  }

  async function openDialog() {
    try {
      var res = await Neutralino.os.showOpenDialog({
        title: "打开 Markdown 文件",
        filters: [{ name: "Markdown", extensions: ["md", "markdown", "mdown", "mkd", "txt"] }]
      });
      if (res && res.length) await loadPath(res[0]);
    } catch (e) { /* 忽略取消 */ }
  }
  window.__neutralinoOpen = openDialog;

  // 覆盖阅读器的“打开”按钮，改用 Neutralino 原生日志对话框（可获得完整路径用于“打开文件夹”）
  function bindOpen() {
    var ob = document.getElementById("openBtn");
    if (ob) ob.onclick = function () { openDialog(); };
  }

  Neutralino.events.on("ready", async function () {
    bindOpen();
    try {
      var args = await Neutralino.os.getArgs();
      for (var i = 1; i < args.length; i++) {
        var a = String(args[i]).toLowerCase();
        if (/\.(md|markdown|mdown|mkd|txt)$/.test(a)) { await loadPath(args[i]); break; }
      }
    } catch (e) { /* ignore */ }
  });

  Neutralino.init();
})();
