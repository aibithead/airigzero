#!/bin/bash
# pve-init3.sh — Proxmox 9 post-install: verification + cleanup
# Run order: 3 of 3
# Prereq: pve-init2.sh complete, rebooted
# Reboots required after: no (exit 0 on success)
# Repo: https://github.com/aibithead/airigzero

set -euo pipefail

LOG="/root/pve-init3-$(date +%Y%m%d-%H%M%S).log"
exec > >(tee -a "$LOG") 2>&1

echo "=== pve-init3 started: $(date) ==="
echo

# --- Pre-flight verification ---
echo "--- Verifying IOMMU is active ---"
if grep -q "intel_iommu=on" /proc/cmdline; then
    echo "  PASS: intel_iommu=on in /proc/cmdline"
else
    echo "  FAIL: intel_iommu=on NOT in /proc/cmdline"
    echo "         Did you reboot after pve-init2.sh? Reboot and re-run pve-init3."
    exit 1
fi

# Use subshell with pipefail disabled — grep -q closes stdin early, causing
# SIGPIPE on journalctl which pipefail otherwise treats as a pipeline failure.
if (set +o pipefail; journalctl -k -b --no-pager 2>/dev/null | grep -q "Default domain type: Passthrough"); then
    echo "  PASS: IOMMU in Passthrough mode"
else
    echo "  WARNING: IOMMU not in Passthrough mode (may be Translated)"
    echo "           This still works for LXC+NVIDIA but is sub-optimal."
fi
echo

# --- Cleanup ---
echo "--- Cleanup ---"
journalctl --vacuum-time=1d
apt-get clean
rm -f /var/crash/*
echo "  Cleanup complete."
echo

# --- Final sanity checks ---
echo "--- Final sanity checks ---"
echo
echo "Failed services:"
systemctl --failed --no-pager || true
echo

echo "Broken packages:"
dpkg --audit || true
echo

echo "Active repositories:"
apt-cache policy 2>&1 | grep -E "http://|https://" | sort -u || true
echo

echo "Kernel:"
uname -r
echo

echo "Proxmox version:"
pveversion
echo

echo "=== pve-init3 complete: $(date) ==="
echo "Host is ready. Next: NVIDIA driver install."
exit 0