use starknet::ContractAddress;

// Custom mint/burn interface - only vault can call these
#[starknet::interface]
pub trait IABTC<TState> {
    fn mint(ref self: TState, recipient: ContractAddress, amount: u256);
    fn burn(ref self: TState, account: ContractAddress, amount: u256);
}

// Vault address management interface
#[starknet::interface]
pub trait IABTCVault<TState> {
    fn get_vault_address(self: @TState) -> ContractAddress;
    fn update_vault_address(ref self: TState, new_vault: ContractAddress);
}

// Note: ERC20 functions (name, symbol, decimals, total_supply, balance_of, 
// allowance, transfer, transfer_from, approve) are provided by 
// OpenZeppelin's ERC20MixinImpl

// Note: Ownable functions (owner, transfer_ownership, renounce_ownership)
// are provided by OpenZeppelin's OwnableMixinImpl
