@echo off
REM === SPEEDY HUB - PUSH TO GITHUB ===
REM Usage: push.bat "commit message"
setlocal
if "%~1"=="" (set MSG=update speedy) else (set MSG=%~1)
echo [1/4] git add...
git add -A
echo [2/4] git commit...
git commit -m "%MSG%" 2>nul
if %errorlevel% neq 0 echo (nothing to commit)
echo [3/4] git push...
git push
echo [4/4] done - %MSG%
endlocal
