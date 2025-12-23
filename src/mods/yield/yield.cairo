use starknet::{ContractAddress, get_contract_address};
use starknet::get_caller_address;
use openzeppelin::token::erc20::interface::{IERC20Dispatcher, IERC20DispatcherTrait};
use openzeppelin::access::ownable::OwnableComponent;
use alexandria_math::u256::U256Math;
use core::num::traits::{Zero, Into};
use zeroable::Zeroable;
use friendly_lamp::components::helpers::{ERC20Helper, math};
use friendly_lamp::components::vesu::{vesuStruct, vesuToken};
use super::interface::{IYield, IYieldView, IYieldOwner, UserInfo};

// Constants
const WBTC_DECIMALS: u8 = 8;
const ABTC_DECIMALS: u8 = 18;
const DECIMAL_PRECISION: u256 = 1_000_000_000_000_000_000; // 1e18
const COLLATERAL_RATIO_PRECISION: u256 = 10_000; // 10000 = 100%

// Minimum collateral ratio (150%) - user must maintain 150% collateral
const MIN_COLLATERAL_RATIO: u256 = 15000;

// Liquidation threshold (120%) - position becomes liquidatable below this
const LIQUIDATION_THRESHOLD: u256 = 12000;

// Liquidation bonus (105%) - liquidator gets 5% bonus
const LIQUIDATION_BONUS: u256 = 10500;

#[starknet::contract]
mod Yield {
    use starknet::ContractAddress;
    use openzeppelin::access::ownable::OwnableComponent;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        ownable: OwnableComponent::Storage,

        // Token addresses
        wbtc_token: ContractAddress,
        abtc_token: ContractAddress,

        // Global state
        total_wbtc_deposited: u256,
        total_shares: u256,
        total_abtc_borrowed: u256,

        // User data
        user_info: LegacyMap<ContractAddress, UserInfo>,

        // Settings
        min_collateral_ratio: u256,
        liquidation_threshold: u256,
        liquidation_bonus: u256,

        // WBTC to aBTC price (1:1 initially can be updated by owner)
        wbtc_abtc_price: u256, // Price with 18 decimals

