use starknet::ContractAddress;

pub trait ILendMod<TLendingProtocol, TToken> {
    fn deposit(self: TLendingProtocol, token: ContractAddress, amount: u256) -> u256;
    fn withdraw(self: TLendingProtocol, token: ContractAddress, amount: u256) -> u256;
    fn borrow(self: TLendingProtocol, token: ContractAddress, amount: u256) -> u256;
    fn repay(self: TLendingProtocol, token: ContractAddress, amount: u256) -> u256;
    fn health_factor(
        self: @TLendingProtocol,
        user: ContractAddress,
        deposits: Array<TToken>,
        borrows: Array<TToken>,
    ) -> u32;
    fn assert_valid(self: @TLendingProtocol);
    fn max_borrow_amount(
        self: @TLendingProtocol,
        deposit_token: TToken,
        deposit_amount: u256,
        borrow_token: TToken,
        min_hf: u32
    ) -> u256;
    fn min_borrow_required(self: @TLendingProtocol, token: ContractAddress) -> u256;
    fn get_repay_amount(self: @TLendingProtocol, token: ContractAddress, amount: u256) -> u256;
    fn deposit_amount(self: @TLendingProtocol, asset: ContractAddress, user: ContractAddress) -> u256;
    fn borrow_amount(self: @TLendingProtocol, asset: ContractAddress, user: ContractAddress) -> u256;
}

