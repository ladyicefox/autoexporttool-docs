@echo off
:: 强制UTF-8编码
chcp 65001 >nul
set PYTHON_SCRIPTS=C:\Users\user\AppData\Local\Programs\Python\Python311\Scripts

:: 修复中文乱码
reg add "HKCU\Console" /v "CodePage" /t REG_DWORD /d 65001 /f
reg add "HKCU\Console" /v "FaceName" /t REG_SZ /d "Lucida Console" /f

:: 添加Python到PATH
setx PATH "%PATH%;%PYTHON_SCRIPTS%" /m

:: 安装MkDocs
python -m pip install --upgrade mkdocs

:: 启动优化后的部署流程
start "" /b python -m mkdocs serve
timeout 3
start http://127.0.0.1:8000
pause
python -m mkdocs gh-deploy --force
pause