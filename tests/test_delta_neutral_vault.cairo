use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};
use starknet::deploy_syscall;
use core::array::ArrayTrait;
use friendly_lamp::DeltaNeutralBTCVault;
use friendly_lamp::IDeltaNeutralBTCVaultDispatcher;
use friendly_lamp::IDeltaNeutralBTCVaultDispatcherTrait;

fn deploy_vault() -> (IDeltaNeutralBTCVaultDispatcher, ContractAddress) {
    let dex_address: ContractAddress = 1.try_into().unwrap();
    let wbtc_address: ContractAddress = 2.try_into().unwrap();
    let (contract_address, _) = deploy_syscall(
        DeltaNeutralBTCVault::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        array![
            dex_address.into(),
            wbtc_address.into(),
            100.into(),  // rebalance_threshold
            2000000000000000000000.into()  // max_leverage
        ]
        .span(),
        false,
    )
    .unwrap();
    let vault = IDeltaNeutralBTCVaultDispatcher { contract_address };
    (vault, contract_address)
}

#[test]
fn test_deposit_wbtc() {
    let (mut vault, contract_address) = deploy_vault();
    let user_address: ContractAddress = 3.try_into().unwrap();
    
    set_contract_address(contract_address);
    set_caller_address(user_address);
    
    // 测试存款
    let deposit_amount = 1000000000000000000; // 1 WBTC
    let dnbtc_minted = vault.deposit_wbtc(deposit_amount);
    
    // 验证状态
    assert(dnbtc_minted == deposit_amount, 'First deposit should be 1:1');
    assert(vault.get_total_dnbtc_supply() == deposit_amount, 'Total supply should match deposit');
    assert(vault.get_total_wbtc_deposited() == deposit_amount, 'Total deposited should match');
    assert(vault.get_dnbtc_balance(user_address) == deposit_amount, 'User balance should match');
}

#[test]
fn test_delta_neutral_positions() {
    let (mut vault, contract_address) = deploy_vault();
    let user_address: ContractAddress = 3.try_into().unwrap();
    
    set_contract_address(contract_address);
    set_caller_address(user_address);
    
    let deposit_amount = 1000000000000000000;
    vault.deposit_wbtc(deposit_amount);
    
    // 验证Delta-Neutral头寸
    let long_size = vault.get_long_position_size();
    let short_size = vault.get_short_position_size();
    let net_delta = vault.get_net_delta();
    
    assert(long_size == deposit_amount, 'Long position should match deposit');
    assert(short_size == deposit_amount, 'Short position should match deposit');
    assert(net_delta == 0, 'Net delta should be 0 for delta-neutral');
}

#[test]
fn test_funding_harvest() {
    let (mut vault, contract_address) = deploy_vault();
    let user_address: ContractAddress = 3.try_into().unwrap();
    
    set_contract_address(contract_address);
    set_caller_address(user_address);
    
    // 初始资金费率为0
    assert(vault.get_accumulated_funding() == 0, 'Initial funding should be 0');
    
    // 收集资金费率
    vault.harvest_funding();
    
    // 验证资金费率增加
    assert(vault.get_accumulated_funding() > 0, 'Funding should increase after harvest');
}

#[test]
fn test_rebalancing() {
    let (mut vault, contract_address) = deploy_vault();
    let user_address: ContractAddress = 3.try_into().unwrap();
    
    set_contract_address(contract_address);
    set_caller_address(user_address);
    
    let deposit_amount = 1000000000000000000;
    vault.deposit_wbtc(deposit_amount);
    
    // 初始状态应该是Delta-Neutral
    assert(vault.get_net_delta() == 0, 'Initial state should be delta-neutral');
    
    // 执行再平衡
    vault.rebalance_positions();
    
    // 再平衡后应该仍然是Delta-Neutral
    assert(vault.get_net_delta() == 0, 'After rebalancing should be delta-neutral');
}

#[test]
fn test_withdrawal() {
    let (mut vault, contract_address) = deploy_vault();
    let user_address: ContractAddress = 3.try_into().unwrap();
    
    set_contract_address(contract_address);
    set_caller_address(user_address);
    
    let deposit_amount = 1000000000000000000;
    let dnbtc_minted = vault.deposit_wbtc(deposit_amount);
    
    // 提取一半
    let withdraw_amount = dnbtc_minted / 2;
    let wbtc_withdrawn = vault.withdraw_wbtc(withdraw_amount);
    
    // 验证提取
    assert(wbtc_withdrawn == deposit_amount / 2, 'Withdrawn amount should be half');
    assert(vault.get_dnbtc_balance(user_address) == dnbtc_minted - withdraw_amount, 'User balance should decrease');
    assert(vault.get_total_dnbtc_supply() == dnbtc_minted - withdraw_amount, 'Total supply should decrease');
}

