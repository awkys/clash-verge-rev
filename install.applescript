try
    set source_app to do shell script "find /Volumes -maxdepth 2 -name 'Clash Verge.app' -type d | head -n 1"
    if source_app is "" then
        display dialog "安装失败：无法自动定位到 Clash Verge 安装文件。\n\n请确保您正直接在刚才下载的 DMG 安装盘窗口中运行此程序，不要复制到桌面运行！" buttons {"确定"} default button "确定" with icon stop
        return
    end if
    
    set dest_dir to "/Applications/"
    set target_app to dest_dir & "Clash Verge.app"
    
    do shell script "rm -rf " & quoted form of target_app & " && cp -R " & quoted form of source_app & " " & quoted form of dest_dir & " && xattr -r -d com.apple.quarantine " & quoted form of target_app with administrator privileges
    
    display dialog "安装并修复成功！\n请前往电脑的「启动台」或「应用程序」中正常双击打开 Clash Verge。" buttons {"完成"} default button "完成" with icon note
on error errStr number errorNumber
    display dialog "安装被取消，或密码输入错误：\n" & errStr buttons {"确定"} default button "确定" with icon stop
end try
