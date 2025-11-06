use friendly_lamp::mods::lend::interface::ILendMod;
use friendly_lamp::config::contract_address;
use friendly_lamp::components::vesu::vesu::{vesuStruct, vesuToken};
use friendly_lamp::components::vesu::interface::IStonDispatcher;
use starknet::get_contract_address;
use starknet::contract_address::contract_address_const;
use snforge_std::{start_cheat_caller_address, stop_cheat_caller_address};
use friendly_lamp::components::helpers::ERC20Helper;
use friendly_lamp::components::helpers::math;

#[test]
#[fork("mainnet_971311")]
fn test_vesu_component() {
    let vesu_settings = vesuStruct {
        singleton: IStonDispatcher { contract_address: contract_address::VESU_SINGLETON_ADDRESS() },
        pool_id: contract_address::VESU_POOL_ID(),
        debt: contract_address::USDT_ADDRESS(),
        col: contract_address::USDC_ADDRESS(),
        oracle: contract_address::Oracle()
    };

    let user = contract_address::TEST_VESU_USER();

    let this = get_contract_address();
    let amount: u256 = 1000 * math::ten_pow(6);
    let borrow_amt: u256 = 500 * math::ten_pow(6);

    start_cheat_caller_address(contract_address::USDC_ADDRESS(), user);
    ERC20Helper::transfer(contract_address::USDC_ADDRESS(), this, amount);
    stop_cheat_caller_address(contract_address::USDC_ADDRESS());

    start_cheat_caller_address(contract_address::USDT_ADDRESS(), user);
    ERC20Helper::transfer(contract_address::USDT_ADDRESS(), this, amount);
    stop_cheat_caller_address(contract_address::USDT_ADDRESS());

    //deposit
    let pre_deposit = vesu_settings.deposit_amount(contract_address::USDC_ADDRESS(), this);
    assert(pre_deposit == 0, 'Vesu::deposit::invalid zero');
    vesu_settings.deposit(contract_address::USDC_ADDRESS(), amount);
    let post_deposit = vesu_settings.deposit_amount(contract_address::USDC_ADDRESS(), this);
    assert(post_deposit == 999999999, 'Vesu::deposit::invalid deposit');

    //borrow
    let init_borrow_amt = vesu_settings.borrow_amount(contract_address::USDT_ADDRESS(), this);
    assert(init_borrow_amt == 0, 'Vesu::borrow::invalid zero');
    vesu_settings.borrow(contract_address::USDT_ADDRESS(), borrow_amt);
    let bor_amount = vesu_settings.borrow_amount(contract_address::USDT_ADDRESS(), this);
    assert(bor_amount == 500000001, 'Vesu::borrow::invalid borrow');

    //assert hf
    let mut deposit_array = ArrayTrait::<vesuToken>::new();
    let mut borrow_array = ArrayTrait::<vesuToken>::new();
    let dep = vesuToken { underlying_asset: contract_address::USDC_ADDRESS(), };
    let bor = vesuToken { underlying_asset: contract_address::USDT_ADDRESS(), };
    deposit_array.append(dep);
    borrow_array.append(bor);
    let hf = vesu_settings.health_factor(this, deposit_array, borrow_array);
    assert(hf == 18593, 'Vesu::hf::invalid hf');

    //repay
    let repay_amount = 500 * math::ten_pow(6);
    vesu_settings.repay(contract_address::USDT_ADDRESS(), repay_amount);
    let bor_amount = vesu_settings.borrow_amount(contract_address::USDT_ADDRESS(), this);
    assert(bor_amount == 0, 'Vesu::repay::invalid repay');

    //withdraw
    let curr_dep = vesu_settings.deposit_amount(contract_address::USDC_ADDRESS(), this);
    assert(curr_dep == 999999999, 'Vesu::withdraw::invalid deposit');
    vesu_settings.withdraw(contract_address::USDC_ADDRESS(), curr_dep);
    let end_dep = vesu_settings.deposit_amount(contract_address::USDC_ADDRESS(), this);
    assert(end_dep == 0, 'Vesu::withdraw::invalid zero');
}

#[test]
#[fork("mainnet_971311")]
fn test_hf_user() {
    let vesu_settings = vesuStruct {
        singleton: IStonDispatcher { contract_address: contract_address::VESU_SINGLETON_ADDRESS() },
        pool_id: contract_address::VESU_POOL_ID(),
        debt: contract_address::ETH_ADDRESS(),
        col: contract_address::USDC_ADDRESS(),
        oracle: contract_address::Oracle()
    };

    let user_1 = contract_address_const::<
        0x0055741fd3ec832F7b9500E24A885B8729F213357BE4A8E209c4bCa1F3b909Ae
    >();
    //assert hf
    let mut deposit_array = ArrayTrait::<vesuToken>::new();
    let mut borrow_array = ArrayTrait::<vesuToken>::new();
    let dep = vesuToken { underlying_asset: contract_address::USDC_ADDRESS(), };
    let bor = vesuToken { underlying_asset: contract_address::ETH_ADDRESS(), };
    deposit_array.append(dep);
    borrow_array.append(bor);
    let hf = vesu_settings.health_factor(user_1, deposit_array, borrow_array);
    assert(hf == 13438, 'Vesu::hf::invalid hf');
}


