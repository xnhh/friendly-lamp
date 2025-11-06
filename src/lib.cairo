use starknet::ContractAddress;

pub mod components;
pub mod mods;
pub mod config;

// Delta-Neutral BTC Vault Interface
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

#[starknet::contract]
pub mod DeltaNeutralBTCVault {
    use super::{IDeltaNeutralBTCVault, IDeltaNeutralBTCVaultDispatcher, IDeltaNeutralBTCVaultDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    #[storage]
    struct Storage {
        // 代币化相关 - 简化实现，只支持单个用户
        user_dnbtc_balance: u256,
        total_dnbtc_supply: u256,
        total_wbtc_deposited: u256,
        
        // 头寸管理
        long_position_size: u256,
        short_position_size: u256,
        long_position_id: u256,
        short_position_id: u256,
        
        // 收益管理
        accumulated_funding: u256,
        last_funding_harvest: u64,
        
        // 外部合约地址
        perps_dex_address: ContractAddress,
        wbtc_address: ContractAddress,
        
        // 管理员
        owner: ContractAddress,
        is_emergency_stopped: bool,
        
        // 配置参数
        rebalance_threshold: u256, // 再平衡阈值 (1% = 100)
        max_leverage: u256,        // 最大杠杆倍数
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        perps_dex_address: ContractAddress,
        wbtc_address: ContractAddress,
        rebalance_threshold: u256,
        max_leverage: u256
    ) {
        // 初始化代币化相关
        self.user_dnbtc_balance.write(0);
        self.total_dnbtc_supply.write(0);
        self.total_wbtc_deposited.write(0);
        
        // 初始化头寸管理
        self.long_position_size.write(0);
        self.short_position_size.write(0);
        self.long_position_id.write(0);
        self.short_position_id.write(0);
        
        // 初始化收益管理
        self.accumulated_funding.write(0);
        self.last_funding_harvest.write(0);
        
        // 设置外部合约地址
        self.perps_dex_address.write(perps_dex_address);
        self.wbtc_address.write(wbtc_address);
        
        // 设置管理员
        self.owner.write(get_caller_address());
        self.is_emergency_stopped.write(false);
        
        // 设置配置参数
        self.rebalance_threshold.write(rebalance_threshold);
        self.max_leverage.write(max_leverage);
    }

    #[abi(embed_v0)]
    impl DeltaNeutralBTCVaultImpl of IDeltaNeutralBTCVault<ContractState> {
        // 存款功能
        fn deposit_wbtc(ref self: ContractState, amount: u256) -> u256 {
            assert(!self.is_emergency_stopped.read(), 'Vault is emergency stopped');
            assert(amount > 0, 'Amount must be positive');
            
            let total_supply = self.total_dnbtc_supply.read();
            let total_deposited = self.total_wbtc_deposited.read();
            
            // 计算应该铸造的dnBTC数量
            let dnbtc_to_mint = if total_supply == 0 {
                amount // 第一次存款，1:1比例
            } else {
                (amount * total_supply) / total_deposited
            };
            
            // 更新状态
            self.total_wbtc_deposited.write(total_deposited + amount);
            self.total_dnbtc_supply.write(total_supply + dnbtc_to_mint);
            self.user_dnbtc_balance.write(self.user_dnbtc_balance.read() + dnbtc_to_mint);
            
            // 建立Delta-Neutral头寸
            self._open_delta_neutral_positions(amount);
            
            dnbtc_to_mint
        }
        
        // 取款功能
        fn withdraw_wbtc(ref self: ContractState, dnbtc_amount: u256) -> u256 {
            assert(!self.is_emergency_stopped.read(), 'Vault is emergency stopped');
            assert(dnbtc_amount > 0, 'Amount must be positive');
            
            let user_balance = self.user_dnbtc_balance.read();
            assert(user_balance >= dnbtc_amount, 'Insufficient dnBTC balance');
            
            let total_supply = self.total_dnbtc_supply.read();
            let total_deposited = self.total_wbtc_deposited.read();
            
            // 计算应该提取的WBTC数量
            let wbtc_to_withdraw = (dnbtc_amount * total_deposited) / total_supply;
            
            // 更新状态
            self.user_dnbtc_balance.write(user_balance - dnbtc_amount);
            self.total_dnbtc_supply.write(total_supply - dnbtc_amount);
            self.total_wbtc_deposited.write(total_deposited - wbtc_to_withdraw);
            
            // 关闭相应的头寸
            self._close_delta_neutral_positions(wbtc_to_withdraw);
            
            wbtc_to_withdraw
        }
        
        // 代币化功能
        fn get_dnbtc_balance(self: @ContractState, user: ContractAddress) -> u256 {
            self.user_dnbtc_balance.read()
        }
        
        fn get_total_dnbtc_supply(self: @ContractState) -> u256 {
            self.total_dnbtc_supply.read()
        }
        
        fn get_total_wbtc_deposited(self: @ContractState) -> u256 {
            self.total_wbtc_deposited.read()
        }
        
        // 头寸管理
        fn get_long_position_size(self: @ContractState) -> u256 {
            self.long_position_size.read()
        }
        
        fn get_short_position_size(self: @ContractState) -> u256 {
            self.short_position_size.read()
        }
        
        fn get_net_delta(self: @ContractState) -> u256 {
            let long_size = self.long_position_size.read();
            let short_size = self.short_position_size.read();
            // 简化实现，返回差值
            if long_size > short_size {
                long_size - short_size
            } else {
                short_size - long_size
            }
        }
        
        // 收益管理
        fn get_accumulated_funding(self: @ContractState) -> u256 {
            self.accumulated_funding.read()
        }
        
        fn harvest_funding(ref self: ContractState) {
            // 这里应该调用永续合约DEX的接口来收集资金费率
            // 简化实现，假设每次调用都能收集到一些收益
            let current_funding = self.accumulated_funding.read();
            self.accumulated_funding.write(current_funding + 1000); // 示例收益
        }
        
        // 再平衡
        fn rebalance_positions(ref self: ContractState) {
            let net_delta = self.get_net_delta();
            let threshold = self.rebalance_threshold.read();
            
            // 如果Delta偏离超过阈值，进行再平衡
            if net_delta > threshold {
                self._rebalance_to_neutral();
            }
        }
        
        // 管理员功能
        fn set_perps_dex_address(ref self: ContractState, dex_address: ContractAddress) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Only owner can set DEX address');
            
            self.perps_dex_address.write(dex_address);
        }
        
        fn set_wbtc_address(ref self: ContractState, wbtc_address: ContractAddress) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Only owner can set WBTC address');
            
            self.wbtc_address.write(wbtc_address);
        }
        
