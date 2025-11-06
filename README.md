# 🌟 Delta-Neutral BTC Vault - Starknet Cairo 智能合约项目

这是一个基于Starknet的Delta-Neutral BTC Vault智能合约项目，实现了无价格风险的BTC收益策略。

## 📋 项目特性

- ✅ Delta-Neutral BTC Vault合约
- ✅ WBTC存款和代币化功能
- ✅ 永续合约多头/空头头寸管理
- ✅ 自动再平衡机制
- ✅ 资金费率收益收集
- ✅ 完整的测试套件
- ✅ 自动化部署脚本
- ✅ 合约交互工具
- ✅ 本地和测试网部署支持

## 🚀 快速开始

### 环境要求

1. **Scarb** - Cairo包管理器
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
   ```

2. **Starknet CLI** - Starknet命令行工具
   ```bash
   # 安装方法请参考: https://docs.starknet.io/documentation/getting-started/quick-start/
   ```

3. **Python 3.7+** - 用于部署脚本

### 安装和构建

```bash
# 克隆项目
git clone <your-repo-url>
cd friendly-lamp

# 构建项目
make build

# 运行测试
make test
```

## 📁 项目结构

```
friendly-lamp/
├── src/
│   └── lib.cairo              # 主合约代码
├── tests/
│   └── test_hello_world.cairo # 测试文件
├── scripts/
│   ├── deploy.py              # 部署脚本
│   └── interact.py            # 交互脚本
├── Scarb.toml                 # 项目配置
├── Makefile                   # 构建命令
└── README.md                  # 项目文档
```

## 🔧 合约功能

### Delta-Neutral BTC Vault 合约

这是一个创新的DeFi产品，实现Delta-Neutral策略来为BTC持有者提供无价格风险的收益：

- **WBTC存款**: 用户存入WBTC获得dnBTC代币
- **Delta-Neutral策略**: 同时建立多头和空头头寸消除价格风险
- **自动再平衡**: 监控并调整头寸保持Delta中性
- **收益收集**: 从永续合约资金费率中获得收益
- **代币化**: 发行dnBTC代币代表用户份额

### 核心策略

```
用户存入 WBTC
    ↓
Vault 建立头寸：
- 用WBTC作为抵押品开多头
- 同时开相同大小的空头
- 净敞口 = 0 (Delta-Neutral)
    ↓
收益来源：
- 永续合约资金费率
- 无价格风险
```

### 合约接口

```cairo
#[starknet::interface]
pub trait IDeltaNeutralBTCVault<TContractState> {
    // 存款和取款
    fn deposit_wbtc(ref self: TContractState, amount: u256) -> u256;
    fn withdraw_wbtc(ref self: TContractState, dnbtc_amount: u256) -> u256;
    
    // 代币化功能
    fn get_dnbtc_balance(self: @TContractState, user: ContractAddress) -> u256;
    fn get_total_dnbtc_supply(self: @TContractState) -> u256;
    fn get_total_wbtc_deposited(self: @TContractState) -> u256;
    
    // 头寸管理
    fn get_long_position_size(self: @TContractState) -> u256;
    fn get_short_position_size(self: @TContractState) -> u256;
    fn get_net_delta(self: @TContractState) -> u256;
    
    // 收益管理
    fn get_accumulated_funding(self: @TContractState) -> u256;
    fn harvest_funding(ref self: TContractState);
    
    // 再平衡
    fn rebalance_positions(ref self: TContractState);
    
    // 管理员功能
    fn set_perps_dex_address(ref self: TContractState, dex_address: ContractAddress);
    fn set_wbtc_address(ref self: TContractState, wbtc_address: ContractAddress);
    fn emergency_withdraw(ref self: TContractState);
}
```

## 🧪 测试

项目包含完整的测试套件，覆盖所有合约功能：

```bash
# 运行所有测试
make test

# 或者使用 scarb 直接运行
scarb test
```

### 测试用例

- ✅ WBTC存款功能
- ✅ dnBTC代币化
- ✅ Delta-Neutral头寸建立
- ✅ 资金费率收益收集
- ✅ 自动再平衡机制
- ✅ 提取功能
- ✅ 权限控制测试
- ✅ 余额不足测试

## 🚀 部署

### 本地部署（推荐用于开发）

```bash
# 启动本地节点
starknet node --host 127.0.0.1 --port 5050

# 部署到本地
make deploy-local
```

### 测试网部署

```bash
# 确保已配置测试网账户
starknet account new

# 部署到测试网
make deploy-testnet
```

### 使用部署脚本

```bash
# 交互式部署
python scripts/deploy.py
```

## 🔗 与合约交互

部署完成后，可以使用交互脚本与合约交互：

```bash
# 启动交互工具
make interact

# 或者直接运行
python scripts/interact.py
```

### 交互功能

- 💰 WBTC存款和提取
- 🪙 dnBTC代币查询
- 📊 头寸大小查询
- ⚖️ Delta状态监控
- 💸 资金费率收益收集
- 🔄 头寸再平衡
- 🔐 管理员功能

## 📚 开发指南

### 添加新功能

1. 在 `src/lib.cairo` 中添加新的合约函数
2. 更新接口定义
3. 在 `tests/test_hello_world.cairo` 中添加测试
4. 运行测试确保功能正常

### 代码结构

```cairo
#[starknet::contract]
pub mod HelloWorld {
    // 存储结构
    #[storage]
    struct Storage {
        // 状态变量
    }
    
    // 构造函数
    #[constructor]
    fn constructor(ref self: ContractState) {
        // 初始化逻辑
    }
    
    // 合约实现
    #[abi(embed_v0)]
    impl HelloWorldImpl of IHelloWorld<ContractState> {
        // 合约函数
    }
}
```

## 🛠️ 常用命令

```bash
# 构建项目
make build

# 运行测试
make test

# 清理构建文件
make clean

# 部署到本地
make deploy-local

# 部署到测试网
make deploy-testnet

# 与合约交互
make interact

# 查看帮助
make help
```

## 🔍 调试技巧

### 使用Starknet CLI调试

```bash
# 查看合约状态
starknet get_contract_address --address <CONTRACT_ADDRESS>

# 调用只读函数
starknet call --address <CONTRACT_ADDRESS> --function get_greeting

# 调用写入函数
starknet invoke --address <CONTRACT_ADDRESS> --function set_greeting --inputs "Hello World"
```

### 常见问题

1. **编译错误**: 检查Cairo语法和依赖
2. **部署失败**: 确保网络连接和账户配置正确
3. **调用失败**: 检查函数参数和权限

## 📖 学习资源

- [Cairo Book](https://book.cairo-lang.org/)
- [Starknet Documentation](https://docs.starknet.io/)
- [OpenZeppelin Cairo Contracts](https://github.com/OpenZeppelin/cairo-contracts)

## 🤝 贡献

欢迎提交Issue和Pull Request来改进这个项目！

## 📄 许可证

MIT License
