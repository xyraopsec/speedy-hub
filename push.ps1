# SPEEDY HUB - PUSH TO GITHUB (PowerShell)
# Usage: .\push.ps1 -Message "update speedy"
param([string]$Message = "update speedy")
Write-Host "[1/4] git add..." -ForegroundColor Cyan
git add -A
Write-Host "[2/4] git commit..." -ForegroundColor Cyan
git commit -m $Message 2>$null; if($LASTEXITCODE -ne 0){ Write-Host "(nothing to commit)" -ForegroundColor DarkGray }
Write-Host "[3/4] git push..." -ForegroundColor Cyan
git push
Write-Host "[4/4] done - $Message" -ForegroundColor Green
