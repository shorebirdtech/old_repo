use std::collections::HashMap;

use serde::Deserialize;

pub struct AppConfig<'a> {
    // provided from the application
    pub client_id: &'a str,
    // typically default=shorebird, but provided by the app as override?
    // pub base_url: Option<&'a str>,
    // typically default=stable, but provided by the app as override.
    // pub channel: Option<&'a str>,
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

struct ResolvedConfig {
    client_id: String,
    base_url: String,
    channel: String,
}

fn load_state() -> Option<UpdaterState> {
    // Load UpdaterState from disk
    // If there is no state, make an empty state.
    return Some(UpdaterState {
        current_slot_index: 0,
        slots: vec![],
    });
}

fn resolve_config(config: AppConfig) -> ResolvedConfig {
    // Resolve the config
    // If there is no base_url, use the default.
    // If there is no channel, use the default.
    return ResolvedConfig {
        client_id: config.client_id.to_string(),
        base_url: "http://localhost:8080".to_string(),
        channel: "stable".to_string(),
    };
}

fn updates_url(config: ResolvedConfig) -> String {
    return format!("{}/updater", config.base_url);
}

#[derive(Deserialize)]
struct UpdateResponse {
    needs_update: bool,
}

pub fn check_for_update(app_config: AppConfig) -> bool {
    let config = resolve_config(app_config);
    // Load UpdaterState from disk
    // If there is no state, make an empty state.
    let version = current_info();
    // Check the current slot.
    // Send info from app + current slot to server.
    let mut map = HashMap::new();
    map.insert("client_id", config.client_id.to_owned());
    map.insert("channel", config.channel.to_owned());
    map.insert("arch", "x86_64".to_string());
    map.insert("platform", "windows".to_string());
    match version {
        Some(v) => {
            map.insert("hash", v.hash);
            map.insert("version", v.version);
        }
        None => {}
    }

    let url = updates_url(config);
    let client = reqwest::blocking::Client::new();
    let response = client.post(url).json(&map).send();
    match response {
        Err(err) => {
            eprintln!("Problem fetching: {err}");
            return false;
        }
        Ok(response) => {
            let result = response.json::<UpdateResponse>();
            match result {
                Err(err) => {
                    eprintln!("Problem parsing: {err}");
                    return false;
                }
                Ok(r) => {
                    // Server returns if there is a new version available.
                    return r.needs_update;
                }
            }
        }
    }
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

// pub fn update(config: AppConfig) -> () {
//     // Check for update.
//     // If needed, download the new version.
//     // Install the new version.
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
