set app_path to POSIX path of (path to me)
set dmg_root to do shell script "dirname " & quoted form of app_path
set source_app to dmg_root & "/Clash Verge.app"
set dest_dir to "/Applications/"
set target_app to dest_dir & "Clash Verge.app"

try
    do shell script "rm -rf " & quoted form of target_app & " && cp -R " & quoted form of source_app & " " & quoted form of dest_dir & " && xattr -r -d com.apple.quarantine " & quoted form of target_app with administrator privileges
    display dialog "安装并修复成功！\n请前往「启动台」或「应用程序」双击打开 Clash Verge。" buttons {"完成"} default button "完成" with icon note
on error errStr number errorNumber
    display dialog "安装失败，已取消操作或密码错误：\n" & errStr buttons {"确定"} default button "确定" with icon stop
end try
