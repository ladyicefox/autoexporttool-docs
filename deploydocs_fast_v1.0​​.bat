@echo off
:: deploydocs_fast v1.0 - MkDocs超级部署插件
:: 功能：预览+提交+部署+智能清理 | 设计：ladyicefox

setlocal enabledelayedexpansion

::: 配置区 ==================================
set PROJECT_DIR=.
set IGNORE_FOLDERS="videos temp_cache"
set DEPLOY_URL=https://ladyicefox.github.io/autoexporttool-docs/
::: ========================================

:: 0. 环境初始化
title MkDocs闪电部署 v1.0
color 0A
if not exist "%PROJECT_DIR%\mkdocs.yml" (
    echo [ERROR] 请将此脚本放在工程根目录（包含mkdocs.yml）
    pause
    exit /b
)
cd /d "%PROJECT_DIR%"

:: 1. 智能清理异常文件
echo [清理] 扫描无效文件夹...
for %%d in (%IGNORE_FOLDERS%) do (
    if exist "%%~d" (
        echo   - 删除无效文件夹: %%~d
        rmdir /s /q "%%~d" 2>nul
    )
)

:: 2. 启动预览服务（带进程守护）
echo [服务] 启动MkDocs本地预览...
start "" /b mkdocs serve
timeout /t 2 >nul
tasklist | find "mkdocs" >nul || (
    echo [警告] Python模块启动失败，尝试原生命令...
    start "" /b python -m mkdocs serve
    timeout /t 2 >nul
    if errorlevel 1 (
        echo [错误] 服务启动失败！请检查：
        echo   1. 是否安装依赖：pip install mkdocs-material
        echo   2. 端口8000是否被占用
        pause
        exit /b
    )
)

:: 3. 用户确认环节
echo.
echo [提示] 浏览器已打开 → http://127.0.0.1:8000
echo [操作] 按任意键继续部署，或关闭窗口终止...
pause >nul

:: 4. 终止服务进程
taskkill /f /im "mkdocs.exe" >nul 2>&1
taskkill /f /im "python.exe" >nul 2>&1

:: 5. 智能生成提交信息
set "COMMIT_MSG=自动提交：%date:~0,10% %time:~0,8%"
for /f "delims=" %%i in ('git status -s 2^>nul ^| findstr /v "\.\.\."') do (
    set "COMMIT_MSG=更新：%%~nxi等文件"
    goto :deploy
)

:: 6. 强制部署流程
:deploy
echo [提交] 正在打包更改...
git add . 2>nul
git commit -m "%COMMIT_MSG%" 2>nul || (
    echo [注意] 无实质性更改或提交跳过
)

echo [部署] 推送至GitHub Pages...
mkdocs gh-deploy --force 2>nul || (
    python -m mkdocs gh-deploy --force
)

:: 7. 完成报告
echo.
echo [成功] 部署完成！访问：%DEPLOY_URL%
echo [时间] 本次耗时：%time:~0,8%
pause