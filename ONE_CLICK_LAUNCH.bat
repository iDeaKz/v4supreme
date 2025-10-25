@echo off
echo.
echo ⚛️ ZKAEDI SYSTEMS - ONE CLICK LAUNCH ⚛️
echo =====================================
echo.
echo 🚀 Starting Supreme V4 Quantum AI Protocol...
echo.

REM Kill any existing Python servers on port 8000
echo 🔄 Stopping any existing servers...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8000') do taskkill /f /pid %%a >nul 2>&1

REM Wait a moment
timeout /t 2 /nobreak >nul

REM Start the HTTP server in background
echo 🌐 Starting HTTP server on port 8000...
start /b python -m http.server 8000

REM Wait for server to start
echo ⏳ Waiting for server to initialize...
timeout /t 3 /nobreak >nul

REM Open all key pages
echo 🎯 Opening ZKAEDI Systems pages...
echo.

echo 📊 Opening ZKAEDI Masterpiece Promotion...
start "" "http://localhost:8000/ZKAEDI_MASTERPIECE_PROMOTION.html"

timeout /t 2 /nobreak >nul

echo 🎮 Opening Interactive Quantum Dashboard...
start "" "http://localhost:8000/frontend/interactive_quantum_dashboard.html"

timeout /t 2 /nobreak >nul

echo 🎨 Opening Ultimate Quantum Dashboard...
start "" "http://localhost:8000/frontend/ultimate_quantum_dashboard.html"

timeout /t 2 /nobreak >nul

echo 📈 Opening Optimized Quantum Dashboard...
start "" "http://localhost:8000/frontend/optimized_quantum_dashboard.html"

timeout /t 2 /nobreak >nul

echo 🔬 Opening Quantum Visualization...
start "" "http://localhost:8000/frontend/quantum_visualization.html"

echo.
echo ✅ ALL SYSTEMS LAUNCHED!
echo.
echo 🌐 Available Pages:
echo    📊 ZKAEDI Masterpiece: http://localhost:8000/ZKAEDI_MASTERPIECE_PROMOTION.html
echo    🎮 Interactive Dashboard: http://localhost:8000/frontend/interactive_quantum_dashboard.html
echo    🎨 Ultimate Dashboard: http://localhost:8000/frontend/ultimate_quantum_dashboard.html
echo    📈 Optimized Dashboard: http://localhost:8000/frontend/optimized_quantum_dashboard.html
echo    🔬 Quantum Visualization: http://localhost:8000/frontend/quantum_visualization.html
echo.
echo 💎 Gem Contracts: http://localhost:8000/gem_contracts/
echo 📚 Documentation: http://localhost:8000/README.md
echo.
echo 🏆 ZKAEDI SYSTEMS - QUANTUM DEFI MASTERPIECE 🏆
echo.
echo Press any key to stop the server...
pause >nul

REM Stop the server when user presses a key
echo.
echo 🛑 Stopping server...
for /f "tokens=5" %%a in ('netstat -aon ^| findstr :8000') do taskkill /f /pid %%a >nul 2>&1
echo ✅ Server stopped.
echo.
echo 👋 Thank you for using ZKAEDI Systems!
pause
