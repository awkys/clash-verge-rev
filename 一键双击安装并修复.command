#!/bin/bash
clear
echo "==================================================="
echo "       Clash Verge Mac 端一键安装助手"
echo "==================================================="
echo ""
echo "本脚本将自动帮您："
echo "1. 将软件拷贝到【应用程序】中完成安装"
echo "2. 解除 macOS 对于未签名应用的安全拦截(提示损坏等)"
echo ""
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

if [ ! -d "$DIR/Clash Verge.app" ]; then
    echo "❌ 错误：未在安装包内找到 Clash Verge.app。"
    echo "请不要把此脚本拖到外面运行，请直接在打开的 dmg 窗口内右键运行！"
    read -p "按回车键退出..."
    exit 1
fi

echo "⏳ 正在将软件复制到您的 Mac【应用程序】(Applications) 文件夹..."
# 删除可能已存在的旧版本然后再复制新的过去
rm -rf "/Applications/Clash Verge.app"
cp -R "$DIR/Clash Verge.app" /Applications/

echo "✅ 复制完成！"
echo ""
echo "⏳ 接下来将帮您解除 macOS 的安全拦截..."
echo "⚠️  注意：这里需要管理员权限，您需要输入 Mac 的开机密码。"
echo "👉 （重要提示：输入密码时，屏幕上什么都不会显示，连星号都不会有，请不要以为键盘坏了。您只需无视屏幕，盲打完密码后立刻按下回车键即可！！！）"
echo ""

sudo xattr -r -d com.apple.quarantine "/Applications/Clash Verge.app"
sudo chmod -R 755 "/Applications/Clash Verge.app"
sudo codesign --force --deep --sign - "/Applications/Clash Verge.app" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "🎉 恭喜！安装及安全修复已成功！"
    echo "⏳ 正在自动启动 Clash Verge..."
    open -a "/Applications/Clash Verge.app"
    echo "✅ 已尝试自动启动 Clash Verge。"
    echo "现在您也可以前往启动台(Launchpad) 或 【应用程序】 里正常双击打开并使用 Clash Verge。"
    echo "以后再也不会提示损坏或拦截了！"
else
    echo ""
    echo "❌ 警告：您可能密码输入错误，解除拦截失败。"
    echo "请关闭窗口，重新用【右键】->【打开】本脚本再试一次。"
fi
echo ""
read -p "安装顺利结束，按回车键关闭本窗口..."
