// 主模块入口文件
// 这里声明的模块会被编译

// 组件模块 (helpers, vesu integration, oracle 等)
pub mod components;

// 配置模块 (合约地址等)
pub mod config;

// 主要合约模块 (aBTC, yield 等)
pub mod mods;

// 测试模块 (开发时使用)
#[cfg(test)]
pub mod tests;

