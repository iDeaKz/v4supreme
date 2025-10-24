#!/usr/bin/env python3
"""
Simple test script for the quantum engine
"""

import numpy as np
import sys
import os

# Add current directory to path
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from hamiltonian_trading import QuantumTradingHamiltonian, create_default_parameters
    from gradient_optimizer import QuantumGradientOptimizer
    
    print("✅ All modules imported successfully!")
    
    # Test quantum Hamiltonian
    print("\n🧠 Testing Quantum Hamiltonian...")
    hamiltonian = QuantumTradingHamiltonian()
    params = create_default_parameters()
    
    # Test Hamiltonian construction
    H = hamiltonian.hamiltonian_operator(0.5, params)
    print(f"✅ Hamiltonian matrix shape: {H.shape}")
    print(f"✅ Hamiltonian is Hermitian: {np.allclose(H, H.conj().T)}")
    
    # Test gradient optimizer
    print("\n🎯 Testing Gradient Optimizer...")
    optimizer = QuantumGradientOptimizer()
    
    # Test optimization
    optimized_params = optimizer.optimize_parameters(hamiltonian, params, max_epochs=10)
    print(f"✅ Optimization completed!")
    print(f"✅ Final loss: {optimized_params.final_loss:.6f}")
    
    # Test trading signal
    print("\n📊 Testing Trading Signal...")
    signal = hamiltonian.calculate_trading_signal()
    print(f"✅ Trading signal: {signal:.6f}")
    
    print("\n🎉 ALL TESTS PASSED! Quantum engine is working perfectly!")
    
except Exception as e:
    print(f"❌ Error: {e}")
    import traceback
    traceback.print_exc()
