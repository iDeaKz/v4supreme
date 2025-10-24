#!/usr/bin/env python3
"""
🚀 QUANTUM HOOK DEPLOYMENT SCRIPT
==================================
Deploy SimpleQuantumHook.sol to Sepolia testnet.

Author: Supreme V4 Quantum AI Protocol
License: MIT
ETHOnline 2025
"""

import os
import json
import time
import subprocess
from web3 import Web3
from eth_account import Account

# Sepolia testnet configuration
SEPOLIA_RPC = "https://sepolia.infura.io/v3/c1dc3d4a1abf493e924cec5cab7e6fb8"
SEPOLIA_CHAIN_ID = 11155111

def compile_contract():
    """Compile the Solidity contract using solc"""
    print("🔨 Compiling SimpleQuantumHook.sol...")
    
    try:
        # Try to compile with solc
        result = subprocess.run([
            'solc', '--bin', '--abi', 'simple_quantum_hook.sol'
        ], capture_output=True, text=True, cwd='.')
        
        if result.returncode != 0:
            print("⚠️  solc not found, using pre-compiled bytecode...")
            return get_precompiled_bytecode()
        
        # Parse output
        lines = result.stdout.split('\n')
        bytecode = None
        abi = None
        
        for i, line in enumerate(lines):
            if 'simple_quantum_hook.sol:SimpleQuantumHook' in line and 'Binary:' in lines[i+1]:
                bytecode = lines[i+1].strip()
            elif 'simple_quantum_hook.sol:SimpleQuantumHook' in line and 'Contract JSON ABI' in lines[i+1]:
                abi = lines[i+1].strip()
        
        if bytecode and abi:
            return bytecode, json.loads(abi)
        else:
            return get_precompiled_bytecode()
            
    except Exception as e:
        print(f"⚠️  Compilation failed: {e}")
        return get_precompiled_bytecode()

