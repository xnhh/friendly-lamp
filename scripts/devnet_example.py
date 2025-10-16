#!/usr/bin/env python3
"""
Starknet Devnet 使用示例
演示如何使用 devnet 进行合约开发和测试
"""

import subprocess
import time
import json
from pathlib import Path

def run_command(command, description):
    """运行命令"""
    print(f"🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} 成功")
        return result.stdout
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} 失败: {e.stderr}")
        return None

def main():
    """主函数 - 演示完整的 devnet 工作流程"""
    print("🌟 Starknet Devnet 使用示例")
    print("=" * 50)
    
    # 1. 检查环境
    print("\n📋 步骤 1: 检查环境")
    if not Path("Scarb.toml").exists():
        print("❌ 请在项目根目录运行此脚本")
        return
    
    # 2. 构建合约
    print("\n📦 步骤 2: 构建合约")
    if not run_command("scarb build", "构建 Cairo 合约"):
        return
    
    # 3. 运行测试
    print("\n🧪 步骤 3: 运行测试")
    if not run_command("scarb test", "运行 Cairo 测试"):
        return
    
    # 4. 启动 devnet
    print("\n🚀 步骤 4: 启动 devnet")
    print("注意: 这将在后台启动 devnet，按 Ctrl+C 停止")
    
    # 检查 devnet 是否已运行
    try:
        import requests
        response = requests.get("http://127.0.0.1:5050/is_alive", timeout=2)
        if response.status_code == 200:
            print("✅ Devnet 已经在运行")
        else:
            print("❌ Devnet 未运行")
            return
    except:
        print("❌ 请先启动 devnet: make devnet-start")
        return
    
    # 5. 部署合约
    print("\n🚀 步骤 5: 部署合约到 devnet")
    if not run_command("python3 scripts/devnet_deploy.py", "部署合约到 devnet"):
        return
    
    # 6. 显示部署信息
    print("\n📋 步骤 6: 部署信息")
    if Path("deployment-info.json").exists():
        with open("deployment-info.json", "r") as f:
            info = json.load(f)
        print(f"✅ 合约地址: {info.get('contract_address', '未知')}")
        print(f"✅ Devnet URL: {info.get('devnet_url', '未知')}")
        print(f"✅ 部署时间: {info.get('deployment_time', '未知')}")
    
    # 7. 交互示例
    print("\n🔗 步骤 7: 合约交互示例")
    print("现在你可以:")
    print("1. 运行 'make interact-devnet' 启动交互工具")
    print("2. 或者使用 starknet CLI 直接与合约交互")
    print("3. 或者编写自己的交互脚本")
    
    print("\n🎉 示例完成!")
    print("\n有用的命令:")
    print("  make devnet-status    # 检查 devnet 状态")
    print("  make devnet-stop      # 停止 devnet")
    print("  make interact-devnet  # 与合约交互")

if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        print("\n\n👋 示例中断")
    except Exception as e:
        print(f"\n❌ 示例失败: {e}")
