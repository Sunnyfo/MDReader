#!/bin/bash
# MDReader 可复现构建脚本：生成 reader.html → 编译通用二进制(arm64+x86_64) → 打包签名 → 安装 + 产出 DMG
set -e

ROOT="/Users/Zhuanz/WorkBuddy/2026-09-20-22-58-54/MDReader"
BUILD="$ROOT/build"
TEMPLATE="$ROOT/reader_template.html"
MARKED="$ROOT/build/marked_min.js"
SRC_ICON="$ROOT/icon/MDReader.icns"
SRC_STRINGS="$ROOT/Resources/zh-Hans.lproj/InfoPlist.strings"
PLIST="$ROOT/Info.plist"
MAIN="$ROOT/main.swift"

APP="$BUILD/MDReader.app"
DMG="$ROOT/MDReader.dmg"
STAGE="$BUILD/dmg_stage"

echo "==> [1/6] 生成 reader.html（内联 marked.js）"
/usr/bin/python3 - "$TEMPLATE" "$MARKED" "$BUILD/reader.html" <<'PY'
import sys
tpl = open(sys.argv[1]).read()
mk  = open(sys.argv[2]).read()
out = tpl.replace("/*__MARKED_PLACEHOLDER__*/", mk)
open(sys.argv[3], "w").write(out)
print("reader.html bytes:", len(out))
PY

echo "==> [2/6] 分架构编译 + lipo 合并通用二进制"
swiftc -O -target arm64-apple-macosx13.0 -framework Cocoa -framework WebKit "$MAIN" -o "$BUILD/MDReader_arm64"
swiftc -O -target x86_64-apple-macosx13.0 -framework Cocoa -framework WebKit "$MAIN" -o "$BUILD/MDReader_x86"
lipo -create -output "$BUILD/MDReader" "$BUILD/MDReader_arm64" "$BUILD/MDReader_x86"
lipo -info "$BUILD/MDReader"

echo "==> [3/6] 组装 .app 包"
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources/zh-Hans.lproj"
cp "$BUILD/MDReader"            "$APP/Contents/MacOS/MDReader"
cp "$BUILD/reader.html"         "$APP/Contents/Resources/reader.html"
cp "$PLIST"                     "$APP/Contents/Info.plist"
if [ -f "$SRC_ICON" ]; then
  cp "$SRC_ICON"                "$APP/Contents/Resources/MDReader.icns"
else
  echo "提示：未找到 $SRC_ICON，将使用系统默认图标（不影响功能）。"
fi
cp "$SRC_STRINGS"               "$APP/Contents/Resources/zh-Hans.lproj/InfoPlist.strings"

echo "==> [4/6] 临时自签名（无证书）"
codesign --force --deep --sign - "$APP"
codesign -dvv "$APP" 2>&1 | grep -E "Signature|Version|Platform" || true

echo "==> [5/6] 安装到 /Applications/MDReader.app"
rm -rf /Applications/MDReader.app
cp -R "$APP" /Applications/MDReader.app
codesign --force --deep --sign - /Applications/MDReader.app

echo "==> [6/6] 产出 DMG 安装包"
rm -rf "$STAGE"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/MD Reader.app"
ln -s /Applications "$STAGE/Applications"
rm -f "$DMG"
hdiutil create -volname "MD Reader" -srcfolder "$STAGE" -ov -format UDZO "$DMG"
echo "DMG: $DMG"
ls -lh "$DMG"
