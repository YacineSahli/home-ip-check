# home-ip-check

Sends an ntfy notification when the home network's public IP (ISP) changes.

## Current deployment (since 2026-09-22): systemd timer on the pve2 Proxmox host

The original Docker-on-a-VM deployment (VM 101) was retired — a whole VM for one
hourly shell script. The Docker variant (Dockerfile + docker-compose.yml) lives in
git history if ever needed.

Files on pve2:

| File | Purpose |
|---|---|
| `/usr/local/sbin/home-ip-check.sh` | this script (identical to `check_ip.sh` here) |
| `/etc/home-ip-check.env` | `NTFY_TOPIC` + `NTFY_SERVER` — **secret, root 600**, never in this repo |
| `/var/lib/home-ip-check/old_ip.txt` | state (last seen IP) |
| `/etc/systemd/system/home-ip-check.{service,timer}` | hourly timer, `RandomizedDelaySec=10m`, `Persistent=true` |

Ops docs: `~/Gits/ops/hosts/pve2/README.md`.

## Usage / testing

```sh
systemctl start home-ip-check.service   # run once now
systemctl list-timers home-ip-check.timer
journalctl -u home-ip-check.service -n 5
```

First-ever run sends "initialized to <IP>" (also serves as an end-to-end delivery
test). On change: "changed from <old> to <new>". State is only updated after a
confirmed ntfy send, so a failed notification retries on the next run.

## Local test without systemd

```sh
NTFY_TOPIC=... NTFY_SERVER=https://ntfy.sh OLD_IP_FILE=/tmp/old_ip.txt ./check_ip.sh
```
