@echo off
:: ==============================================
:: MkDocs Pro 智能部署工具 v1.0
:: 核心功能：
:: 1. 智能差异检测与备份系统
:: 2. 自适应工程目录处理
:: 3. 安全同步机制（防止重复拉取）
:: 4. 工程配置快捷接口
:: 5. 增强型状态报告
:: 6. 智能网页预览控制 / 用户自行选择是否打开网页
:: ==============================================

:: 初始化环境
setlocal enabledelayedexpansion
chcp 65001 >nul
title MkDocs智能部署 v1.0
color 0B

:: 配置区（自动读取或默认）
if "%~1"=="/config" (
    call :create_config
    exit /b
)

set "CONFIG_FILE=%~dp0mkdocs_deploy.cfg"
if exist "%CONFIG_FILE%" (
    for /f "tokens=1,2 delims==" %%a in (%CONFIG_FILE%) do (
        if "%%a"=="PROJECT_NAME" set "PROJECT_NAME=%%b"
        if "%%a"=="REPO_URL" set "REPO_URL=%%b"
        if "%%a"=="BRANCH" set "BRANCH=%%b"
    )
) else (
    set "PROJECT_NAME=autoexporttool-docs"
    set "REPO_URL=https://github.com/ladyicefox/autoexporttool-docs"
    set "BRANCH=main"
)

:: 1. 智能工程检测（四级策略）
:find_project
set "PROJECT_DIR="
set "NEED_CLONE=1"

:: 策略1：检查当前目录
if exist "%cd%\%PROJECT_NAME%\mkdocs.yml" (
    set "PROJECT_DIR=%cd%\%PROJECT_NAME%"
    set "NEED_CLONE=0"
) else if exist "%cd%\mkdocs.yml" (
    set "PROJECT_DIR=%cd%"
    set "NEED_CLONE=0"
)

:: 策略2：检查用户目录
if not defined PROJECT_DIR (
    if exist "%USERPROFILE%\%PROJECT_NAME%\mkdocs.yml" (
        set "PROJECT_DIR=%USERPROFILE%\%PROJECT_NAME%"
        set "NEED_CLONE=0"
    )
)

:: 策略3：全局搜索
if not defined PROJECT_DIR (
    for /f "delims=" %%d in ('dir /s /b /ad "%PROJECT_NAME%" 2^>nul ^| findstr /i ".*%PROJECT_NAME%"') do (
        if exist "%%d\mkdocs.yml" (
            set "PROJECT_DIR=%%d"
            set "NEED_CLONE=0"
            goto :project_found
        )
    )
)

:: 策略4：新建或克隆工程
:project_found
if not defined PROJECT_DIR (
    echo [工程] 未检测到现有项目
    set "PROJECT_DIR=%cd%\%PROJECT_NAME%"
    mkdir "%PROJECT_DIR%" 2>nul
)

:: 2. 进入工程目录
cd /d "%PROJECT_DIR%"
echo [工程] 使用路径: %PROJECT_DIR%

:: 3. 初始化Git仓库（如需）
if %NEED_CLONE% equ 1 (
    echo [Git] 正在克隆仓库...
    git clone %REPO_URL% "%PROJECT_DIR%" >nul 2>&1 || (
        echo [错误] 克隆失败，初始化新仓库
        git init >nul
    )
) else (
    echo [Git] 使用现有仓库
    git remote add origin %REPO_URL% 2>nul
    git fetch origin %BRANCH% >nul 2>&1
)

:: 4. 创建备份系统
set "BACKUP_ROOT=%cd%\..\mkdocs_backups"
if not exist "%BACKUP_ROOT%" mkdir "%BACKUP_ROOT%"
set "TIMESTAMP=%date:~0,4%%date:~5,2%%date:~8,2%"
set "BACKUP_DIR=%BACKUP_ROOT%\%PROJECT_NAME%_backup_%TIMESTAMP%"
mkdir "%BACKUP_DIR%" >nul 2>&1

:: 5. 智能差异检测系统
echo [检测] 正在分析变更...
set "CHANGE_FOUND=0"
set "NEW_FILES=0"

:: 生成变更列表
git fetch origin %BRANCH% >nul 2>&1
git diff --name-only --diff-filter=AM origin/%BRANCH% 2>nul > changes.tmp
git ls-files --others --exclude-standard >> changes.tmp

:: 处理变更文件
for /f "delims=" %%f in ('type changes.tmp ^| findstr /v "\.git\\"') do (
    if exist "%%f" (
        set "CHANGE_FOUND=1"
        
        :: 备份差异文件
        set "filepath=%%~pf"
        set "filename=%%~nxf"
        set "backuppath=%BACKUP_DIR%!filepath:%PROJECT_DIR%=!"
        if not exist "!backuppath!" mkdir "!backuppath!"
        copy "%%f" "!backuppath!!filename!" >nul
        
        :: 分类显示
        if "%%f"=="mkdocs.yml" (
            echo   ! 重要配置变更: %%f
        ) else if exist "%%f" (
            if "%%~xf"==".md" (
                echo   - 文档更新: %%f
            ) else (
                echo   + 资源新增: %%f
                set "NEW_FILES=1"
            )
        )
    )
)
del changes.tmp >nul

