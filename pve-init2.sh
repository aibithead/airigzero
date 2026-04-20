#!/bin/bash
# pve-init2.sh — Proxmox 9 post-install: IOMMU, nag removal, kernel pin
# Run order: 2 of 3
# Prereq: pve-init1.sh complete, rebooted if pve-init1 required it
# Reboots required after: YES (IOMMU cmdline change requires reboot, exit 10)
# Repo: https://github.com/aibithead/airigzero

set -euo pipefail

LOG="/root/pve-init2-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

echo "=== pve-init2 started: $(date) ==="
echo

# --- IOMMU kernel cmdline (for GPU workloads) ---
echo "--- Configuring IOMMU kernel cmdline ---"
GRUB_FILE=/etc/default/grub

if grep -q "intel_iommu=on" "$GRUB_FILE"; then
    echo "  intel_iommu=on already present, skipping grub edit."
else
    cp "$GRUB_FILE" "${GRUB_FILE}.bak.$(date +%Y%m%d-%H%M%S)"
    sed -i 's/^GRUB_CMDLINE_LINUX_DEFAULT="quiet"$/GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_iommu=on iommu=pt"/' "$GRUB_FILE"

    if ! grep -q "intel_iommu=on" "$GRUB_FILE"; then
        echo "ERROR: sed did not modify GRUB_CMDLINE_LINUX_DEFAULT."
        echo "       Check /etc/default/grub format — may have non-default content."
        exit 1
    fi

    echo "  Added: intel_iommu=on iommu=pt"
    echo "  Running update-grub..."
    update-grub
fi
echo

# --- Nag screen removal ---
echo "--- Suppressing 'No valid subscription' nag popup ---"
NAG_FILE=/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js

if [ ! -f "$NAG_FILE" ]; then
    echo "  WARNING: $NAG_FILE not found. Skipping."
elif grep -q "void({ //Ext.Msg.show" "$NAG_FILE"; then
    echo "  Nag already suppressed, skipping."
else
    if ! grep -qE "Ext\.Msg\.show\(\{[^}]*title: gettext\('No valid sub" "$NAG_FILE"; then
        echo "  WARNING: nag pattern not found. Upstream may have changed the code."
        echo "           Nag popup will still appear. Skipping sed."
    else
        sed -Ezi.bak "s/(Ext\.Msg\.show\(\{[^}]*title: gettext\('No valid sub)/void\({ \/\/\1/g" "$NAG_FILE"
        systemctl restart pveproxy
        echo "  Nag suppressed. Backup saved to ${NAG_FILE}.bak"
        echo "  NOTE: Must re-run after any proxmox-widget-toolkit upgrade."
    fi
fi
echo

# --- Pin current kernel (systemd-boot installs only; no-op on grub) ---
echo "--- Pinning current kernel ---"
RUNNING_KERNEL=$(uname -r)
if command -v proxmox-boot-tool >/dev/null 2>&1; then
    proxmox-boot-tool kernel pin "$RUNNING_KERNEL" 2>&1 || {
        echo "  Kernel pin via proxmox-boot-tool not applicable (grub install). Skipping."
    }
else
    echo "  proxmox-boot-tool not found. Skipping kernel pin."
fi
echo

echo "=== pve-init2 complete: $(date) ==="
echo
echo "*** REBOOT REQUIRED for IOMMU cmdline to take effect ***"
echo "    Reboot, verify with 'cat /proc/cmdline', then run pve-init3.sh"
exit 10