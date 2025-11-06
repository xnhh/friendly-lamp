use core::integer::u512_safe_div_rem_by_u256;
use core::num::traits::WideMul;
use core::traits::{Into};
use starknet::{ContractAddress};

use core::panic_with_felt252;

mod errors {
    pub const DECIMALS_OUT_OF_RANGE: felt252 = 'POW_DEC_TOO_LARGE';
}

const SCALE_U256: u256 = 1000000000000000000000000000;

// Lookup-table seems to be the most gas-efficient
pub fn ten_pow(power: u256) -> u256 {
    if power == 0 {
        1
    } else if power == 1 {
        10
    } else if power == 2 {
        100
    } else if power == 3 {
        1000
    } else if power == 4 {
        10000
    } else if power == 5 {
        100000
    } else if power == 6 {
        1000000
    } else if power == 7 {
        10000000
    } else if power == 8 {
        100000000
    } else if power == 9 {
        1000000000
    } else if power == 10 {
        10000000000
    } else if power == 11 {
        100000000000
    } else if power == 12 {
        1000000000000
    } else if power == 13 {
        10000000000000
    } else if power == 14 {
        100000000000000
    } else if power == 15 {
        1000000000000000
    } else if power == 16 {
        10000000000000000
    } else if power == 17 {
        100000000000000000
    } else if power == 18 {
        1000000000000000000
    } else if power == 19 {
        10000000000000000000
    } else if power == 20 {
        100000000000000000000
    } else if power == 21 {
        1000000000000000000000
    } else if power == 22 {
        10000000000000000000000
    } else if power == 23 {
        100000000000000000000000
    } else if power == 24 {
        1000000000000000000000000
    } else if power == 25 {
        10000000000000000000000000
    } else if power == 26 {
        100000000000000000000000000
    } else if power == 27 {
        1000000000000000000000000000
    } else if power == 28 {
        10000000000000000000000000000
    } else if power == 29 {
        100000000000000000000000000000
    } else if power == 30 {
        1000000000000000000000000000000
    } else if power == 31 {
        10000000000000000000000000000000
    } else if power == 32 {
        100000000000000000000000000000000
    } else if power == 33 {
        1000000000000000000000000000000000
    } else if power == 34 {
        10000000000000000000000000000000000
    } else if power == 35 {
        100000000000000000000000000000000000
    } else if power == 36 {
        1000000000000000000000000000000000000
    } else if power == 37 {
        10000000000000000000000000000000000000
    } else if power == 38 {
        100000000000000000000000000000000000000
    } else if power == 39 {
        1000000000000000000000000000000000000000
    } else if power == 40 {
        10000000000000000000000000000000000000000
    } else if power == 41 {
        100000000000000000000000000000000000000000
    } else if power == 42 {
        1000000000000000000000000000000000000000000
    } else if power == 43 {
        10000000000000000000000000000000000000000000
    } else if power == 44 {
        100000000000000000000000000000000000000000000
    } else if power == 45 {
        1000000000000000000000000000000000000000000000
    } else if power == 46 {
        10000000000000000000000000000000000000000000000
    } else if power == 47 {
        100000000000000000000000000000000000000000000000
    } else if power == 48 {
        1000000000000000000000000000000000000000000000000
    } else if power == 49 {
        10000000000000000000000000000000000000000000000000
    } else if power == 50 {
        100000000000000000000000000000000000000000000000000
    } else if power == 51 {
        1000000000000000000000000000000000000000000000000000
    } else if power == 52 {
        10000000000000000000000000000000000000000000000000000
    } else if power == 53 {
        100000000000000000000000000000000000000000000000000000
    } else if power == 54 {
        1000000000000000000000000000000000000000000000000000000
    } else if power == 55 {
        10000000000000000000000000000000000000000000000000000000
    } else if power == 56 {
        100000000000000000000000000000000000000000000000000000000
    } else if power == 57 {
        1000000000000000000000000000000000000000000000000000000000
    } else if power == 58 {
        10000000000000000000000000000000000000000000000000000000000
    } else if power == 59 {
        100000000000000000000000000000000000000000000000000000000000
    } else if power == 60 {
        1000000000000000000000000000000000000000000000000000000000000
    } else if power == 61 {
        10000000000000000000000000000000000000000000000000000000000000
    } else if power == 62 {
        100000000000000000000000000000000000000000000000000000000000000
    } else if power == 63 {
        1000000000000000000000000000000000000000000000000000000000000000
    } else if power == 64 {
        10000000000000000000000000000000000000000000000000000000000000000
    } else if power == 65 {
        100000000000000000000000000000000000000000000000000000000000000000
    } else if power == 66 {
        1000000000000000000000000000000000000000000000000000000000000000000
    } else if power == 67 {
        10000000000000000000000000000000000000000000000000000000000000000000
    } else if power == 68 {
        100000000000000000000000000000000000000000000000000000000000000000000
    } else if power == 69 {
        1000000000000000000000000000000000000000000000000000000000000000000000
    } else if power == 70 {
        10000000000000000000000000000000000000000000000000000000000000000000000
    } else if power == 71 {
        100000000000000000000000000000000000000000000000000000000000000000000000
    } else if power == 72 {
        1000000000000000000000000000000000000000000000000000000000000000000000000
    } else if power == 73 {
        10000000000000000000000000000000000000000000000000000000000000000000000000
    } else if power == 74 {
        100000000000000000000000000000000000000000000000000000000000000000000000000
    } else if power == 75 {
        1000000000000000000000000000000000000000000000000000000000000000000000000000
    } else {
        panic_with_felt252(errors::DECIMALS_OUT_OF_RANGE)
    }
}


