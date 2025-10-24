#!/bin/bash

# ============================================================================
# 🚀 SUPREME V4 QUANTUM AI PROTOCOL - QUICK SETUP SCRIPT
# ============================================================================
# This script sets up the complete development environment
# Author: Supreme V4 Quantum AI Protocol
# License: MIT
# ETHOnline 2025
# ============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print banner
print_banner() {
    echo -e "${CYAN}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║   ⚛️  SUPREME V4 QUANTUM AI TRADING PROTOCOL  ⚛️             ║
║                                                               ║
║   Quick Setup Script for ETHOnline 2025                      ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

# Print section header
print_section() {
    echo -e "\n${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Print success message
print_success() {
    echo -e "${GREEN}✓${NC} $1"
}

# Print error message
print_error() {
    echo -e "${RED}✗${NC} $1"
}

# Print warning message
print_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Main setup
main() {
    print_banner
    
    # ========================================================================
    # STEP 1: Check Prerequisites
    # ========================================================================
    
    print_section "STEP 1: Checking Prerequisites"
    
    # Check Python
    if command_exists python3; then
        PYTHON_VERSION=$(python3 --version | awk '{print $2}')
        print_success "Python 3 found: $PYTHON_VERSION"
    else
        print_error "Python 3 not found. Please install Python 3.9 or higher."
        exit 1
    fi
    
    # Check pip
    if command_exists pip3; then
        print_success "pip3 found"
    else
        print_error "pip3 not found. Please install pip3."
        exit 1
    fi
    
    # Check git
    if command_exists git; then
        print_success "git found"
    else
        print_warning "git not found. Install git for version control."
    fi
    
    # Check node (optional)
    if command_exists node; then
        NODE_VERSION=$(node --version)
        print_success "Node.js found: $NODE_VERSION"
    else
        print_warning "Node.js not found. Optional for smart contract development."
    fi
    
    # ========================================================================
    # STEP 2: Install Python Dependencies
    # ========================================================================
    
    print_section "STEP 2: Installing Python Dependencies"
    
    cd quantum_engine
    
    echo -e "Installing required packages...\n"
    
    # Install core dependencies
    pip3 install --quiet numpy scipy matplotlib web3 eth-account rich
    
    if [ $? -eq 0 ]; then
        print_success "Core dependencies installed"
    else
        print_error "Failed to install dependencies"
        exit 1
    fi
    
    cd ..
    
    # ========================================================================
    # STEP 3: Test Quantum Engine
    # ========================================================================
    
    print_section "STEP 3: Testing Quantum Engine"
    
    echo -e "Running Hamiltonian trading engine test...\n"
    
    cd quantum_engine
    python3 hamiltonian_trading.py > /tmp/test_hamiltonian.log 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Quantum Hamiltonian engine: PASSED"
    else
        print_error "Quantum Hamiltonian engine: FAILED"
        cat /tmp/test_hamiltonian.log
        exit 1
    fi
    
    echo -e "\nRunning gradient optimizer test...\n"
    
    python3 gradient_optimizer.py > /tmp/test_optimizer.log 2>&1
    
    if [ $? -eq 0 ]; then
        print_success "Gradient optimizer: PASSED"
    else
        print_error "Gradient optimizer: FAILED"
        cat /tmp/test_optimizer.log
        exit 1
    fi
    
    cd ..
    
    # ========================================================================
    # STEP 4: Verify Files
    # ========================================================================
    
    print_section "STEP 4: Verifying Project Structure"
    
    # Check for essential files
    FILES=(
        "README.md"
        "PROJECT_STRUCTURE.md"
        "quantum_engine/hamiltonian_trading.py"
        "quantum_engine/gradient_optimizer.py"
        "quantum_engine/oracle_bridge.py"
        "quantum_engine/demo.py"
        "quantum_engine/requirements.txt"
        "contracts/AIQuantumHook.sol"
        "frontend/quantum_dashboard.html"
    )
    
    for file in "${FILES[@]}"; do
        if [ -f "$file" ]; then
            print_success "$file"
        else
            print_warning "$file not found"
        fi
    done
    
    # ========================================================================
    # STEP 5: Summary
    # ========================================================================
    
    print_section "SETUP COMPLETE!"
    
    echo -e "${GREEN}✓ Installation successful!${NC}\n"
    
    echo -e "${CYAN}Next Steps:${NC}"
    echo -e "  1. Run interactive demo:"
    echo -e "     ${YELLOW}cd quantum_engine && python3 demo.py${NC}\n"
    
    echo -e "  2. Open dashboard:"
    echo -e "     ${YELLOW}cd frontend && python3 -m http.server 8000${NC}"
    echo -e "     ${YELLOW}Open: http://localhost:8000/quantum_dashboard.html${NC}\n"
    
    echo -e "  3. Test individual modules:"
    echo -e "     ${YELLOW}cd quantum_engine${NC}"
    echo -e "     ${YELLOW}python3 hamiltonian_trading.py${NC}"
    echo -e "     ${YELLOW}python3 gradient_optimizer.py${NC}\n"
    
    echo -e "${CYAN}Documentation:${NC}"
    echo -e "  • README.md - Comprehensive guide"
    echo -e "  • PROJECT_STRUCTURE.md - File organization"
    echo -e "  • Demo video script in README.md\n"
    
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${GREEN}Built with ⚛️ quantum precision and 💜 for DeFi${NC}"
    echo -e "${GREEN}ETHOnline 2025 | Supreme V4 Quantum AI Protocol${NC}"
    echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
}

# Run main function
main
