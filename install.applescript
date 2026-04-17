set appPath to POSIX path of («event earsffdr» me)
set dmgRoot to «event sysoexec» ("dirname " & quoted form of appPath)
set sourceApp to dmgRoot & "/Clash Verge.app"
set destDir to "/Applications/"
set targetApp to destDir & "Clash Verge.app"

«event sysodlog» "即将开始安装并修复 Clash Verge。\n下一步会弹出系统授权窗口，请输入 Mac 登录密码（或 Touch ID）继续。"

try
	«event sysoexec» ("rm -rf " & quoted form of targetApp & " && cp -R " & quoted form of sourceApp & " " & quoted form of destDir & " && xattr -rd com.apple.quarantine " & quoted form of targetApp & " && chmod -R 755 " & quoted form of targetApp & " && codesign --force --deep --sign - " & quoted form of targetApp) with «class badm»
	«event sysoexec» ("open -a " & quoted form of targetApp)
	«event sysodlog» "安装并修复完成。\nClash Verge 已尝试自动启动。\n如果未弹出，请到【应用程序】里双击 Clash Verge。"
on error errStr number errNum
	«event sysodlog» ("安装失败（错误码 " & errNum & "）：\n" & errStr & "\n\n你可以改用同目录的 .command 脚本继续修复。")
end try
