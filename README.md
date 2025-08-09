# KeePassXC Sync with Google Drive via Executor GNOME Shell Extension
This project provides a solution to keep your KeePassXC `.kdbx` password database (or any other file) synchronized between your local machine and cloud storage (i.e. Google Drive) using `rclone` and the [Executor - Gnome Shell Extension](https://extensions.gnome.org/extension/2932/executor/). It includes two bash scripts:

- `rclone-sync.sh`: Handles uploading and downloading the local file via `rclone`.
- `sync-status-display.sh`: Displays sync status notifications on GNOME Shell using Executor, and triggers sync or reconnection when needed.

---
## Features
* Automatic two-way sync between local file and cloud.
* Handles internet connectivity checks.
* Detects token expiration and guides reconnection.
* Shows real-time sync status in GNOME Shell.
* Works with minimal user intervention.

## Prerequisites
* Linux system with GNOME Shell.
* [rclone](https://rclone.org/downloads/) installed and [configured](https://rclone.org/drive/) with your remote cloud. (i.e. Google Drive).
  > **Note:** Name the remote connection `remote` for consistency.
* [Executor - Gnome Shell Extension](https://extensions.gnome.org/extension/2932/executor/) installed.
* NetworkManager CLI (`nmcli`) installed and accessible, since the scripts use `nmcli` to check internet connectivity.

## Download Scripts
Save the following two scripts to your local machine:
* [`rclone-sync.sh`](./rclone-sync.sh)
* [`sync-status-display.sh`](./sync-status-display.sh)

### Adjust the following variables inside the scripts to fit your environment:

| Variable     | Description                            | Example                                      |
|--------------|----------------------------------------|----------------------------------------------|
| `LOCAL_FILE` | Path to your local file                | `LOCAL_FILE="$HOME/Passwords.kdbx"`              |
| `REMOTE_FILE`| Temporary file location for downloads  | `REMOTE_FILE="/tmp/Passwords_tmp.kdbx"`      |
| `STATUS_FILE`| Path to status tracking file           | `STATUS_FILE="/tmp/rclone_status.txt"`       |
| `SYNC`       | Location of `rclone-sync.sh` script    | `SYNC="$HOME/.local/share/bin/rclone-sync.sh"`   |
| `CLOUD_DIR`  | Remote cloud directory (not file)       | `CLOUD_DIR="remote:/path"`                  |
| `CLOUD_FILE` | Remote cloud file location             | `CLOUD_FILE="remote:/path/Passwords.kdbx"`   |

---


## Make scripts executable
``` bash
chmod +x /path/to/rclone-sync.sh /path/to/sync-status-display.sh
```
## Configure Executor extension
1. Open GNOME Extensions app, find Executor extension and open its preferences or open directly from the terminal:
    ``` bash
    gnome-extensions prefs executor@raujonas.github.io
    ```

2. Add a new command for syncing:

   * Command: `/path/to/rclone-sync.sh`

   * Run every: 600 seconds (15 minutes)

3. Add a new command for display/status updates:

   * Command: `/path/to/sync-status-display.sh`

   * Run every: 10 seconds

5. Save and enable both commands.

## How it works
* Every 15 minutes, `rclone-sync.sh` runs and performs:

    1. Internet connectivity check.

    2. Downloads latest file file from remote cloud (i.e. Google Drive).

    3. Compares timestamps of remote and local files.

    4. Uploads newer local file if applicable.

    5. Updates status in /tmp/rclone_status.txt.

* Every 10 seconds, `sync-status-display.sh` runs and:

    1. Reads the status file.

    2. Displays status on GNOME Shell via Executor.

    3. Automatically triggers sync or reconnects Google Drive token if expired.

* If token expired, a terminal will open to guide re-authentication with the remote cloud.

## Manual Usage
You can manually run sync script anytime:
``` bash
./rclone-sync.sh
```
Or display script:
```bash
./sync-status-display.sh
```

## Troubleshooting
* No internet: Sync is skipped until connection is restored.

* Token expired: Terminal prompts to reconnect remote cloud via rclone.

* Upload/download errors: Logged in status file, retry after fixing network or authentication.

* Permission issues: Ensure scripts have execute permissions and rclone is configured correctly.

## Customization
* Modify paths to local file and status file inside scripts.

* Adjust intervals in Executor extension according to your preference.

* You can customize GNOME Shell display messages by editing sync-status-display.sh.

## Example Directory Structure
```bash
$HOME/.local/share/bin/
  ├─ rclone-sync.sh
  └─ sync-status-display.sh

/tmp/
  ├─ rclone_status.txt
  └─ Passwords_tmp.kdbx (temporary)
  
$HOME/
  └─ Passwords.kdbx (local KeePassXC database)
  ```

