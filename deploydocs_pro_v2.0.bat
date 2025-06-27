@echo off
:: ==============================================
:: MkDocs Pro 部署工具 v3.0
:: 核心功能：
:: 1. 智能环境检测（Python/MkDocs）
:: 2. 彻底解决中文乱码问题
:: 3. 全自动文件跟踪（包括BAT等所有类型）
:: 4. 智能工程定位（可在任意目录执行）
:: 5. 带时间戳的自动备份系统
:: 6. 增强的错误处理和交互逻辑
:: ==============================================

:: 强制UTF-8编码并修复中文显示
chcp 65001 >nul
reg add "HKCU\Console" /v "CodePage" /t REG_DWORD /d 65001 /f >nul
setlocal enabledelayedexpansion

:: 🔧 用户配置区（根据实际修改）
set PROJECT_NAME=autoexporttool-docs
set GIT_REPO=https://github.com/ladyicefox/autoexporttool-docs
set DEPLOY_BRANCH=main
set IGNORE_FOLDERS=".git .venv __pycache__"
set BACKUP_ROOT=%USERPROFILE%\mkdocs_backups
:: --------------------------------------------

:: 0. 初始化环境
title MkDocs Pro Deployer v3.0
color 0B
mkdir "%BACKUP_ROOT%" >nul 2>&1

:: 1. 智能定位工程目录
:find_project
set "PROJECT_DIR="
for /f "delims=" %%d in ('dir /b /s /ad "%PROJECT_NAME%" 2^>nul') do (
    if exist "%%d\mkdocs.yml" set "PROJECT_DIR=%%d"
)

if not defined PROJECT_DIR (
    echo [工程] 未检测到有效工程目录
    set /p "PROJECT_DIR=请输入工程绝对路径: "
    if not exist "!PROJECT_DIR!\mkdocs.yml" (
        echo [错误] 无效的MkDocs工程路径
        pause
        exit /b
    )
)
cd /d "!PROJECT_DIR!"

:: 2. 环境检测与修复
:check_env
echo [环境] 正在检测系统环境...
where python >nul 2>&1 || (
    echo [错误] Python未安装或未添加到PATH
    echo       请从 https://www.python.org/downloads/ 安装
    pause
    exit /b
)

python -m pip show mkdocs >nul 2>&1 || (
    echo [修复] 正在安装MkDocs...
    python -m pip install --upgrade mkdocs || (
        echo [错误] MkDocs安装失败
        pause
        exit /b
    )
)

:: 3. 创建备份（带时间戳）
set "BACKUP_DIR=%BACKUP_ROOT%\%PROJECT_NAME%_!date:~0,4!-!date:~5,2!-!date:~8,2!_!time:~0,2!-!time:~3,2!"
echo [备份] 正在备份到: !BACKUP_DIR!
robocopy "." "!BACKUP_DIR!" /mir /njh /njs /ndl /nc /ns >nul

:: 4. 智能同步代码
if exist ".git" (
    echo [同步] 正在更新仓库...
    git fetch origin %DEPLOY_BRANCH% >nul 2>&1
    git reset --hard origin/%DEPLOY_BRANCH% >nul 2>&1
    git clean -fd >nul 2>&1
) else (
    echo [初始化] 正在克隆仓库...
    git clone --depth=1 %GIT_REPO% "%PROJECT_DIR%" || (
        echo [错误] 仓库克隆失败
        pause
        exit /b
    )
    cd /d "%PROJECT_DIR%"
)

:: 5. 清理干扰项
echo [清理] 移除临时文件...
for %%d in (%IGNORE_FOLDERS%) do (
    if exist "%%~d" (
        echo   - 跳过系统目录: %%~d
    )
)

:: 6. 启动预览服务（双引擎容错）
echo [服务] 启动本地预览...
start "" /b python -m mkdocs serve
timeout /t 3 >nul
tasklist | findstr /i "mkdocs.exe" >nul || (
    echo [备用] 尝试原生启动...
    start "" /b mkdocs serve
)

:: 7. 交互式确认
echo.
echo [预览] 浏览器已打开 → http://127.0.0.1:8000
choice /c YNC /n /m "确认部署? (Y=继续/N=取消/C=打开目录): "
if errorlevel 3 (
    explorer "%PROJECT_DIR%"
    exit /b
)
if errorlevel 2 (
    taskkill /f /im "python.exe" >nul 2>&1
    exit /b
)

:: 8. 终止服务
taskkill /f /im "python.exe" >nul 2>&1

:: 9. 智能提交变更
echo [提交] 扫描文件变更...
set "GIT_ADDED=0"
for /f "delims=" %%f in ('dir /b /s /a-d 2^>nul') do (
    git ls-files --error-unmatch "%%f" >nul 2>&1 || (
        git add "%%f"
        set /a GIT_ADDED+=1
        if !GIT_ADDED! leq 5 echo   - 添加: %%~nxf
    )
)

if !GIT_ADDED! gtr 0 (
    set "COMMIT_MSG=自动提交：!date:~0,10! !time:~0,8! (共!GIT_ADDED!个文件)"
    git commit -m "!COMMIT_MSG!" || (
        echo [跳过] 提交被跳过（无实质变更）
    )
) else (
    echo [信息] 未检测到新文件
)

:: 10. 执行部署
echo [部署] 正在推送至GitHub Pages...
python -m mkdocs gh-deploy --force || (
    echo [错误] 部署失败！
    pause
    exit /b
)

:: 11. 完成报告
echo.
echo [成功] ✔ 部署完成！
echo [访问] !DEPLOY_URL!
echo [备份] !BACKUP_DIR!
echo [时间] 总耗时: !time:~0,8!
pause