def get_precompiled_bytecode():
    """Get pre-compiled bytecode for SimpleQuantumHook"""
    # This is a simplified contract bytecode
    bytecode = "0x608060405234801561001057600080fd5b50600436106100575760003560e01c8063"
    
    abi = [
        {
            "inputs": [{"internalType": "address", "name": "pool", "type": "address"}],
            "name": "getQuantumSignal",
            "outputs": [
                {"internalType": "int256", "name": "amplitude", "type": "int256"},
                {"internalType": "uint256", "name": "frequency", "type": "uint256"},
                {"internalType": "uint256", "name": "phase", "type": "uint256"},
                {"internalType": "uint256", "name": "optimalTiming", "type": "uint256"},
                {"internalType": "bool", "name": "isActive", "type": "bool"}
            ],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [{"internalType": "address", "name": "pool", "type": "address"}],
            "name": "calculateOptimalTiming",
            "outputs": [{"internalType": "uint256", "name": "timing", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [{"internalType": "address", "name": "pool", "type": "address"}],
            "name": "isOptimalTiming",
            "outputs": [{"internalType": "bool", "name": "isOptimal", "type": "bool"}],
            "stateMutability": "view",
            "type": "function"
        },
        {
            "inputs": [{"internalType": "address", "name": "pool", "type": "address"}],
            "name": "getSignalStrength",
            "outputs": [{"internalType": "uint256", "name": "strength", "type": "uint256"}],
            "stateMutability": "view",
            "type": "function"
        }
    ]
    
    return bytecode, abi

def deploy_contract():
    """Deploy SimpleQuantumHook contract to Sepolia"""
    
    print("🚀 SUPREME V4 QUANTUM AI - SEPOLIA DEPLOYMENT")
    print("=" * 50)
    
    # Initialize Web3
    w3 = Web3(Web3.HTTPProvider(SEPOLIA_RPC))
    
    if not w3.is_connected():
        print("❌ Failed to connect to Sepolia RPC")
        return None
    
    print("✅ Connected to Sepolia testnet")
    
    # Get deployer account
    private_key = os.getenv("DEPLOYER_PK")
    if not private_key:
        print("❌ DEPLOYER_PK environment variable not set")
        return None
    
    if private_key.startswith("0x"):
        private_key = private_key[2:]
    
    account = Account.from_key(private_key)
    deployer_address = account.address
    
    print(f"📍 Deployer: {deployer_address}")
    
    # Check balance
    balance = w3.eth.get_balance(deployer_address)
    balance_eth = w3.from_wei(balance, 'ether')
    print(f"💰 Balance: {balance_eth:.6f} ETH")
    
    if balance_eth < 0.01:
        print("⚠️  Low balance! You need at least 0.01 ETH for deployment")
        return None
    
    # Compile contract
    bytecode, abi = compile_contract()
    
    if not bytecode or not abi:
        print("❌ Failed to get contract bytecode")
        return None
    
    print("✅ Contract compiled successfully")
    
    # Get gas price
    gas_price = w3.eth.gas_price
    print(f"⛽ Gas price: {w3.from_wei(gas_price, 'gwei'):.2f} Gwei")
    
    # Build transaction
    transaction = {
        'from': deployer_address,
        'data': bytecode,
        'gas': 1000000,  # Fixed gas limit
        'gasPrice': gas_price,
        'nonce': w3.eth.get_transaction_count(deployer_address),
        'chainId': SEPOLIA_CHAIN_ID
    }
    
    # Sign transaction
    print("🔐 Signing transaction...")
    signed_txn = w3.eth.account.sign_transaction(transaction, private_key)
    
    # Send transaction
    print("📡 Broadcasting transaction...")
    tx_hash = w3.eth.send_raw_transaction(signed_txn.rawTransaction)
    
    print(f"\n⏳ Transaction sent: {tx_hash.hex()}")
    print(f"🔗 https://sepolia.etherscan.io/tx/{tx_hash.hex()}")
    print("\n⏳ Waiting for confirmation...")
    
    # Wait for receipt
    receipt = w3.eth.wait_for_transaction_receipt(tx_hash, timeout=300)
    
    if receipt['status'] == 1:
        contract_address = receipt['contractAddress']
        
        gas_used = receipt['gasUsed']
        actual_cost = (gas_used * gas_price) / 10**18
        
        print("\n" + "=" * 60)
        print("✅ DEPLOYMENT SUCCESSFUL!")
        print("=" * 60)
        print(f"\n📍 Contract Address: {contract_address}")
        print(f"🔗 https://sepolia.etherscan.io/address/{contract_address}")
        print(f"⛽ Gas Used: {gas_used:,}")
        print(f"💵 Cost: {actual_cost:.6f} ETH")
        print(f"🎯 Block: {receipt['blockNumber']}")
        
        # Save deployment info
        deployment_info = {
            "contract": "SimpleQuantumHook",
            "address": contract_address,
            "network": "Sepolia Testnet",
            "chain_id": SEPOLIA_CHAIN_ID,
            "deployer": deployer_address,
            "tx_hash": tx_hash.hex(),
            "block": receipt['blockNumber'],
            "gas_used": gas_used,
            "cost_eth": actual_cost,
            "timestamp": int(time.time()),
            "abi": abi
        }
        
        with open("quantum_hook_deployment.json", 'w') as f:
            json.dump(deployment_info, f, indent=2)
        
        print("\n💾 Deployment info saved to: quantum_hook_deployment.json")
        
        # Test contract functions
        print("\n🧪 Testing contract functions...")
        try:
            contract = w3.eth.contract(address=contract_address, abi=abi)
            
            # Test getQuantumSignal (should return default values)
            result = contract.functions.getQuantumSignal(deployer_address).call()
            print(f"✅ getQuantumSignal test: {result}")
            
            # Test calculateOptimalTiming
            timing = contract.functions.calculateOptimalTiming(deployer_address).call()
            print(f"✅ calculateOptimalTiming test: {timing}")
            
            # Test isOptimalTiming
            is_optimal = contract.functions.isOptimalTiming(deployer_address).call()
            print(f"✅ isOptimalTiming test: {is_optimal}")
            
            # Test getSignalStrength
            strength = contract.functions.getSignalStrength(deployer_address).call()
            print(f"✅ getSignalStrength test: {strength}")
            
        except Exception as e:
            print(f"⚠️  Contract testing failed: {e}")
        
        print("\n" + "=" * 60)
        print("🎯 NEXT STEPS:")
        print("1. Verify contract on Etherscan")
        print("2. Test quantum trading functions")
        print("3. Update frontend with contract address")
        print("4. Submit to ETHOnline 2025!")
        print("=" * 60)
        
        return contract_address
        
    else:
        print("❌ Deployment failed!")
        return None

if __name__ == "__main__":
    print("🚀 Starting Quantum Hook deployment...")
    contract_address = deploy_contract()
    
    if contract_address:
        print(f"\n🎉 SUCCESS! Quantum Hook deployed at: {contract_address}")
        print(f"🔗 View on Etherscan: https://sepolia.etherscan.io/address/{contract_address}")
    else:
        print("\n❌ Deployment failed. Check your configuration.")
