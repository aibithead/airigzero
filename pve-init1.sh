#!/bin/bash
# pve-init1.sh — Proxmox 9 post-install: repos + system upgrade
# Run order: 1 of 3
# Reboots required after: YES if new kernel installed (exit 10)
# Repo: https://github.com/aibithead/airigzero

set -euo pipefail

LOG="/root/pve-init1-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

echo "=== pve-init1 started: $(date) ==="
echo

# --- Repository configuration ---
echo "--- Removing enterprise repositories ---"
rm -f /etc/apt/sources.list.d/pve-enterprise.sources
rm -f /etc/apt/sources.list.d/ceph.sources
echo "  Done."
echo

echo "--- Installing no-subscription repository (Deb822 format) ---"
cat > /etc/apt/sources.list.d/pve-no-subscription.sources <<'EOF'
Types: deb
URIs: http://download.proxmox.com/debian/pve
Suites: trixie
Components: pve-no-subscription
Signed-By: /usr/share/keyrings/proxmox-archive-keyring.gpg
EOF
echo "  Done."
echo

# After (use apt-get, which is the scripting-stable interface):
echo "--- apt-get update ---"
apt-get update
echo

echo "--- apt-get dist-upgrade ---"
DEBIAN_FRONTEND=noninteractive apt-get -y \
    -o Dpkg::Options::="--force-confdef" \
    -o Dpkg::Options::="--force-confold" \
    dist-upgrade

# --- Reboot check ---
echo "=== pve-init1 complete: $(date) ==="
echo
if [ -f /var/run/reboot-required ]; then
    echo "*** REBOOT REQUIRED ***"
    echo "    Reboot, then run pve-init2.sh"
    exit 10
else
    echo "No reboot required. You may proceed to pve-init2.sh."
    exit 0
fi