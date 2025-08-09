#!/bin/bash

SYNC="$HOME/.local/share/bin/rclone-sync.sh"
STATUS_FILE="/tmp/rclone_upload_status.txt"
STATUS=$(cat "$STATUS_FILE" 2>/dev/null)

case "$STATUS" in
"no internet")
    echo "⌛︎  Waiting for connection..."
    "$SYNC"
    ;;

  "upload error")
    echo "<executor.markup.true> <span foreground='red'>⨯  Upload error</span>"
    "$SYNC"
    ;;

  "upload success")
    echo "↑  Upload successful"
    echo -n "" > "$STATUS_FILE"
    ;;

  "download error")
    echo "<executor.markup.true> <span foreground='red'>⨯  Download error</span>"
    "$SYNC"
    ;;

  "download success")
    echo "↓  Download successful"
    echo -n "" > "$STATUS_FILE"
    ;;
esac

# Handle token expired logic
if grep -iq "token expired" <<< "$STATUS"; then
    # Always show the message
    echo "<executor.markup.true> <span foreground='red'>⨯  Token expired</span>"

    # If terminal has not been opened yet for this token expiration
    if ! grep -iq "terminal opened" <<< "$STATUS"; then
        echo "token expired terminal opened" > "$STATUS_FILE"
        gnome-terminal -- bash -c "
        echo 'Reconnect Rclone with remote:'
        while true; do
            rclone config reconnect remote:
            if [ \$? -eq 0 ]; then
                echo -n '' > \"$STATUS_FILE\"
                echo 'Sync running...'
                "$SYNC" && echo 'Sync completed'
                break
            else
                echo 'Reconnect failed. Please try again or press Ctrl+C to abort.'
            fi
        done
        sleep 2
        "
    fi
fi

