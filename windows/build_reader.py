# 生成 Windows 版 reader.html：内联 marked.js + 适配本地 HTTP 服务模式
import os
root = "/Users/Zhuanz/WorkBuddy/2026-09-20-22-58-54/MDReader"
tpl_path = os.path.join(root, "reader_template.html")
marked_path = os.path.join(root, "build", "marked_min.js")
out_path = "/Users/Zhuanz/WorkBuddy/2026-09-20-22-58-54/MDReader-win/reader.html"

tpl = open(tpl_path, encoding="utf-8").read()
marked = open(marked_path, encoding="utf-8").read()

html = tpl.replace("/*__MARKED_PLACEHOLDER__*/", marked)

# 窗口文案适配 Windows
html = html.replace('<button class="btn" id="revealBtn" disabled>在 Finder 显示</button>',
                    '<button class="btn" id="revealBtn" disabled>打开文件夹</button>')

# reveal 走本地服务端 /api/reveal
html = html.replace(
    "revealBtn.onclick=function(){ if(currentPath) post({type:'reveal',path:currentPath}); };",
    "revealBtn.onclick=function(){ if(currentPath) window.revealFile(currentPath); };")

# 顶部加“退出”按钮（关闭本地服务端）
html = html.replace(
    '    <button class="btn icon" id="themeBtn" title="切换主题">🌗</button>',
    '    <button class="btn icon" id="themeBtn" title="切换主题">🌗</button>\n'
    '    <button class="btn icon" id="exitBtn" title="退出程序">✕</button>')

# 注入桥接脚本（同时兼容“本地服务模式”与“Neutralino 内嵌模式”）
inject = '''
<script>
window.revealFile=function(p){
  if(!p) return;
  if(window.Neutralino){
    try{ var d=p.replace(/[\\\\/][^\\\\/]*$/,'') ; Neutralino.os.open(d); }catch(e){}
    return;
  }
  fetch('/api/reveal',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({path:p})}).catch(function(){});
};
window.exitApp=function(){
  if(window.Neutralino){ try{ Neutralino.app.exit(); }catch(e){} return; }
  fetch('/api/exit').catch(function(){});
};
(function(){
  var exitBtn=document.getElementById('exitBtn');
  if(exitBtn) exitBtn.onclick=function(){ if(confirm('退出 MD Reader？')) window.exitApp(); };
  if(window.Neutralino){ return; }
  if(location.search.indexOf('file=1')>=0){
    fetch('/api/content').then(function(r){return r.json();}).then(function(d){
      window.__mdLoad([d.text||'', d.name||'', d.path||'']);
    }).catch(function(e){ console.error(e); });
  }
})();
</script>
'''
html = html.replace('</body>', inject + '\n</body>')

open(out_path, "w", encoding="utf-8").write(html)
print("reader.html written:", len(html), "bytes")
