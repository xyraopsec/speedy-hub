@echo off
REM === SPEEDY HUB - DEPLOY TO VERCEL ===
REM First time: npx vercel link  OR import GitHub repo in Vercel dashboard
setlocal
echo [1/3] building...
cd dashboard
call npm run build
if %errorlevel% neq 0 ( echo build failed & exit /b 1 )
echo [2/3] vercel deploy --prod...
call npx vercel --prod --yes
echo [3/3] done
endlocal
