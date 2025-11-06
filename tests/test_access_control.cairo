use starknet::ContractAddress;
use starknet::testing::{set_caller_address, set_contract_address};
use starknet::deploy_syscall;
use core::array::ArrayTrait;
use friendly_lamp::components::accessControl::AccessControl;
use friendly_lamp::components::accessControl::AccessControl::Roles;

#[starknet::interface]
trait IAccessControlTest<TContractState> {
    fn has_role(self: @TContractState, role: felt252, account: ContractAddress) -> bool;
    fn get_role_admin(self: @TContractState, role: felt252) -> felt252;
    fn grant_role(ref self: TContractState, role: felt252, account: ContractAddress);
    fn revoke_role(ref self: TContractState, role: felt252, account: ContractAddress);
}

#[starknet::interface]
trait IUpgradeableTest<TContractState> {
    fn upgrade(ref self: TContractState, new_class_hash: starknet::ClassHash);
}

fn deploy_access_control(
    admin: ContractAddress,
    governor: ContractAddress,
    relayer: ContractAddress,
    emergency: ContractAddress,
) -> (IAccessControlTestDispatcher, ContractAddress) {
    let (contract_address, _) = deploy_syscall(
        AccessControl::TEST_CLASS_HASH.try_into().unwrap(),
        0,
        array![
            admin.into(),
            governor.into(),
            relayer.into(),
            emergency.into()
        ]
        .span(),
        false,
    )
    .unwrap();
    let mut contract = IAccessControlTestDispatcher { contract_address };
    (contract, contract_address)
}

#[test]
fn test_constructor_sets_roles() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();

    let (contract, _) = deploy_access_control(admin, governor, relayer, emergency);

    // Check DEFAULT_ADMIN_ROLE is granted to admin
    assert(
        contract.has_role(Roles::DEFAULT_ADMIN_ROLE, admin) == true,
        'Admin should have DEFAULT_ADMIN_ROLE',
    );

    // Check GOVERNOR role is granted to governor
    assert(
        contract.has_role(Roles::GOVERNOR, governor) == true,
        'Governor should have GOVERNOR role',
    );

    // Check RELAYER role is granted to relayer
    assert(
        contract.has_role(Roles::RELAYER, relayer) == true,
        'Relayer should have RELAYER role',
    );

    // Check EMERGENCY_ACTOR role is granted to emergency
    assert(
        contract.has_role(Roles::EMERGENCY_ACTOR, emergency) == true,
        'Emergency should have EMERGENCY_ACTOR role',
    );
}

#[test]
fn test_constructor_sets_role_admins() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();

    let (contract, _) = deploy_access_control(admin, governor, relayer, emergency);

    // Check role admins are set correctly
    assert(
        contract.get_role_admin(Roles::GOVERNOR) == Roles::DEFAULT_ADMIN_ROLE,
        'GOVERNOR admin should be DEFAULT_ADMIN_ROLE',
    );

    assert(
        contract.get_role_admin(Roles::RELAYER) == Roles::DEFAULT_ADMIN_ROLE,
        'RELAYER admin should be DEFAULT_ADMIN_ROLE',
    );

    assert(
        contract.get_role_admin(Roles::EMERGENCY_ACTOR) == Roles::DEFAULT_ADMIN_ROLE,
        'EMERGENCY_ACTOR admin should be DEFAULT_ADMIN_ROLE',
    );
}

#[test]
fn test_admin_can_grant_role() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();
    let new_user: ContractAddress = 5.try_into().unwrap();

    let (contract, contract_address) = deploy_access_control(admin, governor, relayer, emergency);

    // Set caller to admin
    set_contract_address(contract_address);
    set_caller_address(admin);

    // Admin grants GOVERNOR role to new user
    contract.grant_role(Roles::GOVERNOR, new_user);

    // Verify new user has the role
    assert(
        contract.has_role(Roles::GOVERNOR, new_user) == true,
        'New user should have GOVERNOR role',
    );
}

