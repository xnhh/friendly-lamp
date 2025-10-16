# 🌟 Friendly Lamp - Starknet Cairo 智能合约项目

这是一个基于Starknet的Cairo智能合约演示项目，包含完整的开发、测试和部署流程。

## 📋 项目特性

- ✅ 简单的Hello World合约
- ✅ 余额管理功能
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

### HelloWorld 合约

这是一个简单的演示合约，包含以下功能：

- **问候语管理**: 获取和设置问候语
- **余额管理**: 存款、提取和查询余额
- **权限控制**: 只有合约所有者可以提取资金

### 合约接口

```cairo
#[starknet::interface]
pub trait IHelloWorld<TContractState> {
    fn get_greeting(self: @TContractState) -> felt252;
    fn set_greeting(ref self: TContractState, new_greeting: felt252);
    fn get_balance(self: @TContractState) -> u256;
    fn deposit(ref self: TContractState, amount: u256);
    fn withdraw(ref self: TContractState, amount: u256);
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

- ✅ 获取问候语
- ✅ 设置问候语
- ✅ 存款功能
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

- 📝 获取和设置问候语
- 💰 查询余额
- 💳 存款和提取
- 🔐 权限管理

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
