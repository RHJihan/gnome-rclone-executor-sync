#!/bin/bash

STATUS_FILE="/tmp/rclone_status.txt"
REMOTE_FILE="/tmp/Passwords_tmp.kdbx"
LOCAL_FILE="$HOME/Passwords.kdbx"
CLOUD_DIR="remote:/path/"
CLOUD_FILE="remote:/path/Passwords.kdbx"

# Check internet connection
CONNECTIVITY=$(nmcli networking connectivity check 2>/dev/null)
if [ "$CONNECTIVITY" != "full" ]; then
    echo "no internet" > "$STATUS_FILE"
    exit 1
fi

# If status file contains "token expired", skip workflow
if [ -f "$STATUS_FILE" ] && grep -iq "token expired" "$STATUS_FILE"; then
    exit 1
fi 

# Try to download latest file from Google Drive
DOWNLOAD_STATUS=$(rclone copyto "$CLOUD_FILE" "$REMOTE_FILE" 2>&1)
if [ $? -eq 0 ]; then
  DOWNLOAD_STATUS="success"
else
  DOWNLOAD_STATUS="error $DOWNLOAD_STATUS"
fi

# Check for download error
if echo "$DOWNLOAD_STATUS" | grep -iqE "token expired|authError"; then
    echo "token expired" > "$STATUS_FILE"
    exit 1
elif echo "$DOWNLOAD_STATUS" | grep -iqE "error"; then
    echo "download error" > "$STATUS_FILE"
    exit 1
fi


# If file was actually downloaded
if echo "$DOWNLOAD_STATUS" | grep -iqE 'success'; then

    # If local file does not exist, accept remote file directly
    if [ ! -f "$LOCAL_FILE" ]; then
        mv "$REMOTE_FILE" "$LOCAL_FILE"
        echo -n "" > "$STATUS_FILE"
        echo "download success" > "$STATUS_FILE"
        exit 0
    fi

    # Compare file modification times
    REMOTE_MTIME=$(stat -c %Y "$REMOTE_FILE")
    LOCAL_MTIME=$(stat -c %Y "$LOCAL_FILE")

    if [ "$REMOTE_MTIME" -gt "$LOCAL_MTIME" ]; then
        # Remote file is newer — replace local with downloaded
        rm -f "$LOCAL_FILE"
        mv "$REMOTE_FILE" "$LOCAL_FILE"
        echo -n "" > "$STATUS_FILE"
        echo "download success" > "$STATUS_FILE"
    elif [ "$REMOTE_MTIME" -lt "$LOCAL_MTIME" ]; then
        # Local file is newer — discard downloaded one and re-upload local
        rm -f "$REMOTE_FILE"
        echo -n "" > "$STATUS_FILE"
        
        UPLOAD_STATUS=$(rclone copy "$LOCAL_FILE" "$CLOUD_DIR" 2>&1)
        if [ $? -eq 0 ]; then
            UPLOAD_STATUS="success"
        else
            UPLOAD_STATUS="error $UPLOAD_STATUS"
        fi

        if echo "$UPLOAD_STATUS" | grep -iqE -iq "token expired|authError"; then
            echo "token expired" > "$STATUS_FILE"
            exit 1
        elif echo "$UPLOAD_STATUS" | grep -iqE -iq "error"; then
            echo "upload error" > "$STATUS_FILE"
            exit 1
        fi

        if echo "$UPLOAD_STATUS" | grep -iqE 'success'; then
            echo "upload success" > "$STATUS_FILE"
            exit 0
        fi
    else
        # Files are the same — do nothing
        rm -f "$REMOTE_FILE"
        echo -n "" > "$STATUS_FILE"
        exit 0
    fi
fi

