use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address, set_block_timestamp, set_block_number};
use starknet::deploy_syscall;
use core::array::ArrayTrait;
use friendly_lamp::{IHelloWorldDispatcher, IHelloWorldDispatcherTrait, HelloWorld};

fn deploy_hello_world() -> (IHelloWorldDispatcher, ContractAddress) {
    let initial_greeting = 'Hello, Starknet!';
    let (contract_address, _) = deploy_syscall(
        HelloWorld::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        array![initial_greeting].span(),
        false
    ).unwrap();
    let contract = IHelloWorldDispatcher { contract_address };
    (contract, contract_address)
}

#[test]
fn test_get_greeting() {
    let (contract, _) = deploy_hello_world();
    let greeting = contract.get_greeting();
    assert(greeting == 'Hello, Starknet!', 'Wrong greeting');
}

#[test]
fn test_set_greeting() {
    let (contract, _) = deploy_hello_world();
    let new_greeting = 'Hello, Cairo!';
    contract.set_greeting(new_greeting);
    let greeting = contract.get_greeting();
    assert(greeting == new_greeting, 'Greeting not updated');
}

#[test]
fn test_deposit() {
    let (contract, _) = deploy_hello_world();
    let deposit_amount = 1000;
    contract.deposit(deposit_amount);
    let balance = contract.get_balance();
    assert(balance == deposit_amount, 'Balance not updated');
}

#[test]
fn test_withdraw() {
    let (contract, contract_address) = deploy_hello_world();
    let deposit_amount = 1000;
    let withdraw_amount = 300;
    
    // 先存款
    contract.deposit(deposit_amount);
    
    // 设置调用者为合约所有者（合约地址）
    set_caller_address(contract_address);
    set_contract_address(contract_address);
    
    // 提取
    contract.withdraw(withdraw_amount);
    
    let balance = contract.get_balance();
    assert(balance == deposit_amount - withdraw_amount, 'Withdrawal failed');
}

#[test]
#[should_panic]
fn test_withdraw_not_owner() {
    let (contract, _) = deploy_hello_world();
    let deposit_amount = 1000;
    let withdraw_amount = 300;
    
    // 先存款
    contract.deposit(deposit_amount);
    
    // 设置不同的调用者地址
    let different_address: ContractAddress = 12345.try_into().unwrap();
    set_caller_address(different_address);
    
    // 尝试提取（应该失败）
    contract.withdraw(withdraw_amount);
}

#[test]
#[should_panic]
fn test_withdraw_insufficient_balance() {
    let (contract, contract_address) = deploy_hello_world();
    let deposit_amount = 100;
    let withdraw_amount = 200;
    
    // 先存款
    contract.deposit(deposit_amount);
    
    // 设置调用者为合约所有者
    set_caller_address(contract_address);
    set_contract_address(contract_address);
    
    // 尝试提取超过余额的金额（应该失败）
    contract.withdraw(withdraw_amount);
}
