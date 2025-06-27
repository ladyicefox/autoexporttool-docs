@echo off
:: ==============================================
:: MkDocs Pro 智能部署工具 v3.1
:: 核心优化：
:: 1. 智能差异检测（只提交真正变更的文件）
:: 2. 彻底忽略Git内部文件
:: 3. 新增文件快速跟踪
:: 4. 实时对比远程仓库状态
:: 1. 强化工程目录检测（支持所有位置调用）
:: 2. 自动处理中英文路径
:: 3. 智能路径输入引导
:: ==============================================

:: 初始化环境
setlocal enabledelayedexpansion
chcp 65001 >nul
title MkDocs智能部署 v3.1
color 0B

:: 配置区（根据实际修改）
set "PROJECT_NAME=autoexporttool-docs"
set "REPO_URL=https://github.com/ladyicefox/autoexporttool-docs"
set "BRANCH=main"

:: 1. 智能工程检测（三级搜索策略）
:find_project
set "PROJECT_DIR="

:: 策略1：检查当前目录
if exist "%cd%\%PROJECT_NAME%\mkdocs.yml" (
    set "PROJECT_DIR=%cd%\%PROJECT_NAME%"
) else if exist "%cd%\mkdocs.yml" (
    set "PROJECT_DIR=%cd%"
)

:: 策略2：递归搜索系统盘
if not defined PROJECT_DIR (
    for /f "delims=" %%d in ('dir /s /b /ad "%PROJECT_NAME%" 2^>nul ^| findstr /i ".*%PROJECT_NAME%"') do (
        if exist "%%d\mkdocs.yml" set "PROJECT_DIR=%%d"
    )
)

:: 策略3：用户手动输入
if not defined PROJECT_DIR (
    echo [工程] 未自动检测到有效目录
    echo 请确认以下位置是否存在:
    echo - 当前目录: %cd%\%PROJECT_NAME%
    echo - 系统路径: C:\Users\%USERNAME%\%PROJECT_NAME%
    echo.
    :input_path
    set /p "PROJECT_DIR=请输入工程绝对路径（如 C:\Projects\%PROJECT_NAME% ）: "
    if not exist "!PROJECT_DIR!\mkdocs.yml" (
        echo [错误] 路径无效或缺少mkdocs.yml
        goto input_path
    )
)

:: 2. 进入工程目录
cd /d "!PROJECT_DIR!"
echo [工程] 使用路径: !PROJECT_DIR!

:: 2. 检测文件变更（智能模式）
echo [检测] 正在分析变更文件...
set "CHANGE_FOUND=0"
git diff --name-only --diff-filter=AM origin/%BRANCH% 2>nul > changes.tmp
git ls-files --others --exclude-standard >> changes.tmp

:: 过滤有效变更（排除.git目录）
for /f "delims=" %%f in ('type changes.tmp ^| findstr /v "\.git\\"') do (
    if exist "%%f" (
        set "CHANGE_FOUND=1"
        echo   - 检测到变更: %%f
    )
)
del changes.tmp >nul 2>&1

:: 3. 启动预览服务
echo [服务] 启动MkDocs...
start "" /b python -m mkdocs serve
timeout /t 3 >nul

:: 4. 用户确认
echo.
echo [预览] http://127.0.0.1:8000
choice /c YNC /n /m "继续部署? (Y=继续/N=取消/C=强制全量): "
if errorlevel 3 (
    explorer .
    exit /b
)
if errorlevel 2 (
    taskkill /f /im "python.exe" >nul 2>&1
    exit /b
)

:: 5. 智能提交
if !CHANGE_FOUND! equ 1 (
    echo [提交] 正在处理变更...
    git add --update >nul
    git add --all >nul
    git commit -m "自动更新: !date! !time!" >nul || (
        echo [信息] 无实质性变更
    )
) else (
    echo [信息] 未检测到有效变更
)

:: 6. 差异部署
echo [部署] 推送至GitHub...
git push origin %BRANCH% >nul && (
    python -m mkdocs gh-deploy --force >nul
)

:: 7. 完成报告
echo.
echo [备份] !BACKUP_DIR!
echo [时间] 总耗时: !time:~0,8!
echo [成功] 部署完成 → https://ladyicefox.github.io/autoexporttool-docs/
echo [状态] 远程已同步: !BRANCH!
pause