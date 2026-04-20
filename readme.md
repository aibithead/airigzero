# airigzero

Post-install bootstrap scripts for **airigzero**, a Proxmox VE 9 AI compute host built on an HP Z440 workstation with dual NVIDIA RTX 5060 Ti GPUs.

These scripts automate the repository configuration, system upgrade, IOMMU setup, and UI tweaks required after a fresh Proxmox VE install. They're designed to be idempotent, self-logging, and safe to re-run.

## What these scripts do

| Script | Purpose | Reboots after |
|---|---|---|
| `pve-init1.sh` | Replace enterprise repos with no-subscription repo; run `apt dist-upgrade` | If kernel updated |
| `pve-init2.sh` | Enable IOMMU kernel cmdline (`intel_iommu=on iommu=pt`); suppress subscription nag popup | Always |
| `pve-init3.sh` | Verify IOMMU is active; clean up logs and caches; print sanity summary | No |

## Quick start

After a fresh Proxmox VE install, log in as `root` at the console and run:

```bash
cd /root
for f in pve-init1.sh pve-init2.sh pve-init3.sh; do
    curl -fsSLO "https://raw.githubusercontent.com/aibithead/airigzero/main/$f"
done
chmod +x pve-init*.sh
```

Then run each script in order, rebooting when indicated:

```bash
./pve-init1.sh   # reboot if exit code 10
./pve-init2.sh   # always reboot after (exit code 10)
./pve-init3.sh   # no reboot; prints "Host is ready" on success
```

Each script logs its full output to `/root/pve-initN-YYYYMMDD-HHMMSS.log`.

## Target environment

These scripts are tuned for:

- **Hardware:** HP Z440 workstation, Intel Xeon E5-1600/2600 v3/v4 series CPU, dual NVIDIA RTX 5060 Ti GPUs, AMD RX 550 as host display
- **Software:** Proxmox VE 9.x on a grub + LVM/ext4 install (not ZFS/systemd-boot)
- **Architecture:** LXC containers with shared GPUs (NVIDIA driver on host, nvidia-container-toolkit for LXC), not VFIO/VM passthrough

The scripts should work on other Intel-based Proxmox 9 hosts with minor adjustments, but the IOMMU cmdline assumes Intel CPU. For AMD hosts, `intel_iommu=on` should be changed to `amd_iommu=on` in `pve-init2.sh`.

## Prerequisites

Before running these scripts:

1. **Proxmox VE 9.x freshly installed** from the official ISO
2. **BIOS/UEFI configured** — specifically:
   - VT-x (Intel Virtualization Technology) enabled
   - VT-d (Intel Virtualization Technology for Directed I/O) enabled
   - Legacy boot disabled
   - NVMe first in UEFI boot order
   - POST delay set to ≥2 seconds (recommended for F-key access)
3. **Network connectivity** — verify with `ping -c 2 deb.debian.org`
4. **Root shell access** — physical console or SSH

## Idempotency

All three scripts are safe to run multiple times:

- `pve-init1.sh` — apt operations are naturally idempotent; repo file writes are overwrites, not appends
- `pve-init2.sh` — skips the grub edit if `intel_iommu=on` already present; skips the nag patch if already applied
- `pve-init3.sh` — verification and cleanup only; always safe

## After the nag patch

The "No valid subscription" popup suppression works by patching `/usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js`. This file is **replaced on every upgrade of the `proxmox-widget-toolkit` package**, which will re-expose the nag popup.

To re-apply after an upgrade, just re-run `pve-init2.sh`. The grub edit and kernel pin steps will be skipped (idempotent); the nag patch will be re-applied.

## Troubleshooting

**Scripts download as 0-byte files:** Check repo visibility — `raw.githubusercontent.com` returns 404 without auth for private repos. This repo must remain public.

**`pve-init2.sh` says "nag pattern not found":** Upstream changed the JavaScript structure in a newer `proxmox-widget-toolkit` release. The sed pattern needs updating. Check the pve-init2 log for details; manual patching per Proxmox community resources may be required until this repo is updated.

**`pve-init3.sh` fails with "intel_iommu=on NOT in /proc/cmdline":** You didn't reboot after `pve-init2.sh`. Reboot and re-run `pve-init3.sh`.

**IOMMU not in Passthrough mode:** VT-d may be disabled in BIOS. Confirm with `dmesg | grep -i dmar` — you should see `DMAR: IOMMU enabled`.

## Why these scripts exist

Post-install configuration of Proxmox VE involves a handful of well-known steps that every administrator performs manually: disabling the enterprise repo, enabling no-subscription, upgrading, configuring IOMMU, suppressing the nag popup. Doing this by copy-pasting commands from a blog post works, but:

- It's error-prone — single character paste errors have caused real problems on this very host
- It's not reproducible — if something breaks later, you can't tell what state the host should be in
- It's not documented as code — the procedure lives in prose, not in version control

These scripts formalize the procedure into auditable, version-controlled shell code. The commit history of this repo becomes the history of how the procedure has evolved.

## Related resources

- [Proxmox VE Documentation](https://pve.proxmox.com/pve-docs/)
- [Proxmox No-Subscription Repository](https://pve.proxmox.com/wiki/Package_Repositories#sysadmin_no_subscription_repo)
- Author's project showcase: [aibithead.com](https://aibithead.com)

## License

MIT. Use at your own risk. See the scripts themselves — they modify system configuration files, and while they're tested on the target hardware, your mileage may vary.

## Author

Andrew Creque ([@acreque](https://github.com/acreque)) — part of the [airigzero](https://github.com/aibithead/airigzero) infrastructure project.