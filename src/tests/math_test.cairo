use friendly_lamp::components::helpers::math;

#[test]
fn test_max() {
    let a: u256 = 100;
    let b: u256 = 200;
    let ret = math::max(a, b);
    assert(ret == b, 'invalid max');
}

#[test]
fn test_min() {
    let a: u256 = 100;
    let b: u256 = 200;
    let ret = math::min(a, b);
    assert(ret == a, 'invalid min');
}

#[test]
fn test_mul() {
    assert_eq!(@math::mul(10, 2000000000000000000000000000), @20, "FAILED");
}

#[test]
fn test_mul_decimals() {
    assert_eq!(@math::mul_decimals(10, 2000000000000000000000000000, 27), @20, "FAILED");
}

#[test]
#[should_panic(expected: ('u256_mul Overflow',))]
fn test_mul_overflow() {
    math::mul(
        0x400000000000000000000000000000000000000000000000000000000000000,
        2000000000000000000000000000
    );
}

#[test]
#[should_panic(expected: ('u256_mul Overflow',))]
fn test_mul_decimals_overflow() {
    math::mul_decimals(
        0x400000000000000000000000000000000000000000000000000000000000000,
        2000000000000000000000000000,
        27
    );
}

#[test]
fn test_div() {
    assert_eq!(@math::div(10, 2000000000000000000000000000), @5, "FAILED");
}

#[test]
fn test_div_decimals() {
    assert_eq!(@math::div_decimals(10, 2000000000000000000000000000, 27), @5, "FAILED");
}


