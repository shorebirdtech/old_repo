#[allow(dead_code)]
pub struct AppConfig<'a> {
    // provided from the application
    pub client_id: &'a str,
    // typically default=shorebird, but provided by the app as override?
    pub url: &'a str,
    // typically default=stable, but provided by the app as override.
    pub channel: &'a str,
    // Other needs:
    // Architecture? Or engine can get that itself?
    // fallback path?  Or engine just returns null and caller figures that out?
}

pub struct VersionInfo {
    pub path: String,
    pub version: String,
    pub hash: String,
}

struct Slot {
    path: String,
    version: String,
    hash: String,
}

struct UpdaterState {
    current_slot_index: usize,
    slots: Vec<Slot>,
}

fn load_state() -> Option<UpdaterState> {
    // Load UpdaterState from disk
    // If there is no state, make an empty state.
    return Some(UpdaterState {
        current_slot_index: 0,
        slots: vec![],
    });
}

pub fn check_for_update(_config: AppConfig) -> bool {
    // Load UpdaterState from disk
    // If there is no state, make an empty state.
    // let version = current_info();
    // Check the current slot.
    // Send info from app + current slot to server.
    // Server returns if there is a new version available.
    return false;
}

fn current_version(state: UpdaterState) -> Option<VersionInfo> {
    // If there is no state, return None.
    if state.slots.is_empty() {
        return None;
    }
    let slot = &state.slots[state.current_slot_index];
    // Otherwise return the version info from the current slot.
    return Some(VersionInfo {
        path: slot.path.clone(),
        version: slot.version.clone(),
        hash: slot.hash.clone(),
    });
}

pub fn current_info() -> Option<VersionInfo> {
    // Load UpdaterState from disk
    let state = load_state();
    // If there is no state, return None.
    if state.is_none() {
        return None;
    }
    // Otherwise return the version info from the current slot.
    return current_version(state.unwrap());
}

// pub fn update( config: AppConfig) -> () {
//     // Download the new version
//     // Install the new version
//     // Restart the application
// }

pub fn add(left: usize, right: usize) -> usize {
    left + right
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_works() {
        let result = add(2, 2);
        assert_eq!(result, 4);
    }
}
