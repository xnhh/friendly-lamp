# Yield Contract Summary

## Overview
The yield contract is a lending protocol that allows users to:
1. Deposit WBTC and receive shares representing their proportional ownership
2. Borrow aBTC against their deposited WBTC collateral
3. Repay borrowed aBTC
4. Liquidate undercollateralized positions

## Key Features

### State Variables
- **wbtc_token**: WBTC token contract address
- **abtc_token**: aBTC token contract address  
- **total_wbtc_deposited**: Total WBTC deposited by all users
- **total_shares**: Total shares issued to all users
- **total_abtc_borrowed**: Total aBTC borrowed by all users
- **user_info**: Mapping of user address to their deposit/borrow info

### User Data Structure
```cairo
struct UserInfo {
    deposited_wbtc: u256,  // Total WBTC deposited by user
    shares: u256,         // Shares owned by user (proportional ownership)
    borrowed_abtc: u256,  // Total aBTC borrowed by user
}
```

### Key Constants
- **MIN_COLLATERAL_RATIO**: 150% (minimum collateral ratio)
- **LIQUIDATION_THRESHOLD**: 120% (ratio below which positions can be liquidated)
- **LIQUIDATION_BONUS**: 105% (bonus given to liquidators)

### Core Functions

#### Deposit/Borrow Operations
- **deposit(amount)**: Deposit WBTC and receive shares
- **withdraw(amount)**: Withdraw WBTC (must maintain collateral ratio)
- **borrow(amount)**: Borrow aBTC against WBTC collateral
- **repay(amount)**: Repay borrowed aBTC

#### Liquidation
- **liquidate(user, debt_to_cover)**: Liquidate an undercollateralized position

#### View Functions
- **calculate_collateral_ratio(collateral, debt)**: Calculate current collateral ratio
- **calculate_required_collateral(borrow_amount)**: Calculate required WBTC for borrowing
- **get_user_info(user)**: Get user's current position

### Share System
Users receive shares proportional to their WBTC deposits:
- First deposit: 1:1 share ratio
- Subsequent deposits: Shares calculated proportionally to existing deposits

### Security Features
- Minimum collateral ratio requirements
- Liquidation mechanism for undercollateralized positions  
- Liquidation bonus to incentivize liquidators
- Ownership controls for parameter updates

### Price Integration
The contract supports WBTC/aBTC price oracle integration for accurate collateral calculations.

## Next Steps
1. Implement vault contract that can mint/burn aBTC
2. Connect yield contract to aBTC contract for minting/burning
3. Add price oracle integration
4. Implement interest rate mechanics
5. Add comprehensive testing
