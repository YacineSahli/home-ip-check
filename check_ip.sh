#!/bin/sh

# Configuration
NTFY_TOPIC=""
NTFY_SERVER="https://ntfy.sh"

OLD_IP_FILE="/config/old_ip.txt"

# Function to send an ntfy notification
send_notification() {
    local message=$1
    curl -H "Title: Public IP Change Alert" \
         -H "Priority: high" \
         -d "$message" \
         "$NTFY_SERVER/$NTFY_TOPIC"
}

# Get current public IP
CURRENT_IP=$(curl -s api.ipify.org)

# Check if the IP was retrieved successfully
if [ -z "$CURRENT_IP" ]; then
    echo "$(date): Failed to retrieve public IP"
    exit 1
fi

# Check if the old IP file exists
if [ -f "$OLD_IP_FILE" ]; then
    OLD_IP=$(cat "$OLD_IP_FILE")

    # Compare current and old IP
    if [ "$CURRENT_IP" != "$OLD_IP" ]; then
        MESSAGE="Homelab Public IP changed from $OLD_IP to $CURRENT_IP"
        send_notification "$MESSAGE"
        echo "$CURRENT_IP" > "$OLD_IP_FILE" # Update the stored IP
    fi
else
    # If file doesn't exist, create it and notify
    echo "$CURRENT_IP" > "$OLD_IP_FILE"
    MESSAGE="Homelab Public IP initialized to $CURRENT_IP"
    send_notification "$MESSAGE"
fi
