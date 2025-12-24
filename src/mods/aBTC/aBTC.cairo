use starknet::ContractAddress;

#[starknet::contract]
mod aBTC {
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use starknet::storage::{StoragePointerReadAccess, StoragePointerWriteAccess};
    use openzeppelin::token::erc20::ERC20Component;
    use openzeppelin::token::erc20::ERC20Component::InternalTrait as ERC20InternalTrait;
    use openzeppelin::token::erc20::ERC20HooksEmptyImpl;
    use openzeppelin::access::ownable::OwnableComponent;
    use openzeppelin::access::ownable::OwnableComponent::InternalTrait as OwnableInternalTrait;
    use friendly_lamp::mods::aBTC::interface::{IABTC, IABTCVault};

    component!(path: ERC20Component, storage: erc20, event: ERC20Event);
    component!(path: OwnableComponent, storage: ownable, event: OwnableEvent);

    // ERC20 Mixin - provides all ERC20 functions
    #[abi(embed_v0)]
    impl ERC20MixinImpl = ERC20Component::ERC20MixinImpl<ContractState>;
    impl ERC20InternalImpl = ERC20Component::InternalImpl<ContractState>;

    // Ownable Mixin - provides owner(), transfer_ownership(), renounce_ownership()
    #[abi(embed_v0)]
    impl OwnableMixinImpl = OwnableComponent::OwnableMixinImpl<ContractState>;
    impl OwnableInternalImpl = OwnableComponent::InternalImpl<ContractState>;

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
        #[flat]
        ERC20Event: ERC20Component::Event,
        #[flat]
        OwnableEvent: OwnableComponent::Event,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_owner: ContractAddress,
        vault_address: ContractAddress,
    ) {
        self.erc20.initializer("aBTC", "aBTC");
        self.ownable.initializer(initial_owner);
        self.vault_address.write(vault_address);
    }

    // Custom mint/burn functions - only vault can call
    #[abi(embed_v0)]
    impl IABTCImpl of IABTC<ContractState> {
        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            let vault = self.vault_address.read();
            assert(caller == vault, 'aBTC: Only vault can mint');
            self.erc20.mint(recipient, amount);
        }

        fn burn(ref self: ContractState, account: ContractAddress, amount: u256) {
            let caller = get_caller_address();
            let vault = self.vault_address.read();
            assert(caller == vault, 'aBTC: Only vault can burn');
            self.erc20.burn(account, amount);
        }
    }

    // Vault address management
    #[abi(embed_v0)]
    impl IABTCVaultImpl of IABTCVault<ContractState> {
        fn get_vault_address(self: @ContractState) -> ContractAddress {
            self.vault_address.read()
        }

        fn update_vault_address(ref self: ContractState, new_vault: ContractAddress) {
            self.ownable.assert_only_owner();
            self.vault_address.write(new_vault);
        }
    }
}