#[test]
fn test_admin_can_revoke_role() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();

    let (contract, contract_address) = deploy_access_control(admin, governor, relayer, emergency);

    // Verify governor has the role initially
    assert(
        contract.has_role(Roles::GOVERNOR, governor) == true,
        'Governor should have GOVERNOR role initially',
    );

    // Set caller to admin
    set_contract_address(contract_address);
    set_caller_address(admin);

    // Admin revokes GOVERNOR role from governor
    contract.revoke_role(Roles::GOVERNOR, governor);

    // Verify role is revoked
    assert(
        contract.has_role(Roles::GOVERNOR, governor) == false,
        'Governor should not have GOVERNOR role after revocation',
    );
}

#[test]
#[should_panic(expected: ('AccessControl: account is missing role',))]
fn test_non_admin_cannot_grant_role() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();
    let new_user: ContractAddress = 5.try_into().unwrap();

    let (contract, contract_address) = deploy_access_control(admin, governor, relayer, emergency);

    // Set caller to governor (not admin)
    set_contract_address(contract_address);
    set_caller_address(governor);

    // Governor tries to grant role (should fail)
    contract.grant_role(Roles::GOVERNOR, new_user);
}

#[test]
#[should_panic(expected: ('AccessControl: account is missing role',))]
fn test_non_admin_cannot_revoke_role() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();

    let (contract, contract_address) = deploy_access_control(admin, governor, relayer, emergency);

    // Set caller to governor (not admin)
    set_contract_address(contract_address);
    set_caller_address(governor);

    // Governor tries to revoke role (should fail)
    contract.revoke_role(Roles::RELAYER, relayer);
}

#[test]
fn test_admin_can_upgrade() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();

    let (contract, contract_address) = deploy_access_control(admin, governor, relayer, emergency);

    // Set caller to admin
    set_contract_address(contract_address);
    set_caller_address(admin);

    let mut upgradeable_contract = IUpgradeableTestDispatcher { contract_address };
    let new_class_hash = 12345.try_into().unwrap();

    // Admin can upgrade (should not panic)
    upgradeable_contract.upgrade(new_class_hash);
}

#[test]
#[should_panic(expected: ('AccessControl: account is missing role',))]
fn test_non_admin_cannot_upgrade() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();

    let (contract, contract_address) = deploy_access_control(admin, governor, relayer, emergency);

    // Set caller to governor (not admin)
    set_contract_address(contract_address);
    set_caller_address(governor);

    let mut upgradeable_contract = IUpgradeableTestDispatcher { contract_address };
    let new_class_hash = 12345.try_into().unwrap();

    // Governor tries to upgrade (should fail)
    upgradeable_contract.upgrade(new_class_hash);
}

#[test]
#[should_panic(expected: ('Governor address cannot be zero',))]
fn test_constructor_rejects_zero_governor() {
    let admin = contract_address_const::<'admin'>();
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let relayer = contract_address_const::<'relayer'>();
    let emergency = contract_address_const::<'emergency'>();

    let (_, _) = deploy_access_control(admin, zero_address, relayer, emergency);
}

#[test]
#[should_panic(expected: ('Relayer address cannot be zero',))]
fn test_constructor_rejects_zero_relayer() {
    let admin = contract_address_const::<'admin'>();
    let governor = contract_address_const::<'governor'>();
    let zero_address: ContractAddress = 0.try_into().unwrap();
    let emergency = contract_address_const::<'emergency'>();

    let (_, _) = deploy_access_control(admin, governor, zero_address, emergency);
}

#[test]
#[should_panic(expected: ('Emgncy address cannot be zero',))]
fn test_constructor_rejects_zero_emergency() {
    let admin = contract_address_const::<'admin'>();
    let governor = contract_address_const::<'governor'>();
    let relayer = contract_address_const::<'relayer'>();
    let zero_address: ContractAddress = 0.try_into().unwrap();

    let (_, _) = deploy_access_control(admin, governor, relayer, zero_address);
}

