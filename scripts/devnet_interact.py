#!/usr/bin/env python3
"""
Starknet Devnet 合约交互脚本
与部署在 devnet 上的合约进行交互
"""

import json
import requests
import subprocess
import sys
from pathlib import Path

# Devnet 配置
DEVNET_HOST = "127.0.0.1"
DEVNET_PORT = 5050
DEVNET_URL = f"http://{DEVNET_HOST}:{DEVNET_PORT}"

def load_deployment_info():
    """加载部署信息"""
    info_file = Path("deployment-info.json")
    if not info_file.exists():
        print("❌ 未找到部署信息文件 deployment-info.json")
        print("请先运行部署脚本: python3 scripts/devnet_deploy.py")
        return None
    
    with open(info_file, "r") as f:
        return json.load(f)

def check_devnet_running():
    """检查 devnet 是否运行"""
    try:
        response = requests.get(f"{DEVNET_URL}/is_alive", timeout=2)
        return response.status_code == 200
    except:
        return False

def run_starknet_command(command):
    """运行 starknet 命令"""
    try:
        result = subprocess.run(command, shell=True, capture_output=True, text=True)
        return result.returncode == 0, result.stdout, result.stderr
    except Exception as e:
        return False, "", str(e)

def call_contract_function(contract_address, abi_file, function_name, inputs=None):
    """调用合约函数"""
    gateway_url = f"{DEVNET_URL}/gateway"
    feeder_gateway_url = f"{DEVNET_URL}/feeder_gateway"
    
    cmd = f"starknet call --gateway_url {gateway_url} --feeder_gateway_url {feeder_gateway_url} --address {contract_address} --abi {abi_file} --function {function_name}"
    
    if inputs:
        cmd += f" --inputs {' '.join(inputs)}"
    
    success, stdout, stderr = run_starknet_command(cmd)
    
    if success:
        return True, stdout.strip()
    else:
        return False, stderr

def invoke_contract_function(contract_address, abi_file, function_name, inputs=None):
    """调用合约函数（写入操作）"""
    gateway_url = f"{DEVNET_URL}/gateway"
    feeder_gateway_url = f"{DEVNET_URL}/feeder_gateway"
    
    cmd = f"starknet invoke --gateway_url {gateway_url} --feeder_gateway_url {feeder_gateway_url} --address {contract_address} --abi {abi_file} --function {function_name}"
    
    if inputs:
        cmd += f" --inputs {' '.join(inputs)}"
    
    success, stdout, stderr = run_starknet_command(cmd)
    
    if success:
        return True, stdout.strip()
    else:
        return False, stderr

def get_greeting(contract_address, abi_file):
    """获取问候语"""
    print("📖 获取当前问候语...")
    success, result = call_contract_function(contract_address, abi_file, "get_greeting")
    
    if success:
        # 解析结果
        if result:
            try:
                # 提取十六进制值并转换为字符串
                hex_value = result.split()[-1] if result.split() else ""
                if hex_value.startswith("0x"):
                    hex_value = hex_value[2:]
                # 将十六进制转换为字符串
                greeting = bytes.fromhex(hex_value).decode('utf-8')
                print(f"✅ 当前问候语: {greeting}")
            except:
                print(f"✅ 原始结果: {result}")
        else:
            print("❌ 未获取到结果")
    else:
        print(f"❌ 获取问候语失败: {result}")

def set_greeting(contract_address, abi_file, new_greeting):
    """设置新的问候语"""
    print(f"✏️  设置问候语为: {new_greeting}")
    
    # 将字符串转换为十六进制
    hex_greeting = new_greeting.encode('utf-8').hex()
    inputs = [f"0x{hex_greeting}"]
    
    success, result = invoke_contract_function(contract_address, abi_file, "set_greeting", inputs)
    
    if success:
        print(f"✅ 设置成功: {result}")
    else:
        print(f"❌ 设置失败: {result}")

def get_balance(contract_address, abi_file):
    """获取余额"""
    print("💰 获取当前余额...")
    success, result = call_contract_function(contract_address, abi_file, "get_balance")
    
    if success:
        print(f"✅ 当前余额: {result}")
    else:
        print(f"❌ 获取余额失败: {result}")

def deposit(contract_address, abi_file, amount):
    """存款"""
    print(f"💳 存款 {amount}...")
    inputs = [str(amount)]
    
    success, result = invoke_contract_function(contract_address, abi_file, "deposit", inputs)
    
    if success:
        print(f"✅ 存款成功: {result}")
    else:
        print(f"❌ 存款失败: {result}")

def withdraw(contract_address, abi_file, amount):
    """提取"""
    print(f"💸 提取 {amount}...")
    inputs = [str(amount)]
    
    success, result = invoke_contract_function(contract_address, abi_file, "withdraw", inputs)
    
    if success:
        print(f"✅ 提取成功: {result}")
    else:
        print(f"❌ 提取失败: {result}")

def show_menu():
    """显示菜单"""
    print("\n" + "="*50)
    print("🔗 合约交互菜单")
    print("="*50)
    print("1. 获取问候语")
    print("2. 设置问候语")
    print("3. 获取余额")
    print("4. 存款")
    print("5. 提取")
    print("6. 显示合约信息")
    print("0. 退出")
    print("="*50)

def main():
    """主函数"""
    print("🌟 Starknet Devnet 合约交互工具")
    print("=" * 50)
    
    # 检查 devnet 是否运行
    if not check_devnet_running():
        print("❌ Devnet 未运行")
        print("请先启动 devnet: python3 scripts/devnet_deploy.py")
        return
    
    # 加载部署信息
    deployment_info = load_deployment_info()
    if not deployment_info:
        return
    
    contract_address = deployment_info.get("contract_address")
    abi_file = "target/dev/friendly_lamp_HelloWorld.contract_class.json"
    
    if not contract_address:
        print("❌ 未找到合约地址")
        return
    
    if not Path(abi_file).exists():
        print(f"❌ ABI 文件不存在: {abi_file}")
        return
    
    print(f"✅ 连接到合约: {contract_address}")
    print(f"✅ Devnet URL: {DEVNET_URL}")
    
    while True:
        show_menu()
        choice = input("\n请选择操作 (0-6): ").strip()
        
        if choice == "0":
            print("👋 再见!")
            break
        elif choice == "1":
            get_greeting(contract_address, abi_file)
        elif choice == "2":
            new_greeting = input("请输入新的问候语: ").strip()
            if new_greeting:
                set_greeting(contract_address, abi_file, new_greeting)
        elif choice == "3":
            get_balance(contract_address, abi_file)
        elif choice == "4":
            try:
                amount = int(input("请输入存款金额: ").strip())
                deposit(contract_address, abi_file, amount)
            except ValueError:
                print("❌ 请输入有效的数字")
        elif choice == "5":
            try:
                amount = int(input("请输入提取金额: ").strip())
                withdraw(contract_address, abi_file, amount)
            except ValueError:
                print("❌ 请输入有效的数字")
        elif choice == "6":
            print(f"\n📋 合约信息:")
            print(f"   地址: {contract_address}")
            print(f"   Devnet URL: {DEVNET_URL}")
            print(f"   部署时间: {deployment_info.get('deployment_time', '未知')}")
        else:
            print("❌ 无效选择，请重试")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 再见!")
