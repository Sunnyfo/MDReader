import CoreServices
import Foundation

// 把 MD Reader 设为 Markdown 文件的默认打开方式（双击 .md 直接用它打开）
let uti = "net.daringfireball.markdown" as CFString
let bid = "com.local.mdreader" as CFString

let rAll    = LSSetDefaultRoleHandlerForContentType(uti, .all, bid)
let rViewer = LSSetDefaultRoleHandlerForContentType(uti, .viewer, bid)

print("set .all    -> OSStatus \(rAll)")
print("set .viewer -> OSStatus \(rViewer)")

if let cur = LSCopyDefaultRoleHandlerForContentType(uti, .viewer)?.takeRetainedValue() {
    print("current default handler: \(cur)")
}