:: 6. 预览服务控制台（新增智能检测）
echo [服务] 检测MkDocs服务状态...
tasklist /fi "imagename eq python.exe" /fo csv 2>nul | findstr /i "mkdocs" >nul
if %errorlevel% equ 0 (
    echo [信息] 检测到已有MkDocs服务正在运行
    choice /c YN /n /m "是否打开本地预览页面(Y/N)? "
    if errorlevel 2 (
        echo 已跳过打开预览页面
    ) else (
        start "" "http://127.0.0.1:8000"
    )
) else (
    echo [服务] 启动MkDocs预览...
    start "" /b python -m mkdocs serve
    timeout /t 2 >nul
    echo [预览] 访问 http://127.0.0.1:8000
    choice /c YN /n /m "是否立即打开预览页面(Y/N)? "
    if errorlevel 2 (
        echo 已跳过打开预览页面
    ) else (
        start "" "http://127.0.0.1:8000"
    )
)
echo.

:: 7. 用户确认流程
if %CHANGE_FOUND% equ 1 (
    echo [差异] 发现变更文件已备份到:
    echo        %BACKUP_DIR%
    echo.
) else (
    echo [信息] 未检测到有效变更
    echo.
)

choice /c YNC /n /m "请选择操作 (Y=部署/N=取消/C=强制全量): "
if errorlevel 3 (
    explorer "%BACKUP_DIR%"
    exit /b
)
if errorlevel 2 (
    taskkill /f /im "python.exe" >nul 2>&1
    exit /b
)

:: 8. 智能提交系统
if %CHANGE_FOUND% equ 1 (
    echo [Git] 正在提交变更...
    git add --update >nul
    if %NEW_FILES% equ 1 git add --all >nul
    git commit -m "自动更新: %date% %time%" >nul || (
        echo [信息] 提交无实质性变更
    )
)

:: 9. 安全推送机制
echo [同步] 正在推送至GitHub...
git push origin %BRANCH% >nul && (
    echo [部署] 正在更新GitHub Pages...
    python -m mkdocs gh-deploy --force >nul
)

:: 10. 完成报告（核心/用户可自行选择是否打开最终网址，选择Y则自动跳转到最终部署完成的站点）
echo.
echo ===== 部署报告 =====
echo [工程] %PROJECT_NAME%
echo [路径] %PROJECT_DIR%
echo [分支] %BRANCH% 已同步
if %CHANGE_FOUND% equ 1 (
    echo [备份] 共备份 !CHANGE_FOUND! 个文件
    echo        %BACKUP_DIR%
)

:: 修正GitHub Pages网址生成逻辑（关键修改）
for /f "tokens=2 delims=/" %%a in ("%REPO_URL%") do set "GH_ACCOUNT=%%a"
for /f "tokens=3 delims=/" %%a in ("%REPO_URL%") do set "GH_REPO=%%a"
set "FINAL_URL=https://%GH_ACCOUNT%.github.io/%GH_REPO%/"

echo [页面] %FINAL_URL%
echo ===================
echo.

:: 选择性打开最终文档网址（非GitHub Pages首页）
choice /c YN /n /m "是否立即打开文档页面 %FINAL_URL% (Y/N)? "
if errorlevel 2 (
    echo 已跳过打开页面
) else (
    echo [操作] 正在打开文档页面...
    start "" "%FINAL_URL%"
)

:: 快捷接口提示
echo 提示: 使用 /config 参数创建新配置
echo      例如: %~nx0 /config
echo.

:: 安全退出
taskkill /f /im "python.exe" >nul 2>&1
pause
exit /b

:: ==============================================
:: 功能子程序
:: ==============================================

:create_config
echo 正在创建新配置...
set /p "NEW_PROJECT=请输入新工程名称: "
set /p "NEW_REPO=请输入Git仓库URL: "
set /p "NEW_BRANCH=请输入分支名称(default=main): "

if "!NEW_BRANCH!"=="" set "NEW_BRANCH=main"

(
    echo PROJECT_NAME=!NEW_PROJECT!
    echo REPO_URL=!NEW_REPO!
    echo BRANCH=!NEW_BRANCH!
) > "%~dp0!NEW_PROJECT!_deploy.cfg"

echo 已创建配置文件: %~dp0!NEW_PROJECT!_deploy.cfg
echo 请将脚本复制为新文件并修改配置引用
pause
exit /b