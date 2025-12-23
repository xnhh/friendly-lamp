use starknet::ContractAddress;

#[starknet::interface]
pub trait IYield<TState> {
    // Deposit functions
    fn deposit(ref self: TState amount: u256);
    fn withdraw(ref self: TState amount: u256);

    // Borrow/repay functions
    fn borrow(ref self: TState amount: u256);
    fn repay(ref self: TState amount: u256);
    // Harvest function
    fn harvest(ref self: TState);

    // Liquidation
    fn liquidate(ref self: TState user: ContractAddress debt_to_cover: u256);
}

#[starknet::interface]
pub trait IYieldView<TState> {
    // User info
    fn get_user_info(self: @TState user: ContractAddress) -> UserInfo;

    // Global state
    fn get_total_wbtc_deposited(self: @TState) -> u256;
    fn get_total_shares(self: @TState) -> u256;
    fn get_total_abtc_borrowed(self: @TState) -> u256;

    // Token addresses
    fn get_wbtc_token(self: @TState) -> ContractAddress;
    fn get_abtc_token(self: @TState) -> ContractAddress;

    // Price
    fn get_price(self: @TState) -> u256;

    // Calculation functions
    fn calculate_shares(self: @TState wbtc_amount: u256) -> u256;
    fn shares_to_wbtc(self: @TState shares: u256) -> u256;
    fn calculate_collateral_ratio(self: @TState collateral_wbtc: u256 borrowed_abtc: u256) -> u256;
    fn calculate_required_collateral(self: @TState borrow_amount: u256) -> u256;
    fn calculate_liquidation_collateral(self: @TState debt_amount: u256) -> u256;
}

#[starknet::interface]
pub trait IYieldOwner<TState> {
    // Ownable functions
    fn owner(self: @TState) -> ContractAddress;
    fn transfer_ownership(ref self: TState new_owner: ContractAddress);
    fn renounce_ownership(ref self: TState);

    // Settings management
    fn update_price(ref self: TState new_price: u256);
    fn update_min_collateral_ratio(ref self: TState new_ratio: u256);
    fn update_liquidation_threshold(ref self: TState new_threshold: u256);
    fn update_liquidation_bonus(ref self: TState new_bonus: u256);
}

#[derive(Drop Copy Serde starknet::Store)]
pub struct UserInfo {
    deposited_wbtc: u256
    shares: u256
    borrowed_abtc: u256
}