#!/usr/bin/env bash
# Install this repo's system files (needs root): sudo ./system/install.sh
#   etc/udev/rules.d/70-dri-stable.rules -> /dev/dri/intel-igpu, nvidia-dgpu
# Safe to re-run. stow.sh never links this directory into $HOME.
set -euo pipefail

if ((EUID != 0)); then
    echo "run with sudo: sudo $0" >&2
    exit 1
fi

here=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

install -Dm644 "$here/etc/udev/rules.d/70-dri-stable.rules" \
    /etc/udev/rules.d/70-dri-stable.rules
udevadm control --reload
# Re-apply rules to the two GPU card nodes only (a "change" event, which the
# running compositor treats like a hotplug rescan).
udevadm trigger --action=change --subsystem-match=drm --property-match=DEVTYPE=drm_minor --sysname-match='card[0-9]*'
udevadm settle

ls -l /dev/dri/intel-igpu /dev/dri/nvidia-dgpu