        // Vesu integration for yield harvesting
        vesu_singleton: ContractAddress,
        vesu_pool_id: felt252,
        vesu_collateral: ContractAddress,
        vesu_debt: ContractAddress,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        OwnableEvent: OwnableComponent::Event,
        Deposited: Deposited,
        Withdrawn: Withdrawn,
        Borrowed: Borrowed,
        Repaid: Repaid,
        Liquidated: Liquidated,
        Harvested: Harvested,
        PriceUpdated: PriceUpdated,
    }

    #[derive(Drop, starknet::Event)]
    struct Deposited {
        user: ContractAddress,
        amount: u256,
        shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Withdrawn {
        user: ContractAddress,
        amount: u256,
        shares: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Borrowed {
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Repaid {
        user: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Liquidated {
        liquidator: ContractAddress,
        user: ContractAddress,
        wbtc_amount: u256,
        abtc_amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct Harvested {
        total_yield: u256,
        new_total_deposited: u256,
    }

    #[derive(Drop, starknet::Event)]
    struct PriceUpdated {
        new_price: u256,
    }

    #[constructor]
    fn constructor(
        ref self: ContractState,
        initial_owner: ContractAddress,
        wbtc_token: ContractAddress,
        abtc_token: ContractAddress,
        vesu_singleton: ContractAddress,
        vesu_pool_id: felt252,
        vesu_collateral: ContractAddress,
        vesu_debt: ContractAddress,
    ) {
        self.ownable.initializer(initial_owner);
        self.wbtc_token.write(wbtc_token);
        self.abtc_token.write(abtc_token);
        self.min_collateral_ratio.write(MIN_COLLATERAL_RATIO);
        self.liquidation_threshold.write(LIQUIDATION_THRESHOLD);
        self.liquidation_bonus.write(LIQUIDATION_BONUS);
        self.wbtc_abtc_price.write(DECIMAL_PRECISION); // 1:1 price initially
        self.vesu_singleton.write(vesu_singleton);
        self.vesu_pool_id.write(vesu_pool_id);
        self.vesu_collateral.write(vesu_collateral);
        self.vesu_debt.write(vesu_debt);
    }

    #[external(v0)]
    impl IYieldImpl of IYield<ContractState> {
        fn deposit(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            assert(amount > 0, "Yield: Amount must be > 0");

            // Calculate shares to mint
            let shares = self.calculate_shares(amount);

            // Update user info
            let mut user_info = self.user_info.read(caller);
            user_info.deposited_wbtc += amount;
            user_info.shares += shares;
            self.user_info.write(caller, user_info);

            // Update global state
            self.total_wbtc_deposited.write(self.total_wbtc_deposited.read() + amount);
            self.total_shares.write(self.total_shares.read() + shares);

            // Transfer WBTC from user to contract
            let wbtc_dispatcher = IERC20Dispatcher { contract_address: self.wbtc_token.read() };
            wbtc_dispatcher.transferFrom(caller, get_contract_address(), amount);

            emit Deposited { user: caller, amount, shares };
        }

        fn withdraw(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            assert(amount > 0, "Yield: Amount must be > 0");

            let mut user_info = self.user_info.read(caller);
            assert(user_info.deposited_wbtc >= amount, "Yield: Insufficient deposited amount");

            // Check collateral ratio after withdrawal
            let shares_to_burn = self.shares_to_wbtc(amount);
            assert(user_info.shares >= shares_to_burn, "Yield: Insufficient shares");

            // Check if withdrawal would maintain healthy collateral ratio
            if (!user_info.borrowed_abtc.is_zero()) {
                let new_collateral = user_info.deposited_wbtc - amount;
                let new_ratio = self.calculate_collateral_ratio(new_collateral, user_info.borrowed_abtc);
                assert(new_ratio >= self.min_collateral_ratio.read(), "Yield: Withdrawal would cause undercollateralization");
            }

            // Update user info
            user_info.deposited_wbtc -= amount;
            user_info.shares -= shares_to_burn;
            self.user_info.write(caller, user_info);

            // Update global state
            self.total_wbtc_deposited.write(self.total_wbtc_deposited.read() - amount);
            self.total_shares.write(self.total_shares.read() - shares_to_burn);

            // Transfer WBTC from contract to user
            let wbtc_dispatcher = IERC20Dispatcher { contract_address: self.wbtc_token.read() };
            wbtc_dispatcher.transfer(caller, amount);

            emit Withdrawn { user: caller, amount, shares: shares_to_burn };
        }

        fn borrow(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            assert(amount > 0, "Yield: Amount must be > 0");

            let mut user_info = self.user_info.read(caller);

            // Calculate required collateral for this borrow
            let total_required = self.calculate_required_collateral(user_info.borrowed_abtc + amount);
            assert(user_info.deposited_wbtc >= total_required, "Yield: Insufficient collateral");

            // Update user info
            user_info.borrowed_abtc += amount;
            self.user_info.write(caller, user_info);

            // Update global state
            self.total_abtc_borrowed.write(self.total_abtc_borrowed.read() + amount);

            // Mint aBTC to user (assuming aBTC is our token with controlled mint)
            let abtc_dispatcher = IERC20Dispatcher { contract_address: self.abtc_token.read() };
            // Note: This would require aBTC contract to have mint functionality
            // abtc_dispatcher.mint(caller, amount);

            emit Borrowed { user: caller, amount };
        }

        fn repay(ref self: ContractState, amount: u256) {
            let caller = get_caller_address();
            assert(amount > 0, "Yield: Amount must be > 0");

            let mut user_info = self.user_info.read(caller);
            assert(user_info.borrowed_abtc >= amount, "Yield: Repaying more than borrowed");

            // Update user info
            user_info.borrowed_abtc -= amount;
            self.user_info.write(caller, user_info);

            // Update global state
            self.total_abtc_borrowed.write(self.total_abtc_borrowed.read() - amount);

            // Transfer aBTC from user to contract for burning
            let abtc_dispatcher = IERC20Dispatcher { contract_address: self.abtc_token.read() };
            abtc_dispatcher.transferFrom(caller, get_contract_address(), amount);
            // Note: This would require aBTC contract to have burn functionality
            // abtc_dispatcher.burn(amount);

            emit Repaid { user: caller, amount };
        }

        fn liquidate(ref self: ContractState, user: ContractAddress, debt_to_cover: u256) {
            let caller = get_caller_address();
            assert(debt_to_cover > 0, "Yield: Amount must be > 0");

            let user_info = self.user_info.read(user);
            let collateral_ratio = self.calculate_collateral_ratio(user_info.deposited_wbtc, user_info.borrowed_abtc);

            // Check if user is liquidatable
            assert(collateral_ratio < self.liquidation_threshold.read(), "Yield: User not liquidatable");
            assert(user_info.borrowed_abtc >= debt_to_cover, "Yield: Debt to cover too high");

            // Calculate collateral to seize
            let collateral_to_seize = self.calculate_liquidation_collateral(debt_to_cover);
            assert(user_info.deposited_wbtc >= collateral_to_seize, "Yield: Insufficient collateral");

            // Update user info
            let mut updated_user_info = user_info;
            updated_user_info.deposited_wbtc -= collateral_to_seize;
            updated_user_info.borrowed_abtc -= debt_to_cover;
            self.user_info.write(user, updated_user_info);

            // Update global state
            self.total_wbtc_deposited.write(self.total_wbtc_deposited.read() - collateral_to_seize);
            self.total_abtc_borrowed.write(self.total_abtc_borrowed.read() - debt_to_cover);

            // Transfer aBTC from liquidator to contract
            let abtc_dispatcher = IERC20Dispatcher { contract_address: self.abtc_token.read() };
            abtc_dispatcher.transferFrom(caller, get_contract_address(), debt_to_cover);

            // Transfer WBTC from contract to liquidator
            let wbtc_dispatcher = IERC20Dispatcher { contract_address: self.wbtc_token.read() };
            wbtc_dispatcher.transfer(caller, collateral_to_seize);

            emit Liquidated {
                liquidator: caller,
                user,
                wbtc_amount: collateral_to_seize,
                abtc_amount: debt_to_cover,
            };
        }

        fn harvest(ref self: ContractState) {
            let total_shares = self.total_shares.read();
            assert(total_shares > 0, "Yield: No shares to harvest");

            // Get current position from Vesu using the vesuStruct
            let vesu_struct = vesuStruct {
                singleton: self.vesu_singleton.read().into(),
                pool_id: self.vesu_pool_id.read(),
                col: self.vesu_collateral.read(),
                debt: self.vesu_debt.read(),
                oracle: Zeroable::zero(), // Not needed for deposit_amount
            };
            
            let current_collateral = vesu_struct.deposit_amount(
                self.vesu_collateral.read(), get_contract_address()
            );

            // Calculate the yield (difference between current collateral and tracked deposits)
            let tracked_deposits = self.total_wbtc_deposited.read();
            let total_yield = if current_collateral > tracked_deposits {
                current_collateral - tracked_deposits
            } else {
                0
            };

            // If there is yield, update the total deposits to reflect the new total
            if (total_yield > 0) {
                let new_total_deposited = tracked_deposits + total_yield;
                self.total_wbtc_deposited.write(new_total_deposited);

                emit Harvested {
                    total_yield,
                    new_total_deposited: new_total_deposited,
                };
            }
        }
    }

    #[external(v0)]
    impl IYieldViewImpl of IYieldView<ContractState> {
        fn get_user_info(self: @ContractState, user: ContractAddress) -> UserInfo {
            self.user_info.read(user)
        }

        fn get_total_wbtc_deposited(self: @ContractState) -> u256 {
            self.total_wbtc_deposited.read()
        }

        fn get_total_shares(self: @ContractState) -> u256 {
            self.total_shares.read()
        }

        fn get_total_abtc_borrowed(self: @ContractState) -> u256 {
            self.total_abtc_borrowed.read()
        }

        fn get_wbtc_token(self: @ContractState) -> ContractAddress {
            self.wbtc_token.read()
        }

        fn get_abtc_token(self: @ContractState) -> ContractAddress {
            self.abtc_token.read()
        }

        fn get_price(self: @ContractState) -> u256 {
            self.wbtc_abtc_price.read()
        }

        fn calculate_shares(self: @ContractState, wbtc_amount: u256) -> u256 {
            let total_deposited = self.total_wbtc_deposited.read();
            let total_shares = self.total_shares.read();

            if (total_deposited.is_zero()) {
                // First deposit 1:1 share ratio
                wbtc_amount
            } else {
                // Calculate shares proportionally
                math::mul_div(wbtc_amount, total_shares, total_deposited)
            }
        }

        fn shares_to_wbtc(self: @ContractState, shares: u256) -> u256 {
            let total_deposited = self.total_wbtc_deposited.read();
            let total_shares = self.total_shares.read();

            if (total_shares.is_zero()) {
                0
            } else {
                math::mul_div(shares, total_deposited, total_shares)
            }
        }

        fn calculate_collateral_ratio(
            self: @ContractState, collateral_wbtc: u256, borrowed_abtc: u256
        ) -> u256 {
            if (borrowed_abtc.is_zero()) {
                return COLLATERAL_RATIO_PRECISION * 100; // Infinite ratio
            }

            // Convert both to 18 decimals for calculation
            // WBTC is 8 decimals, aBTC is 18 decimals
            let collateral_wbtc_18 = collateral_wbtc * 10_u256.pow(10); // Convert 8 -> 18 decimals

            // Calculate collateral value in aBTC terms
            let collateral_value = math::mul_div(collateral_wbtc_18, self.wbtc_abtc_price.read(), DECIMAL_PRECISION);

            // Calculate ratio as percentage * 100 (e.g., 15000 = 150%)
            math::mul_div(collateral_value, COLLATERAL_RATIO_PRECISION, borrowed_abtc)
        }

        fn calculate_required_collateral(self: @ContractState, borrow_amount: u256) -> u256 {
            let min_ratio = self.min_collateral_ratio.read();
            
            // Required collateral = (borrow_amount * min_ratio) / price
            let required_18 = math::mul_div(borrow_amount, min_ratio, COLLATERAL_RATIO_PRECISION);
            math::div_ceil(required_18, self.wbtc_abtc_price.read()) // Convert back to WBTC 8 decimals
        }

        fn calculate_liquidation_collateral(self: @ContractState, debt_amount: u256) -> u256 {
            let liquidation_bonus = self.liquidation_bonus.read();
            
            // Liquidator gets bonus: collateral = (debt * bonus) / price
            let collateral_18 = math::mul_div(debt_amount, liquidation_bonus, COLLATERAL_RATIO_PRECISION);
            math::div_ceil(collateral_18, self.wbtc_abtc_price.read()) // Convert back to WBTC 8 decimals
        }
    }

    #[external(v0)]
    impl IYieldOwnerImpl of IYieldOwner<ContractState> {
        fn owner(self: @ContractState) -> ContractAddress {
            self.ownable.get_owner()
        }

        fn transfer_ownership(ref self: ContractState, new_owner: ContractAddress) {
            self.ownable.transfer_ownership(new_owner);
        }

        fn renounce_ownership(ref self: ContractState) {
            self.ownable.renounce_ownership();
        }

        fn update_price(ref self: ContractState, new_price: u256) {
            self.ownable.assert_only_owner();
            assert(new_price > 0, "Yield: Price must be > 0");
            self.wbtc_abtc_price.write(new_price);
            emit PriceUpdated { new_price };
        }

        fn update_min_collateral_ratio(ref self: ContractState, new_ratio: u256) {
            self.ownable.assert_only_owner();
            assert(new_ratio >= COLLATERAL_RATIO_PRECISION, "Yield: Ratio must be >= 100%");
            self.min_collateral_ratio.write(new_ratio);
        }

        fn update_liquidation_threshold(ref self: ContractState, new_threshold: u256) {
            self.ownable.assert_only_owner();
            assert(new_threshold >= COLLATERAL_RATIO_PRECISION, "Yield: Threshold must be >= 100%");
            self.liquidation_threshold.write(new_threshold);
        }

        fn update_liquidation_bonus(ref self: ContractState, new_bonus: u256) {
            self.ownable.assert_only_owner();
            assert(new_bonus >= COLLATERAL_RATIO_PRECISION, "Yield: Bonus must be >= 100%");
            self.liquidation_bonus.write(new_bonus);
        }
    }
}
