@echo off
chcp 65001 >nul
setlocal
cd /d "%~dp0"

set "GIT=git"
where git >nul 2>nul
if errorlevel 1 (
  set "GIT=C:\Users\33359\.cache\codex-runtimes\codex-primary-runtime\dependencies\native\git\cmd\git.exe"
  if not exist "%GIT%" (
    echo 未找到 Git。请先安装 Git for Windows，然后重新运行本文件。
    pause
    exit /b 1
  )
)

if not exist ".git" (
  "%GIT%" init
  "%GIT%" branch -M main
)

"%GIT%" remote get-url origin >nul 2>nul
if errorlevel 1 (
  echo.
  echo 请先在 GitHub 创建一个空仓库，不要勾选 README。
  set /p REPO_URL=请粘贴仓库地址（例如 https://github.com/用户名/仓库名.git）：
  if "%REPO_URL%"=="" (
    echo 未填写仓库地址，已取消。
    pause
    exit /b 1
  )
  "%GIT%" remote add origin "%REPO_URL%"
)

"%GIT%" add .
"%GIT%" diff --cached --quiet
if errorlevel 1 (
  "%GIT%" commit -m "更新数学建模训练记录助手"
  if errorlevel 1 (
    echo.
    echo 提交失败。首次使用 Git 时，请先配置用户名和邮箱：
    echo git config --global user.name "你的名字"
    echo git config --global user.email "你的邮箱"
    pause
    exit /b 1
  )
) else (
  echo 没有需要提交的新修改。
)

"%GIT%" push -u origin main
if errorlevel 1 (
  echo.
  echo 上传失败。请检查 GitHub 登录状态、仓库地址和网络连接。
  pause
  exit /b 1
)

echo.
echo 上传成功。
echo 首次发布请进入仓库 Settings - Pages：
echo Source 选择 Deploy from a branch，Branch 选择 main 和 / (root)。
pause
