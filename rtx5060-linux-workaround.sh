#!/usr/bin/env bash
#
# rtx5060-linux-workaround.sh
#
# Robust GRUB workaround for RTX 5060 issues on Linux kernels 6.14+
# Handles non-interactive execution (curl | bash) safely.
#

set -euo pipefail

SCRIPT_NAME="rtx5060-linux-workaround.sh"
AUTO_CONFIRM="no"

# Detect --yes anywhere in args
for arg in "$@"; do
    if [ "$arg" = "--yes" ]; then
        AUTO_CONFIRM="yes"
    fi
done

require_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo "This action requires root privileges."
        exit 1
    fi
}

has_cmdline_flag() {
    grep -qw "$1" /proc/cmdline
}

backup_grub() {
    local backup="/etc/default/grub.backup-$(date +%Y%m%d-%H%M%S)"
    cp /etc/default/grub "$backup"
    echo "GRUB backup created at: $backup"
}

confirm() {
    if [ "$AUTO_CONFIRM" = "yes" ]; then
        return 0
    fi

    if [ ! -t 0 ]; then
        echo "Non-interactive execution detected. Auto-confirming."
        return 0
    fi

    echo
    read -r -p "This will modify /etc/default/grub. Continue? [y/N]: " ans
    if [ "$ans" != "y" ] && [ "$ans" != "Y" ]; then
        echo "Aborted."
        exit 1
    fi
}

normalize_grub_line() {
    local extra_flags="$1"

    local current
    current=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub)

    # Extract content inside quotes
    local content
    content=$(printf '%s\n' "$current" | sed 's/^[^"]*"\(.*\)"/\1/')

    # Append missing flags
    for flag in $extra_flags; do
        if ! printf '%s\n' "$content" | grep -qw "$flag"; then
            content="$content $flag"
        fi
    done

    # Normalize spaces
    content=$(printf '%s\n' "$content" | sed 's/  */ /g; s/^ //; s/ $//')

    # Write back
    sed -i "s|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT=\"$content\"|" /etc/default/grub
}

diagnose() {
    echo "RTX 5060 Linux Diagnostic"
    echo "========================="
    echo

    if lspci | grep -qi "NVIDIA"; then
        echo "GPU: NVIDIA detected"
    else
        echo "GPU: NVIDIA not detected"
    fi

    echo "Kernel: $(uname -r)"

    if grep -qi AuthenticAMD /proc/cpuinfo; then
        echo "CPU: AMD"
    elif grep -qi GenuineIntel /proc/cpuinfo; then
        echo "CPU: Intel"
    else
        echo "CPU: Unknown"
    fi

    if command -v nvidia-smi >/dev/null 2>&1 && nvidia-smi >/dev/null 2>&1; then
        echo "Driver: NVIDIA responding"
        DRIVER_OK=yes
    else
        echo "Driver: NVIDIA not responding"
        DRIVER_OK=no
    fi

    echo
    echo "Boot parameters:"
    has_cmdline_flag pci=realloc=off && echo "  pci=realloc=off (active)"
    has_cmdline_flag amd_iommu=off   && echo "  amd_iommu=off (active)"
    has_cmdline_flag iommu=soft      && echo "  iommu=soft (active)"

    echo
    echo "Assessment:"

    if [ "$DRIVER_OK" = "yes" ] && has_cmdline_flag pci=realloc=off; then
        echo "System already running with workaround applied."
        echo "No action required."
        exit 0
    fi

    if grep -qi AuthenticAMD /proc/cpuinfo; then
        echo "Suggested command:"
        echo "  sudo ./$SCRIPT_NAME apply-amd"
    else
        echo "Suggested command:"
        echo "  sudo ./$SCRIPT_NAME apply-intel"
    fi
}

apply_amd() {
    require_root

    echo "Applying workaround for AMD CPU systems"
    echo
    echo "This will ensure the following GRUB parameters are set:"
    echo "  pci=realloc=off amd_iommu=off"
    echo

    confirm
    backup_grub

    normalize_grub_line "pci=realloc=off amd_iommu=off"

    echo
    echo "Updated GRUB configuration:"
    grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub

    update-grub
    echo
    echo "Workaround applied. Reboot the system."
}

apply_intel() {
    require_root

    echo "Applying workaround for Intel CPU systems"
    echo
    echo "This will ensure the following GRUB parameter is set:"
    echo "  pci=realloc=off"
    echo

    confirm
    backup_grub

    normalize_grub_line "pci=realloc=off"

    echo
    echo "Updated GRUB configuration:"
    grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub

    update-grub
    echo
    echo "Workaround applied. Reboot the system."
}

rollback() {
    require_root

    local backup
    backup=$(ls -t /etc/default/grub.backup-* 2>/dev/null | head -1)

    if [ -z "$backup" ]; then
        echo "No GRUB backup found."
        exit 1
    fi

    echo "Restoring GRUB from backup:"
    echo "  $backup"
    echo

    confirm
    cp "$backup" /etc/default/grub
    update-grub
    echo
    echo "Rollback complete. Reboot the system."
}

show() {
    echo "Current GRUB configuration:"
    grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub
    echo
    echo "Active kernel command line:"
    cat /proc/cmdline
}

usage() {
    echo "Usage:"
    echo "  $SCRIPT_NAME diagnose"
    echo "  sudo $SCRIPT_NAME apply-amd [--yes]"
    echo "  sudo $SCRIPT_NAME apply-intel [--yes]"
    echo "  sudo $SCRIPT_NAME rollback [--yes]"
    echo "  $SCRIPT_NAME show"
}

case "${1:-}" in
    diagnose)      diagnose ;;
    apply-amd)     apply_amd ;;
    apply-intel)   apply_intel ;;
    rollback)      rollback ;;
    show)          show ;;
    help|-h|--help|"") usage ;;
    *)
        echo "Unknown command: $1"
        usage
        exit 1
        ;;
esac