#[test]
fn test_has_role_returns_false_for_unauthorized_account() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();
    let unauthorized: ContractAddress = 6.try_into().unwrap();

    let (contract, _) = deploy_access_control(admin, governor, relayer, emergency);

    // Unauthorized user should not have any role
    assert(
        contract.has_role(Roles::GOVERNOR, unauthorized) == false,
        'Unauthorized user should not have GOVERNOR role',
    );

    assert(
        contract.has_role(Roles::RELAYER, unauthorized) == false,
        'Unauthorized user should not have RELAYER role',
    );

    assert(
        contract.has_role(Roles::EMERGENCY_ACTOR, unauthorized) == false,
        'Unauthorized user should not have EMERGENCY_ACTOR role',
    );

    assert(
        contract.has_role(Roles::DEFAULT_ADMIN_ROLE, unauthorized) == false,
        'Unauthorized user should not have DEFAULT_ADMIN_ROLE',
    );
}

#[test]
fn test_role_permissions_separation() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();

    let (contract, _) = deploy_access_control(admin, governor, relayer, emergency);

    // Governor should not have RELAYER role
    assert(
        contract.has_role(Roles::RELAYER, governor) == false,
        'Governor should not have RELAYER role',
    );

    // Relayer should not have GOVERNOR role
    assert(
        contract.has_role(Roles::GOVERNOR, relayer) == false,
        'Relayer should not have GOVERNOR role',
    );

    // Emergency should not have GOVERNOR or RELAYER roles
    assert(
        contract.has_role(Roles::GOVERNOR, emergency) == false,
        'Emergency should not have GOVERNOR role',
    );

    assert(
        contract.has_role(Roles::RELAYER, emergency) == false,
        'Emergency should not have RELAYER role',
    );
}

#[test]
fn test_admin_can_grant_multiple_roles() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();
    let new_user: ContractAddress = 5.try_into().unwrap();

    let (contract, contract_address) = deploy_access_control(admin, governor, relayer, emergency);

    // Set caller to admin
    set_contract_address(contract_address);
    set_caller_address(admin);

    // Admin grants multiple roles to new user
    contract.grant_role(Roles::GOVERNOR, new_user);
    contract.grant_role(Roles::RELAYER, new_user);
    contract.grant_role(Roles::EMERGENCY_ACTOR, new_user);

    // Verify new user has all granted roles
    assert(
        contract.has_role(Roles::GOVERNOR, new_user) == true,
        'New user should have GOVERNOR role',
    );

    assert(
        contract.has_role(Roles::RELAYER, new_user) == true,
        'New user should have RELAYER role',
    );

    assert(
        contract.has_role(Roles::EMERGENCY_ACTOR, new_user) == true,
        'New user should have EMERGENCY_ACTOR role',
    );
}

#[test]
fn test_admin_can_revoke_and_re_grant_role() {
    let admin: ContractAddress = 1.try_into().unwrap();
    let governor: ContractAddress = 2.try_into().unwrap();
    let relayer: ContractAddress = 3.try_into().unwrap();
    let emergency: ContractAddress = 4.try_into().unwrap();

    let (contract, contract_address) = deploy_access_control(admin, governor, relayer, emergency);

    // Set caller to admin
    set_contract_address(contract_address);
    set_caller_address(admin);

    // Verify initial state
    assert(
        contract.has_role(Roles::GOVERNOR, governor) == true,
        'Governor should have GOVERNOR role initially',
    );

    // Revoke role
    contract.revoke_role(Roles::GOVERNOR, governor);

    // Verify role is revoked
    assert(
        contract.has_role(Roles::GOVERNOR, governor) == false,
        'Governor should not have GOVERNOR role after revocation',
    );

    // Re-grant role
    contract.grant_role(Roles::GOVERNOR, governor);

    // Verify role is granted again
    assert(
        contract.has_role(Roles::GOVERNOR, governor) == true,
        'Governor should have GOVERNOR role after re-granting',
    );
}

