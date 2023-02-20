use std::ffi::CStr;
use std::os::raw::c_char;

use crate::updater;

#[no_mangle]
pub extern "C" fn hello_world() {
    println!("Hello, world!");
}

// bool and C do not get along.
// https://stackoverflow.com/questions/47705093/what-is-the-correct-type-for-returning-a-c99-bool-to-rust-via-the-ffi
// https://stackoverflow.com/questions/62307551/how-to-use-boolean-types-in-dart-ffi

#[no_mangle]
pub extern "C" fn check_for_update(c_client_id: *const c_char, c_cache_dir: *const c_char) -> u8 {
    let client_id = unsafe { CStr::from_ptr(c_client_id) }.to_str().unwrap();
    let cache_dir = if c_cache_dir == std::ptr::null() {
        None
    } else {
        Some(unsafe { CStr::from_ptr(c_cache_dir).to_str().unwrap() })
    };

    let config = updater::AppConfig {
        client_id: client_id,
        cache_dir: cache_dir,
    };
    if updater::check_for_update(config) {
        1
    } else {
        0
    }
}
