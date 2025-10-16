# 🚀 快速开始指南

## 5分钟快速体验Starknet Cairo合约开发

### 第一步：环境准备

1. **安装Scarb（Cairo包管理器）**
   ```bash
   curl --proto '=https' --tlsv1.2 -sSf https://docs.swmansion.com/scarb/install.sh | sh
   ```

2. **安装Starknet CLI**
   ```bash
   # 参考官方文档: https://docs.starknet.io/documentation/getting-started/quick-start/
   ```

3. **验证安装**
   ```bash
   scarb --version
   starknet --version
   ```

### 第二步：构建和测试

```bash
# 构建项目
make build

# 运行测试
make test
```

如果一切正常，你应该看到类似输出：
```
✅ 构建成功
✅ 测试通过
```

### 第三步：本地部署

1. **启动本地节点**
   ```bash
   starknet node --host 127.0.0.1 --port 5050
   ```

2. **部署合约**
   ```bash
   make deploy-local
   ```

3. **记录合约地址**
   部署成功后，会显示合约地址，类似：
   ```
   🎉 本地合约地址: 0x1234567890abcdef...
   ```

### 第四步：与合约交互

```bash
# 启动交互工具
make interact
```

在交互工具中，你可以：
- 获取问候语
- 设置新的问候语
- 查看余额
- 存款和提取

### 第五步：测试网部署（可选）

1. **创建测试网账户**
   ```bash
   starknet account new
   ```

2. **获取测试网代币**
   - 访问 [Starknet Faucet](https://faucet.goerli.starknet.io/)
   - 获取测试网代币

3. **部署到测试网**
   ```bash
   make deploy-testnet
   ```

## 🎯 下一步

- 查看 [README.md](README.md) 了解完整功能
- 修改 `src/lib.cairo` 添加新功能
- 在 `tests/test_hello_world.cairo` 中添加测试
- 探索 [Cairo Book](https://book.cairo-lang.org/) 学习更多

## ❓ 遇到问题？

1. **构建失败**: 检查Scarb版本和依赖
2. **测试失败**: 查看测试输出，检查合约逻辑
3. **部署失败**: 确保本地节点运行或网络连接正常
4. **交互失败**: 检查合约地址和函数参数

## 🎉 恭喜！

你已经成功完成了Starknet Cairo智能合约的完整开发流程！
