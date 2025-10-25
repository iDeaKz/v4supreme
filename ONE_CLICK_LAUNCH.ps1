# ZKAEDI SYSTEMS - ONE CLICK LAUNCH (PowerShell)
# ===============================================

Write-Host ""
Write-Host "⚛️ ZKAEDI SYSTEMS - ONE CLICK LAUNCH ⚛️" -ForegroundColor Cyan
Write-Host "=====================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "🚀 Starting Supreme V4 Quantum AI Protocol..." -ForegroundColor Green
Write-Host ""

# Kill any existing Python servers on port 8000
Write-Host "🔄 Stopping any existing servers..." -ForegroundColor Yellow
Get-Process | Where-Object {$_.ProcessName -eq "python"} | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

# Start the HTTP server in background
Write-Host "🌐 Starting HTTP server on port 8000..." -ForegroundColor Green
$serverJob = Start-Job -ScriptBlock {
    Set-Location "D:\_supreme_chain\supreme-v4-quantum-ai"
    python -m http.server 8000
}

# Wait for server to start
Write-Host "⏳ Waiting for server to initialize..." -ForegroundColor Yellow
Start-Sleep -Seconds 3

# Open all key pages
Write-Host "🎯 Opening ZKAEDI Systems pages..." -ForegroundColor Green
Write-Host ""

Write-Host "📊 Opening ZKAEDI Masterpiece Promotion..." -ForegroundColor Cyan
Start-Process "http://localhost:8000/ZKAEDI_MASTERPIECE_PROMOTION.html"
Start-Sleep -Seconds 2

Write-Host "🎮 Opening Interactive Quantum Dashboard..." -ForegroundColor Cyan
Start-Process "http://localhost:8000/frontend/interactive_quantum_dashboard.html"
Start-Sleep -Seconds 2

Write-Host "🎨 Opening Ultimate Quantum Dashboard..." -ForegroundColor Cyan
Start-Process "http://localhost:8000/frontend/ultimate_quantum_dashboard.html"
Start-Sleep -Seconds 2

Write-Host "📈 Opening Optimized Quantum Dashboard..." -ForegroundColor Cyan
Start-Process "http://localhost:8000/frontend/optimized_quantum_dashboard.html"
Start-Sleep -Seconds 2

Write-Host "🔬 Opening Quantum Visualization..." -ForegroundColor Cyan
Start-Process "http://localhost:8000/frontend/quantum_visualization.html"

Write-Host ""
Write-Host "✅ ALL SYSTEMS LAUNCHED!" -ForegroundColor Green
Write-Host ""
Write-Host "🌐 Available Pages:" -ForegroundColor Yellow
Write-Host "   📊 ZKAEDI Masterpiece: http://localhost8000/ZKAEDI_MASTERPIECE_PROMOTION.html" -ForegroundColor White
Write-Host "   🎮 Interactive Dashboard: http://localhost:8000/frontend/interactive_quantum_dashboard.html" -ForegroundColor White
Write-Host "   🎨 Ultimate Dashboard: http://localhost:8000/frontend/ultimate_quantum_dashboard.html" -ForegroundColor White
Write-Host "   📈 Optimized Dashboard: http://localhost:8000/frontend/optimized_quantum_dashboard.html" -ForegroundColor White
Write-Host "   🔬 Quantum Visualization: http://localhost:8000/frontend/quantum_visualization.html" -ForegroundColor White
Write-Host ""
Write-Host "💎 Gem Contracts: http://localhost:8000/gem_contracts/" -ForegroundColor Magenta
Write-Host "📚 Documentation: http://localhost:8000/README.md" -ForegroundColor Magenta
Write-Host ""
Write-Host "🏆 ZKAEDI SYSTEMS - QUANTUM DEFI MASTERPIECE 🏆" -ForegroundColor Green
Write-Host ""
Write-Host "Press any key to stop the server..." -ForegroundColor Red
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")

# Stop the server when user presses a key
Write-Host ""
Write-Host "🛑 Stopping server..." -ForegroundColor Yellow
Stop-Job $serverJob -ErrorAction SilentlyContinue
Remove-Job $serverJob -ErrorAction SilentlyContinue
Write-Host "✅ Server stopped." -ForegroundColor Green
Write-Host ""
Write-Host "👋 Thank you for using ZKAEDI Systems!" -ForegroundColor Cyan
Read-Host "Press Enter to exit"
