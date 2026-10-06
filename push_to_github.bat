@echo off
setlocal

cd /d "%~dp0"

set "REMOTE_URL=https://github.com/bobozai2019/hd-2d.git"
git remote get-url origin >nul 2>&1
if errorlevel 1 (
    git remote add origin "%REMOTE_URL%"
) else (
    git remote set-url origin "%REMOTE_URL%"
)
if errorlevel 1 exit /b 1

git add -A
git diff --cached --quiet
if not errorlevel 1 (
    echo No changes to commit.
) else (
    git commit -m "Update project and ignore generated output"
    if errorlevel 1 exit /b 1
)

git push
if errorlevel 1 exit /b 1

echo Push completed successfully.
endlocal
