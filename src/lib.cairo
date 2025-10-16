use starknet::ContractAddress;

#[starknet::interface]
pub trait IHelloWorld<TContractState> {
    fn get_greeting(self: @TContractState) -> felt252;
    fn set_greeting(ref self: TContractState, new_greeting: felt252);
    fn get_balance(self: @TContractState) -> u256;
    fn deposit(ref self: TContractState, amount: u256);
    fn withdraw(ref self: TContractState, amount: u256);
}

#[starknet::contract]
pub mod HelloWorld {
    use super::{IHelloWorld, IHelloWorldDispatcher, IHelloWorldDispatcherTrait};
    use starknet::{ContractAddress, get_caller_address, get_contract_address};

    #[storage]
    struct Storage {
        greeting: felt252,
        balance: u256,
        owner: ContractAddress,
    }

    #[constructor]
    fn constructor(ref self: ContractState, initial_greeting: felt252) {
        self.greeting.write(initial_greeting);
        self.balance.write(0);
        self.owner.write(get_contract_address());
    }

    #[abi(embed_v0)]
    impl HelloWorldImpl of IHelloWorld<ContractState> {
        fn get_greeting(self: @ContractState) -> felt252 {
            self.greeting.read()
        }

        fn set_greeting(ref self: ContractState, new_greeting: felt252) {
            self.greeting.write(new_greeting);
        }

        fn get_balance(self: @ContractState) -> u256 {
            self.balance.read()
        }

        fn deposit(ref self: ContractState, amount: u256) {
            let current_balance = self.balance.read();
            self.balance.write(current_balance + amount);
        }

        fn withdraw(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            let owner = self.owner.read();
            assert(caller == owner, 'Only owner can withdraw');
            
            let current_balance = self.balance.read();
            assert(current_balance >= amount, 'Insufficient balance');
            
            self.balance.write(current_balance - amount);
        }
    }
}
