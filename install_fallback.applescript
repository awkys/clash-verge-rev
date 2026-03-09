try
    set source_app to do shell script "find /Volumes -maxdepth 2 -name 'Clash Verge.app' -type d | head -n 1"
    if source_app is "" then
        error "无法自动定位到 Clash Verge 安装文件。"
    end if
    
    set dest_dir to "/Applications/"
    set target_app to dest_dir & "Clash Verge.app"
    
    do shell script "rm -rf " & quoted form of target_app & " && cp -R " & quoted form of source_app & " " & quoted form of dest_dir & " && xattr -r -d com.apple.quarantine " & quoted form of target_app with administrator privileges
    
    display dialog "🎉 安装并安全修复成功！\n\n大功告成！现在您可以直接关掉这个窗口，前往电脑底部的「启动台(Launchpad)」或「应用程序」中，找到粉色的 Clash Verge 正常双击使用了！（不会再有任何拦截警告）" buttons {"太棒了，完成！"} default button 1 with icon note
on error errStr number errorNumber
    display dialog "⚠️ 自动安装失败（可能是取消了密码或系统拦截）。\n\n原因：" & errStr & "\n\n【必须手动操作】：\n请关闭此提示，打开旁边的《解决“文件已损坏”必看教程.txt》，只需按照里面的 4 步极其简单的操作，即可 100% 成功运行！" buttons {"我知道了，去看教程"} default button 1 with icon stop
end try
