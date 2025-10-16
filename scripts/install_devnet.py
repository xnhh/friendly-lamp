#!/usr/bin/env python3
"""
安装 starknet-devnet 脚本
"""

import subprocess
import sys
import shutil

def run_command(command, description):
    """运行命令并处理错误"""
    print(f"🔄 {description}...")
    try:
        result = subprocess.run(command, shell=True, check=True, capture_output=True, text=True)
        print(f"✅ {description} 成功")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ {description} 失败: {e.stderr}")
        return False

def check_pip():
    """检查 pip 是否可用"""
    if shutil.which("pip3"):
        return "pip3"
    elif shutil.which("pip"):
        return "pip"
    else:
        return None

def check_pipx():
    """检查 pipx 是否可用"""
    return shutil.which("pipx") is not None

def install_devnet():
    """安装 starknet-devnet"""
    print("🌟 安装 starknet-devnet")
    print("=" * 50)
    
    # 检查是否已经安装
    if shutil.which("starknet-devnet"):
        print("✅ starknet-devnet 已经安装")
        return True
    
    # 优先使用 pipx
    if check_pipx():
        print("📦 使用 pipx 安装 starknet-devnet...")
        if run_command("pipx install starknet-devnet", "使用 pipx 安装 starknet-devnet"):
            return True
    
    # 使用 pip 安装
    pip_cmd = check_pip()
    if pip_cmd:
        print(f"📦 使用 {pip_cmd} 安装 starknet-devnet...")
        if run_command(f"{pip_cmd} install starknet-devnet", f"使用 {pip_cmd} 安装 starknet-devnet"):
            return True
    
    print("❌ 无法安装 starknet-devnet")
    print("请手动安装:")
    print("  pip install starknet-devnet")
    print("  或者")
    print("  pipx install starknet-devnet")
    return False

def verify_installation():
    """验证安装"""
    print("\n🔍 验证安装...")
    try:
        result = subprocess.run(["starknet-devnet", "--version"], capture_output=True, text=True)
        if result.returncode == 0:
            print(f"✅ starknet-devnet 安装成功: {result.stdout.strip()}")
            return True
    except:
        pass
    
    print("❌ starknet-devnet 安装验证失败")
    return False

def main():
    """主函数"""
    if install_devnet():
        if verify_installation():
            print("\n🎉 starknet-devnet 安装完成!")
            print("\n下一步:")
            print("1. 运行 'make devnet-start' 启动 devnet")
            print("2. 运行 'make deploy-devnet' 部署合约")
            print("3. 运行 'make interact-devnet' 与合约交互")
        else:
            print("\n❌ 安装验证失败")
            sys.exit(1)
    else:
        print("\n❌ 安装失败")
        sys.exit(1)

if __name__ == "__main__":
    main()
