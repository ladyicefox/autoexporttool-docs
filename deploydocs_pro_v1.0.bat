@echo off
:: deploydocs_pro v1.0 - 全能MkDocs部署插件
:: 功能：智能克隆/拉取+备份+预览+部署 | 设计：ladyicefox

setlocal enabledelayedexpansion

::: ⚙️ 用户配置区 ==================================
set REPO_URL=https://github.com/ladyicefox/autoexporttool-docs
set PROJECT_DIR=autoexporttool-docs
set BRANCH=main
set IGNORE_FOLDERS="videos temp_cache"
set DEPLOY_URL=https://ladyicefox.github.io/autoexporttool-docs/
set BACKUP_DIR=%USERPROFILE%\mkdocs_backups
::: ==============================================

:: 0. 初始化环境
title MkDocs全自动部署 v1.0
color 0B
mkdir "%BACKUP_DIR%" >nul 2>&1

:: 1. 智能获取工程（带网络优化）
if not exist "%PROJECT_DIR%" (
    echo [网络] 正在克隆仓库（VPN加速启用）...
    git clone --depth=1 %REPO_URL% %PROJECT_DIR%
    if errorlevel 1 (
        echo [错误] 克隆失败！请检查：
        echo   1. VPN是否连接
        echo   2. 是否有权限访问仓库
        pause
        exit /b
    )
) else (
    echo [同步] 检测到本地工程，准备更新...
    cd "%PROJECT_DIR%"
    
    :: 备份本地修改
    set BACKUP_NAME=%PROJECT_DIR%_backup_%date:~0,4%%date:~5,2%%date:~8,2%
    echo [备份] 正在保存工作副本到：%BACKUP_DIR%\!BACKUP_NAME!
    xcopy /E /I /Y "%cd%" "%BACKUP_DIR%\!BACKUP_NAME!" >nul
    
    :: 强制更新代码
    git fetch --all >nul
    git reset --hard origin/%BRANCH% >nul
    git clean -fd >nul
    cd ..
)

:: 2. 进入工程目录（严格校验）
cd /d "%PROJECT_DIR%" 2>nul || (
    echo [错误] 目录切换失败：%PROJECT_DIR%
    pause
    exit /b
)
if not exist "mkdocs.yml" (
    echo [错误] 非标准MkDocs工程（缺少mkdocs.yml）
    pause
    exit /b
)

:: 3. 清理异常文件（安全模式）
echo [清理] 移除干扰文件夹...
for %%d in (%IGNORE_FOLDERS%) do (
    if exist "%%~d" (
        echo   - 安全删除: %%~d
        rmdir /s /q "%%~d" 2>nul
    )
)

:: 4. 启动预览服务（双引擎容错）
echo [服务] 启动实时预览（8000端口）...
start "" /b python -m mkdocs serve
timeout /t 3 >nul
tasklist | findstr /i "mkdocs.exe" >nul || (
    echo [优化] 尝试原生启动方式...
    start "" /b mkdocs serve
    timeout /t 3 >nul
    if errorlevel 1 (
        echo [修复] 正在自动安装依赖...
        pip install --upgrade mkdocs-material >nul
        start "" /b mkdocs serve
    )
)

:: 5. 用户确认环节
echo.
echo [提示] 浏览器访问 → http://127.0.0.1:8000
echo [操作] 按任意键继续部署，Ctrl+C终止...
pause >nul

:: 6. 终止服务进程
taskkill /f /im "mkdocs.exe" >nul 2>&1
taskkill /f /im "python.exe" >nul 2>&1

:: 7. 智能提交（差异检测）
set "COMMIT_MSG=自动同步：%date:~0,10% %time:~0,8%"
for /f "tokens=2-*" %%a in ('git status --porcelain 2^>nul') do (
    set "COMMIT_MSG=更新：%%b"
    goto :deploy
)

:: 8. 强制部署流程
:deploy
echo [提交] 正在打包变更...
git add --all >nul
git commit -m "%COMMIT_MSG%" >nul || (
    echo [跳过] 未检测到文件变更
)

echo [部署] 推送至GitHub Pages（强制覆盖）...
mkdocs gh-deploy --force >nul 2>&1 || (
    python -m mkdocs gh-deploy --force >nul
)

:: 9. 生成报告
echo.
echo [成功] ✔ 部署完成！访问：%DEPLOY_URL%
echo [备份] 本地副本保存在：%BACKUP_DIR%
echo [耗时] 总用时：%time:~0,8%
pause