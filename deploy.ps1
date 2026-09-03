# SPEEDY HUB - DEPLOY TO VERCEL (PowerShell)
# First time: npx vercel link  (or import GitHub repo in Vercel dashboard)
# Needs DATABASE_URL from Vercel Storage > Prisma Postgres
Write-Host "[1/3] building dashboard..." -ForegroundColor Cyan
Set-Location "$PSScriptRoot\dashboard"
npm run build
if($LASTEXITCODE -ne 0){ Write-Error "build failed"; exit 1 }
Write-Host "[2/3] vercel deploy --prod..." -ForegroundColor Cyan
npx vercel --prod --yes
Write-Host "[3/3] done" -ForegroundColor Green
