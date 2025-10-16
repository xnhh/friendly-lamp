#!/usr/bin/env python3
"""
Starknet Devnet 部署脚本
使用 starknet-devnet 作为本地测试环境
"""

import subprocess
import json
import os
import sys
import time
import requests
from pathlib import Path

# Devnet 配置
DEVNET_HOST = "127.0.0.1"
DEVNET_PORT = 5050
DEVNET_URL = f"http://{DEVNET_HOST}:{DEVNET_PORT}"

def run_command(command, description, check=True):
    """运行命令并处理错误"""
    print(f"🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=check, capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ {description} 成功")
        return result
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} 失败: {e.stderr}")
        if check:
            sys.exit(1)
        return result

def check_devnet_installed():
    """检查 starknet-devnet 是否安装"""
    try:
        result = subprocess.run(["starknet-devnet", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            print("✅ starknet-devnet 已安装")
            return True
    except FileNotFoundError:
        pass
    
    print("❌ starknet-devnet 未安装")
    print("安装方法:")
    print("  pip install starknet-devnet")
    print("  或者")
    print("  pipx install starknet-devnet")
    return False

def start_devnet():
    """启动 starknet-devnet"""
    print(f"\n🚀 启动 starknet-devnet 在 {DEVNET_URL}...")
    
    # 检查 devnet 是否已经在运行
    try:
        response = requests.get(f"{DEVNET_URL}/is_alive", timeout=2)
        if response.status_code == 200:
            print("✅ starknet-devnet 已经在运行")
            return True
    except:
        pass
    
    # 启动 devnet
    cmd = f"starknet-devnet --host {DEVNET_HOST} --port {DEVNET_PORT} --seed 42 --accounts 10 --initial-balance 1000000000000000000000"
    
    # 在后台启动 devnet
    subprocess.Popen(cmd, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    
    # 等待 devnet 启动
    print("⏳ 等待 devnet 启动...")
    for i in range(30):  # 最多等待 30 秒
        try:
            response = requests.get(f"{DEVNET_URL}/is_alive", timeout=1)
            if response.status_code == 200:
                print("✅ starknet-devnet 启动成功")
                return True
        except:
            pass
        time.sleep(1)
    
    print("❌ starknet-devnet 启动超时")
    return False

def build_contract():
    """构建合约"""
    print("\n📦 构建合约...")
    run_command("scarb build", "构建 Cairo 合约")

def get_accounts():
    """获取 devnet 预配置账户"""
    try:
        response = requests.get(f"{DEVNET_URL}/predeployed_accounts")
        if response.status_code == 200:
            accounts = response.json()
            print(f"✅ 获取到 {len(accounts)} 个预配置账户")
            return accounts
    except Exception as e:
        print(f"❌ 获取账户失败: {e}")
    
    return []

def import_account():
    """导入 devnet 账户"""
    print("📝 导入 devnet 账户...")
    import_cmd = f"sncast account import --address=0x064b48806902a367c8598f4f95c305e8c1a1acba5f082d294a43793113115691 --type=oz --url=http://127.0.0.1:5050 --private-key=0x0000000000000000000000000000000071d7bb07b9a64f6f78ac4c816aff4da9 --add-profile=devnet --silent"
    
    result = run_command(import_cmd, "导入 devnet 账户", check=False)
    
    if result.returncode == 0:
        print("✅ 账户导入成功")
        return True
    else:
        print(f"⚠️ 账户导入失败，尝试继续: {result.stderr}")
        return False

def deploy_contract():
    """部署合约到 devnet"""
    print("\n🚀 部署合约到 devnet...")
    
    # 先导入账户
    import_account()
    
    contract_file = "target/dev/friendly_lamp_HelloWorld.contract_class.json"
    if not Path(contract_file).exists():
        print(f"❌ 合约文件不存在: {contract_file}")
        return None
    
    # 先声明合约类
    print("📝 声明合约类...")
    declare_cmd = f"sncast --profile=devnet declare --url=http://127.0.0.1:5050 --contract-name HelloWorld"
    
    declare_result = run_command(declare_cmd, "声明合约类", check=False)
    
    if declare_result.returncode != 0:
        print(f"❌ 声明合约类失败: {declare_result.stderr}")
        return None
    
    # 从声明结果中提取 class hash
    class_hash = None
    for line in declare_result.stdout.split('\n'):
        if 'class_hash:' in line:
            class_hash = line.split('class_hash:')[1].strip()
            print(f"✅ 获取到 class_hash: {class_hash}")
            break
    
    if not class_hash:
        print("❌ 无法从声明结果中获取 class_hash")
        return None
    
    # 使用 sncast 部署
    deploy_cmd = f"sncast --profile=devnet deploy --class-hash {class_hash} --constructor-calldata 0x48656c6c6f20576f726c64 --salt=0"
    
    result = run_command(deploy_cmd, "部署合约到 devnet", check=False)
    
    if result.returncode == 0:
        # 提取合约地址
        for line in result.stdout.split('\n'):
            if 'contract_address:' in line:
                contract_address = line.split('contract_address:')[1].strip()
                print(f"🎉 合约地址: {contract_address}")
                return contract_address
    else:
        print(f"❌ 部署失败: {result.stderr}")
    
    return None

def interact_with_contract(contract_address):
    """与合约交互的示例"""
    if not contract_address:
        return
    
    print(f"\n🔗 与合约交互示例 (地址: {contract_address})")
    print("你可以使用以下命令与合约交互:")
    print(f"  # 获取问候语")
    print(f"  sncast --profile=devnet call --contract-address {contract_address} --function get_greeting")
    print(f"  ")
    print(f"  # 设置新的问候语")
    print(f"  sncast --profile=devnet invoke --contract-address {contract_address} --function set_greeting --arguments 0x48656c6c6f204465766e6574")

def save_deployment_info(contract_address, accounts):
    """保存部署信息"""
    deployment_info = {
        "contract_address": contract_address,
        "devnet_url": DEVNET_URL,
        "accounts": accounts,
        "deployment_time": time.strftime("%Y-%m-%d %H:%M:%S")
    }
    
    with open("deployment-info.json", "w") as f:
        json.dump(deployment_info, f, indent=2)
    
    print(f"💾 部署信息已保存到 deployment-info.json")

def main():
    """主函数"""
    print("🌟 Starknet Devnet 部署工具")
    print("=" * 50)
    
    # 检查环境
    if not check_devnet_installed():
        return
    
    # 启动 devnet
    if not start_devnet():
        return
    
    # 构建合约
    build_contract()
    
    # 获取账户信息
    accounts = get_accounts()
    
    # 部署合约
    contract_address = deploy_contract()
    
    # 保存部署信息
    save_deployment_info(contract_address, accounts)
    
    # 显示交互示例
    interact_with_contract(contract_address)
    
    print(f"\n🎉 部署完成!")
    print(f"Devnet URL: {DEVNET_URL}")
    print(f"合约地址: {contract_address}")
    print(f"\n要停止 devnet，请按 Ctrl+C 或运行: pkill -f starknet-devnet")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 正在停止 devnet...")
        subprocess.run("pkill -f starknet-devnet", shell=True)
        print("✅ Devnet 已停止")