        fn emergency_withdraw(ref self: ContractState) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Only owner');
            
            self.is_emergency_stopped.write(true);
            // 关闭所有头寸
            self._close_all_positions();
        }
    }
    
    // 内部函数
    impl InternalImpl of InternalTrait<ContractState> {
        fn _open_delta_neutral_positions(ref self: ContractState, amount: u256) {
            // 使用WBTC作为抵押品开多头
            let long_size = self.long_position_size.read();
            self.long_position_size.write(long_size + amount);
            
            // 开相同大小的空头
            let short_size = self.short_position_size.read();
            self.short_position_size.write(short_size + amount);
            
            // 这里应该调用永续合约DEX的接口
            // 简化实现，只更新内部状态
        }
        
        fn _close_delta_neutral_positions(ref self: ContractState, amount: u256) {
            let long_size = self.long_position_size.read();
            let short_size = self.short_position_size.read();
            
            assert(long_size >= amount, 'Insufficient long position');
            assert(short_size >= amount, 'Insufficient short position');
            
            self.long_position_size.write(long_size - amount);
            self.short_position_size.write(short_size - amount);
        }
        
        fn _rebalance_to_neutral(ref self: ContractState) {
            let net_delta = self.get_net_delta();
            
            if net_delta != 0 {
                // 简化实现，重置头寸为0
                self.long_position_size.write(0);
                self.short_position_size.write(0);
            }
        }
        
        fn _close_all_positions(ref self: ContractState) {
            self.long_position_size.write(0);
            self.short_position_size.write(0);
            
            // 这里应该调用永续合约DEX的接口关闭所有头寸
        }
    }
    
    #[starknet::interface]
    trait InternalTrait<TContractState> {
        fn _open_delta_neutral_positions(ref self: TContractState, amount: u256);
        fn _close_delta_neutral_positions(ref self: TContractState, amount: u256);
        fn _rebalance_to_neutral(ref self: TContractState);
        fn _close_all_positions(ref self: TContractState);
    }
}