fn mul_scale(a: u256, b: u256, scale: u256) -> u256 {
    a * b / scale
}

fn div_scale(a: u256, b: u256, scale: u256) -> u256 {
    (a * scale) / b
}

/// This function assumes `b` is scaled by `SCALE`
pub fn mul(a: u256, b: u256) -> u256 {
    mul_scale(a, b, SCALE_U256)
}

/// This function assumes `b` is scaled by `SCALE`
pub fn div(a: u256, b: u256) -> u256 {
    div_scale(a, b, SCALE_U256)
}

// rounds down
pub fn div_round_down(a: u256, b: u256) -> u256 {
    a / b
}

/// This function assumes `b` is scaled by `10 ^ b_decimals`
pub fn mul_decimals(a: u256, b: u256, b_decimals: u8) -> u256 {
    // `ten_pow` already handles overflow anyways
    let scale = ten_pow(b_decimals.into());
    mul_scale(a, b, scale)
}

/// This function assumes `b` is scaled by `10 ^ b_decimals`
pub fn div_decimals(a: u256, b: u256, b_decimals: u8) -> u256 {
    // `ten_pow` already handles overflow anyways
    let scale = ten_pow(b_decimals.into());
    div_scale(a, b, scale)
}

pub fn normalise(a: u256, actual_decimals: u8, required_decimals: u8) -> u256 {
    if actual_decimals == required_decimals {
        return a;
    }

    if (actual_decimals > required_decimals) {
        return mul_decimals(a, 1, actual_decimals - required_decimals);
    }

    div_decimals(a, 1, required_decimals - actual_decimals)
}

pub fn address_to_felt252(addr: ContractAddress) -> felt252 {
    addr.try_into().unwrap()
}

fn u256_to_address(token_id: u256) -> ContractAddress {
    let token_id_felt: felt252 = token_id.try_into().unwrap();
    token_id_felt.try_into().unwrap()
}

pub fn non_negative_sub(a: u256, b: u256) -> u256 {
    if a < b {
        return 0;
    }
    a - b
}

pub fn is_under_by_percent_bps(value: u256, base: u256, percent_bps: u256) -> bool {
    if (base == 0) {
        return value == 0;
    }
    let factor = value * 10000 / base;
    return factor <= percent_bps;
}

