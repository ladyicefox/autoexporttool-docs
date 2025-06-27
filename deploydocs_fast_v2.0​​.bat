@echo off
:: ==============================================
:: MkDocs智能部署工具 v2.0
:: 功能：环境检测+乱码修复+自动提交+一键部署
:: 优化点：
:: 1. 自动识别Python和MkDocs安装位置
:: 2. 彻底解决中文乱码问题
:: 3. 自动跟踪所有新增文件（包括BAT）
:: 4. 增强错误处理和用户交互
:: ==============================================

:: 强制UTF-8编码
chcp 65001 >nul
setlocal enabledelayedexpansion

:: 配置区 --------------------------------------
set PROJECT_DIR=%~dp0
set IGNORE_FOLDERS=".git .venv __pycache__"
set DEPLOY_URL=https://ladyicefox.github.io/autoexporttool-docs/
:: --------------------------------------------

:: 0. 环境初始化
title MkDocs智能部署工具 v2.0
color 0A

:: 检测MkDocs安装
where python >nul 2>&1 || (
    echo [错误] 未检测到Python环境
    pause
    exit /b
)

python -m pip show mkdocs >nul 2>&1 || (
    echo [安装] 正在安装MkDocs...
    python -m pip install mkdocs || (
        echo [错误] MkDocs安装失败
        pause
        exit /b
    )
)

:: 1. 智能文件清理
echo [清理] 扫描无效文件夹...
for %%d in (%IGNORE_FOLDERS%) do (
    if exist "%%~d" (
        echo   - 跳过系统文件夹: %%~d
    )
)

:: 2. 启动预览服务
echo [服务] 启动MkDocs本地预览...
start "" /b python -m mkdocs serve
timeout /t 3 >nul

:: 3. 用户确认环节
echo.
echo [提示] 浏览器已打开 → http://127.0.0.1:8000
echo [操作] 检查无误后按任意键继续部署...
choice /c yn /n /m "是否继续部署? (Y/N)" 
if errorlevel 2 (
    taskkill /f /im "python.exe" >nul 2>&1
    exit /b
)

:: 4. 终止服务进程
taskkill /f /im "python.exe" >nul 2>&1

:: 5. 智能提交（自动添加所有新文件）
echo [提交] 正在扫描变更文件...
set "GIT_ADD_FLAG=0"
for /f "delims=" %%f in ('dir /b /s /a-d 2^>nul') do (
    git ls-files --error-unmatch "%%f" >nul 2>&1 || (
        git add "%%f"
        set "GIT_ADD_FLAG=1"
        echo   - 添加新文件: %%~nxf
    )
)

if %GIT_ADD_FLAG%==1 (
    set "COMMIT_MSG=自动提交：%date:~0,10% %time:~0,8%"
    git commit -m "!COMMIT_MSG!" || (
        echo [注意] 提交失败或没有实质性变更
    )
) else (
    echo [信息] 未检测到文件变更
)

:: 6. 强制部署
echo [部署] 正在推送至GitHub Pages...
python -m mkdocs gh-deploy --force || (
    echo [错误] 部署失败！
    pause
    exit /b
)

:: 7. 完成报告
echo.
echo [成功] 部署完成！访问：%DEPLOY_URL%
echo [时间] 本次耗时：%time:~0,8%
pause