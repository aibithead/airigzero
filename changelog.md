# Changelog

## v1.2 — 2026-04-20
- Fix pve-init2 nag-pattern grep checks. The sed replacement uses `-Ezi` (multi-line) but the preceding grep existence check used line-by-line mode, so the check always failed and the script skipped the replacement with "pattern not found". Both grep checks now use `-z` for consistent multi-line matching.

## v1.1 — 2026-04-20
- Fix false-positive "Failed services:" match when grepping pve-init logs for errors
- Update pve-init3 section header text to avoid matching `grep -iE "fail"` patterns

## v1.0 — 2026-04-20
- Initial tagged release
- Three-script post-install workflow: pve-init1 (repos + upgrade), pve-init2 (IOMMU + nag + kernel pin), pve-init3 (verify + cleanup)
- Scripts are idempotent and self-logging
- Tested end-to-end on HP Z440 + Proxmox VE 9.1.8