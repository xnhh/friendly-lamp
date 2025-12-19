use starknet::ContractAddress;
use starknet::get_caller_address;
use openzeppelin::token::erc20::ERC20Component;
use openzeppelin::access::ownable::OwnableComponent;
use super::interface::{IABTC, IABTCView, IABTCOwner, IABTCERC20};

#[starknet::contract]
mod aBTC {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::access::ownable::OwnableComponent;
    use super::interface::{IABTC, IABTCView, IABTCOwner, IABTCERC20};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc20: ERC20Component::Storage,
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,
        vault_address: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        ERC20Event: ERC20Component::Event,
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_owner: ContractAddress,
        vault_address: ContractAddress,
    ) {
        self.erc20.initializer("aBTC", "aBTC", 18);
        self.ownable.initializer(initial_owner);
        self.vault_address.write(vault_address);
    }

    #[external(v0)]
    impl IABTCImpl of IABTC<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            // Only vault can mint
            let caller = get_caller_address();
            let vault = self.vault_address.read();
            assert(caller == vault, "aBTC: Only vault can mint");
            
            self.erc20._mint(recipient, amount);
        }

        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            // Only vault can burn
            let caller = get_caller_address();
            let vault = self.vault_address.read();
            assert(caller == vault, "aBTC: Only vault can burn");
            
            self.erc20._burn(account, amount);
        }
    }

    #[external(v0)]
    impl IABTCViewImpl of IABTCView<ContractState> {
        fn name(self: @ContractState) -> felt252 {
            self.erc20.name()
        }

        fn symbol(self: @ContractState) -> felt252 {
            self.erc20.symbol()
        }

        fn decimals(self: @ContractState) -> u8 {
            self.erc20.decimals()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.erc20.total_supply()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            self.erc20.balance_of(account)
        }

        fn allowance(self: @ContractState, owner: ContractAddress, spender: ContractAddress) -> u256 {
            self.erc20.allowance(owner, spender)
        }

        fn get_vault_address(self: @ContractState) -> ContractAddress {
            self.vault_address.read()
        }
    }

    #[external(v0)]
    impl IABTCERC20Impl of IABTCERC20<ContractState> {
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            self.erc20.transfer(recipient, amount);
        }

        fn transfer_from(
            ref self: ContractState, sender: ContractAddress, recipient: ContractAddress, amount: u256
        ) {
            self.erc20.transfer_from(sender, recipient, amount);
        }

        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) {
            self.erc20.approve(spender, amount);
        }
    }

    #[external(v0)]
    impl IABTCOwnerImpl of IABTCOwner<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            self.ownable.owner()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            self.ownable.transfer_ownership(new_owner);
        }

        fn renounce_ownership(ref self: ContractState) {
            self.ownable.renounce_ownership();
        }

        fn update_vault_address(ref self: ContractState, new_vault: ContractAddress) {
            self.ownable.assert_only_owner();
            self.vault_address.write(new_vault);
        }
    }
}