// converts absolute amount to wei amount
pub fn fei_to_wei(etherAmount: u256, decimals: u8) -> u256 {
    etherAmount * ten_pow(decimals.into())
}

#[derive(Drop, Copy, Debug)]
pub enum Rounding {
    Floor, // Toward negative infinity
    Ceil, // Toward positive infinity
    Trunc, // Toward zero
    Expand // Away from zero
}

fn cast_rounding(rounding: Rounding) -> u8 {
    match rounding {
        Rounding::Floor => 0,
        Rounding::Ceil => 1,
        Rounding::Trunc => 2,
        Rounding::Expand => 3
    }
}

pub fn power<T, +Drop<T>, +PartialEq<T>, +TryInto<u256, T>, +Into<T, u256>, +Into<u8, T>>(
    base: T, exp: T
) -> T {
    assert!(base != 0_u8.into(), "Math: base cannot be zero");
    let base: u256 = base.into();
    let exp: u256 = exp.into();
    let mut result: u256 = 1;

    for _ in 0..exp {
        result *= base;
    };

    result.try_into().unwrap()
}

fn round_up(rounding: Rounding) -> bool {
    let u8_rounding = cast_rounding(rounding);
    u8_rounding % 2 == 1
}

pub fn u256_mul_div(x: u256, y: u256, denominator: u256, rounding: Rounding) -> u256 {
    let (q, r) = _raw_u256_mul_div(x, y, denominator);

    // Cast to felts for bitwise op
    let is_rounded_up: felt252 = round_up(rounding).into();
    let has_remainder: felt252 = (r > 0).into();

    q + (is_rounded_up.into() & has_remainder.into())
}

fn _raw_u256_mul_div(x: u256, y: u256, denominator: u256) -> (u256, u256) {
    assert(denominator != 0, 'Math: division by zero');
    let p = x.wide_mul(y);
    let (mut q, r) = u512_safe_div_rem_by_u256(p, denominator.try_into().unwrap());
    let q = q.try_into().expect('Math: quotient > u256');
    (q, r)
}

fn max(a: u256, b: u256) -> u256 {
    let mut max: u256 = 0;
    if (a >= b) {
        max = a;
    } else {
        max = b;
    }
    return max;
}

fn min(a: u256, b: u256) -> u256 {
    let mut min: u256 = 0;
    if (a <= b) {
        min = a;
    } else {
        min = b;
    }
    return min;
}

#[cfg(test)]
mod tests {
    use super::{max, min};

    #[test]
    fn test_max() {
        let a: u256 = 100;
        let b: u256 = 200;
        let ret = max(a, b);
        assert(ret == b, 'invalid max');
    }

    #[test]
    fn test_min() {
        let a: u256 = 100;
        let b: u256 = 200;
        let ret = min(a, b);
        assert(ret == a, 'invalid min');
    }

    #[test]
    fn test_mul() {
        assert_eq!(@super::mul(10, 2000000000000000000000000000), @20, "FAILED");
    }

    #[test]
    fn test_mul_decimals() {
        assert_eq!(@super::mul_decimals(10, 2000000000000000000000000000, 27), @20, "FAILED");
    }

    #[test]
    #[should_panic(expected: ('u256_mul Overflow',))]
    fn test_mul_overflow() {
        super::mul(
            0x400000000000000000000000000000000000000000000000000000000000000,
            2000000000000000000000000000
        );
    }

    #[test]
    #[should_panic(expected: ('u256_mul Overflow',))]
    fn test_mul_decimals_overflow() {
        super::mul_decimals(
            0x400000000000000000000000000000000000000000000000000000000000000,
            2000000000000000000000000000,
            27
        );
    }

    #[test]
    fn test_div() {
        assert_eq!(@super::div(10, 2000000000000000000000000000), @5, "FAILED");
    }

    #[test]
    fn test_div_decimals() {
        assert_eq!(@super::div_decimals(10, 2000000000000000000000000000, 27), @5, "FAILED");
    }
}
