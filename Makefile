# Starknet Cairo 项目 Makefile

.PHONY: help build test clean deploy-local deploy-testnet deploy-devnet interact devnet-start devnet-stop devnet-status

# 默认目标
help:
	@echo "🌟 Starknet Cairo 项目命令"
	@echo "================================"
	@echo "build          - 构建项目"
	@echo "test           - 运行测试"
	@echo "clean          - 清理构建文件"
	@echo "deploy-devnet  - 部署到 starknet-devnet"
	@echo "devnet-start   - 启动 starknet-devnet"
	@echo "devnet-stop    - 停止 starknet-devnet"
	@echo "devnet-status  - 检查 devnet 状态"
	@echo "setup          - 设置开发环境"

# 构建项目
build:
	@echo "📦 构建 Cairo 合约..."
	scarb build

# 运行测试
test:
	@echo "🧪 运行测试..."
	scarb test

# 清理构建文件
clean:
	@echo "🧹 清理构建文件..."
	rm -rf target/

# 部署到 starknet-devnet
deploy-devnet:
	@echo "🚀 部署到 starknet-devnet..."
	python3 scripts/devnet_deploy.py

# 启动 starknet-devnet
devnet-start:
	@echo "🚀 启动 starknet-devnet..."
	starknet-devnet --host 127.0.0.1 --port 5050 --seed 42 --accounts 10 --initial-balance 1000000000000000000000

# 停止 starknet-devnet
devnet-stop:
	@echo "🛑 停止 starknet-devnet..."
	pkill -f starknet-devnet || echo "Devnet 未运行"

# 检查 devnet 状态
devnet-status:
	@echo "🔍 检查 devnet 状态..."
	@curl -s http://127.0.0.1:5050/is_alive > /dev/null && echo "✅ Devnet 正在运行" || echo "❌ Devnet 未运行"

# 与 devnet 合约交互
interact-devnet:
	@echo "🔗 启动 devnet 合约交互工具..."
	python3 scripts/devnet_interact.py

# 设置开发环境
setup:
	@echo "⚙️  设置开发环境..."
	@echo "请确保已安装以下工具:"
	@echo "1. Scarb: https://docs.swmansion.com/scarb/"
	@echo "2. Python 3.7+"
	@echo "3. starknet-devnet: pip install starknet-devnet"
	@echo ""
	@echo "安装完成后运行: make build"
