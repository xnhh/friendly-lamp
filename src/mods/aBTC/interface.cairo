use starknet::ContractAddress;

#[starknet::interface]
pub trait IABTC<TState> {
    // Mint function - only callable by vault
    fn mint(ref self: TState, recipient: ContractAddress, amount: u256);
    
    // Burn function - only callable by vault  
    fn burn(ref self: TState, account: ContractAddress, amount: u256);
}

#[starknet::interface]
pub trait IABTCView<TState> {
    // ERC20 view functions
    fn name(self: @TState) -> ByteArray;
    fn symbol(self: @TState) -> ByteArray;
    fn decimals(self: @TState) -> u8;
    fn total_supply(self: @TState) -> u256;
    fn balance_of(self: @TState, account: ContractAddress) -> u256;
    fn allowance(self: @TState, owner: ContractAddress, spender: ContractAddress) -> u256;
    
    // aBTC specific view functions
    fn get_vault_address(self: @TState) -> ContractAddress;
}

#[starknet::interface]
pub trait IABTCOwner<TState> {
    // Ownable functions
    fn owner(self: @TState) -> ContractAddress;
    fn transfer_ownership(ref self: TState, new_owner: ContractAddress);
    fn renounce_ownership(ref self: TState);
    
    // Vault management
    fn update_vault_address(ref self: TState, new_vault: ContractAddress);
}

#[starknet::interface]
pub trait IABTCERC20<TState> {
    // ERC20 external functions
    fn transfer(ref self: TState, recipient: ContractAddress, amount: u256) -> bool;
    fn transfer_from(
        ref self: TState, 
        sender: ContractAddress, 
        recipient: ContractAddress, 
        amount: u256
    ) -> bool;
    fn approve(ref self: TState, spender: ContractAddress, amount: u256) -> bool;
}
