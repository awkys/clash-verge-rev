#!/bin/bash
clear
echo "==================================================="
echo "       Clash Verge Mac 端一键解除拦截助手"
echo "==================================================="
echo ""
echo "由于 macOS 的系统安全策略，第三方未签名软件会被拦截。"
echo "此脚本将帮您一键安全地解除 macOS 对 Clash Verge 的限制。"
echo ""
echo "⚠️  注意：执行过程中系统会要求输入您的 Mac 开机密码。"
echo "（输入密码时屏幕不会显示任何字符或星号，请直接盲打密码后回车即可）"
echo ""

sudo xattr -r -d com.apple.quarantine "/Applications/Clash Verge.app"
sudo chmod -R 755 "/Applications/Clash Verge.app"
sudo codesign --force --deep --sign - "/Applications/Clash Verge.app" >/dev/null 2>&1

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ 恭喜！拦截已成功解除。"
    echo "⏳ 正在自动启动 Clash Verge..."
    open -a "/Applications/Clash Verge.app"
    echo "现在您可以前往【应用程序】双击正常打开 Clash Verge 了！"
    echo ""
else
    echo ""
    echo "❌ 解除失败..."
    echo "请检查："
    echo "1. 您是否输入了正确的电脑开机密码？"
    echo "2. 您是否已经将 Clash Verge 拖入了【应用程序】(Applications) 文件夹中？"
    echo ""
fi

read -p "按回车键关闭本窗口..."
