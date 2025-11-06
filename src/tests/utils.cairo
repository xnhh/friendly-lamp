use snforge_std::{
    declare, ContractClassTrait, start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::{ContractAddress, get_contract_address};
use snforge_std::{DeclareResultTrait};

pub fn deploy_access_control() -> ContractAddress {
    let cls = declare("AccessControl").unwrap().contract_class();

    let this = get_contract_address();

    let mut calldata: Array<felt252> = array![this.into(), this.into(), this.into(), this.into(),];
    let (address, _) = cls.deploy(@calldata).expect('AC deploy failed');
    return address;
}