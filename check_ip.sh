#!/bin/sh
# home-ip-check — send an ntfy notification when the home public IP changes.
# Deployed on: pve2 host (Proxmox) as a systemd timer — see README.md.
# Config : /etc/home-ip-check.env     (NTFY_TOPIC, NTFY_SERVER — root only)
# State  : /var/lib/home-ip-check/old_ip.txt

set -u

NTFY_TOPIC="${NTFY_TOPIC:-}"
NTFY_SERVER="${NTFY_SERVER:-https://ntfy.sh}"
OLD_IP_FILE="${OLD_IP_FILE:-/var/lib/home-ip-check/old_ip.txt}"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S%z'): $*"; }

[ -z "$NTFY_TOPIC" ] && { log "NTFY_TOPIC is not set — check /etc/home-ip-check.env"; exit 1; }

send_notification() {
    curl --max-time 20 -sf \
        -H "Title: Public IP Change Alert" \
        -H "Priority: high" \
        -d "$1" \
        "$NTFY_SERVER/$NTFY_TOPIC" >/dev/null
}

CURRENT_IP=$(curl --max-time 20 -sf https://api.ipify.org)
if [ -z "$CURRENT_IP" ]; then
    log "failed to retrieve public IP (ipify unreachable or error)"
    exit 1
fi

# Validate IPv4 — guards against captive portals / HTML error pages stored as an "IP"
if ! printf '%s' "$CURRENT_IP" | grep -Eq '^([0-9]{1,3}\.){3}[0-9]{1,3}$'; then
    log "invalid response from ipify: $CURRENT_IP"
    exit 1
fi
for octet in $(printf '%s' "$CURRENT_IP" | tr '.' ' '); do
    [ "$octet" -le 255 ] || { log "invalid IP: $CURRENT_IP"; exit 1; }
done

if [ -s "$OLD_IP_FILE" ]; then
    OLD_IP=$(cat "$OLD_IP_FILE")
    if [ "$CURRENT_IP" = "$OLD_IP" ]; then
        log "IP unchanged ($CURRENT_IP)"
        exit 0
    fi
    MESSAGE="Homelab Public IP changed from $OLD_IP to $CURRENT_IP"
else
    MESSAGE="Homelab Public IP initialized to $CURRENT_IP"
fi

if send_notification "$MESSAGE"; then
    echo "$CURRENT_IP" > "$OLD_IP_FILE"  # update state only after a confirmed send
    log "$MESSAGE"
else
    log "ntfy send FAILED — state not updated, will retry next run"
    exit 1
fi
