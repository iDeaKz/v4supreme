#!/usr/bin/env python3
"""
🚀 ZKAEDI SYSTEMS - ONE CLICK LAUNCH
==================================
One-click launcher for Supreme V4 Quantum AI Protocol

Features:
- Starts HTTP server automatically
- Opens all key pages in browser
- Cross-platform compatibility
- Beautiful console output
- Easy server management

Author: ZKAEDI Systems
License: MIT
"""

import os
import sys
import time
import webbrowser
import subprocess
import threading
import signal
from pathlib import Path

class ZKAEDILauncher:
    def __init__(self):
        self.server_process = None
        self.base_url = "http://localhost:8000"
        self.pages = [
            {
                "name": "ZKAEDI Masterpiece Promotion",
                "url": f"{self.base_url}/ZKAEDI_MASTERPIECE_PROMOTION.html",
                "icon": "📊",
                "description": "Main promotion page with gem contracts showcase"
            },
            {
                "name": "Interactive Quantum Dashboard",
                "url": f"{self.base_url}/frontend/interactive_quantum_dashboard.html",
                "icon": "🎮",
                "description": "Fully interactive dashboard with working buttons"
            },
            {
                "name": "Ultimate Quantum Dashboard",
                "url": f"{self.base_url}/frontend/ultimate_quantum_dashboard.html",
                "icon": "🎨",
                "description": "Integrated quantum visualizations"
            },
            {
                "name": "Optimized Quantum Dashboard",
                "url": f"{self.base_url}/frontend/optimized_quantum_dashboard.html",
                "icon": "📈",
                "description": "Performance-optimized dashboard"
            },
            {
                "name": "Quantum Visualization",
                "url": f"{self.base_url}/frontend/quantum_visualization.html",
                "icon": "🔬",
                "description": "Advanced D3.js quantum visualizations"
            }
        ]
    
    def print_banner(self):
        """Print the ZKAEDI Systems banner"""
        banner = """
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║  ⚛️  ZKAEDI SYSTEMS - QUANTUM DEFI MASTERPIECE  ⚛️           ║
║                                                              ║
║  🚀 Supreme V4 Quantum AI Trading Protocol                  ║
║  💎 $1.59M+ Gem Contracts Collection                       ║
║  🎯 10 Premium Smart Contracts                             ║
║  🏆 World-First Quantum DeFi Innovation                    ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
        """
        print(banner)
    
    def kill_existing_servers(self):
        """Kill any existing Python servers on port 8000"""
        try:
            # Find processes using port 8000
            result = subprocess.run(['netstat', '-ano'], capture_output=True, text=True)
            for line in result.stdout.split('\n'):
                if ':8000' in line and 'LISTENING' in line:
                    parts = line.split()
                    if len(parts) > 4:
                        pid = parts[-1]
                        try:
                            subprocess.run(['taskkill', '/F', '/PID', pid], 
                                         capture_output=True, check=True)
                            print("🔄 Stopped existing server")
                        except:
                            pass
        except:
            pass
    
    def start_server(self):
        """Start the HTTP server"""
        print("🌐 Starting HTTP server on port 8000...")
        try:
            self.server_process = subprocess.Popen(
                [sys.executable, '-m', 'http.server', '8000'],
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                cwd=Path(__file__).parent
            )
            print("✅ Server started successfully!")
            return True
        except Exception as e:
            print(f"❌ Failed to start server: {e}")
            return False
    
    def wait_for_server(self, timeout=10):
        """Wait for server to be ready"""
        print("⏳ Waiting for server to initialize...")
        for i in range(timeout):
            try:
                import urllib.request
                urllib.request.urlopen(self.base_url, timeout=1)
                print("✅ Server is ready!")
                return True
            except:
                time.sleep(1)
        print("❌ Server failed to start within timeout")
        return False
    
    def open_pages(self):
        """Open all pages in browser"""
        print("\n🎯 Opening ZKAEDI Systems pages...\n")
        
        for i, page in enumerate(self.pages, 1):
            print(f"{page['icon']} Opening {page['name']}...")
            print(f"   📝 {page['description']}")
            try:
                webbrowser.open(page['url'])
                time.sleep(1)  # Small delay between opens
            except Exception as e:
                print(f"   ❌ Failed to open {page['name']}: {e}")
            print()
    
    def show_available_pages(self):
        """Show all available pages"""
        print("🌐 Available Pages:")
        print("=" * 50)
        
        for page in self.pages:
            print(f"{page['icon']} {page['name']}")
            print(f"   🔗 {page['url']}")
            print(f"   📝 {page['description']}")
            print()
        
        print("💎 Additional Resources:")
        print(f"   📁 Gem Contracts: {self.base_url}/gem_contracts/")
        print(f"   📚 Documentation: {self.base_url}/README.md")
        print(f"   🎬 Demo Script: {self.base_url}/DEMO_VIDEO_SCRIPT.md")
        print()
    
    def run(self):
        """Main launcher function"""
        try:
            # Print banner
            self.print_banner()
            
            # Kill existing servers
            print("🔄 Stopping any existing servers...")
            self.kill_existing_servers()
            time.sleep(2)
            
            # Start server
            if not self.start_server():
                return False
            
            # Wait for server
            if not self.wait_for_server():
                return False
            
            # Open pages
            self.open_pages()
            
            # Show available pages
            self.show_available_pages()
            
            print("🏆 ZKAEDI SYSTEMS - QUANTUM DEFI MASTERPIECE 🏆")
            print("\n✅ ALL SYSTEMS LAUNCHED!")
            print("\nPress Ctrl+C to stop the server...")
            
            # Keep server running
            try:
                while True:
                    time.sleep(1)
            except KeyboardInterrupt:
                print("\n\n🛑 Stopping server...")
                if self.server_process:
                    self.server_process.terminate()
                    self.server_process.wait()
                print("✅ Server stopped.")
                print("\n👋 Thank you for using ZKAEDI Systems!")
            
        except Exception as e:
            print(f"❌ Error: {e}")
            return False
        
        return True

def main():
    """Main entry point"""
    launcher = ZKAEDILauncher()
    success = launcher.run()
    
    if not success:
        print("\n❌ Launch failed. Please check the error messages above.")
        sys.exit(1)
    else:
        print("\n🎉 Launch completed successfully!")

if __name__ == "__main__":
    main()
