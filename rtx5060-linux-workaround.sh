#!/bin/bash
#
# rtx5060-linux-workaround.sh
#
# Diagnostic and minimal GRUB workaround for RTX 5060 issues
# on Linux kernels 6.14 or newer.
#

set -e

SCRIPT_NAME="rtx5060-linux-workaround.sh"
AUTO_CONFIRM="no"

# Parse options
for arg in "$@"; do
    case "$arg" in
        --yes)
            AUTO_CONFIRM="yes"
            ;;
    esac
done

has_cmdline_flag() {
    grep -qw "$1" /proc/cmdline
}

detect_nvidia() {
    if lspci | grep -qi "NVIDIA"; then
        echo "GPU: NVIDIA detected"
        return 0
    else
        echo "GPU: NVIDIA not detected"
        return 1
    fi
}

check_pci_error() {
    dmesg 2>/dev/null | grep -q "PCI I/O region.*invalid\|BAR0 is 0M"
}

backup_grub() {
    BACKUP_FILE="/etc/default/grub.backup-$(date +%Y%m%d-%H%M%S)"
    cp /etc/default/grub "$BACKUP_FILE"
    echo "Backup created: $BACKUP_FILE"
}

confirm() {
    if [ "$AUTO_CONFIRM" = "yes" ]; then
        return 0
    fi

    echo
    read -p "This will modify /etc/default/grub. Continue? [y/N]: " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "Aborted."
        exit 1
    fi
}

diagnose() {
    echo "RTX 5060 Linux Diagnostic"
    echo "========================="
    echo

    detect_nvidia || true

    KERNEL=$(uname -r)
    echo "Kernel: $KERNEL"

    if grep -qi "AuthenticAMD" /proc/cpuinfo; then
        CPU_VENDOR="AMD"
        echo "CPU: AMD"
    elif grep -qi "GenuineIntel" /proc/cpuinfo; then
        CPU_VENDOR="Intel"
        echo "CPU: Intel"
    else
        CPU_VENDOR="Unknown"
        echo "CPU: Unknown"
    fi

    if command -v nvidia-smi >/dev/null 2>&1 && timeout 2 nvidia-smi >/dev/null 2>&1; then
        DRIVER_OK="yes"
        echo "Driver: NVIDIA responding"
    else
        DRIVER_OK="no"
        echo "Driver: NVIDIA not responding"
        if check_pci_error; then
            echo "Problem: PCI BAR allocation error detected"
        fi
    fi

    echo
    echo "Boot parameters:"
    has_cmdline_flag "pci=realloc=off" && echo "  pci=realloc=off (active)"
    has_cmdline_flag "amd_iommu=off"   && echo "  amd_iommu=off (active)"
    has_cmdline_flag "iommu=off"       && echo "  iommu=off (active)"
    has_cmdline_flag "iommu=soft"      && echo "  iommu=soft (active)"

    echo
    echo "Assessment:"

    if [ "$DRIVER_OK" = "yes" ] && has_cmdline_flag "pci=realloc=off"; then
        echo "System already running with workaround applied."
        echo "No action required."
        exit 0
    fi

    if [ "$DRIVER_OK" = "no" ]; then
        if [ "$CPU_VENDOR" = "AMD" ]; then
            echo "Workaround may be required on this AMD system."
            echo "Suggested command: sudo ./$SCRIPT_NAME apply-amd"
        elif [ "$CPU_VENDOR" = "Intel" ]; then
            echo "Workaround may be required on this Intel system."
            echo "Suggested command: sudo ./$SCRIPT_NAME apply-intel"
        else
            echo "CPU vendor unknown. Manual investigation recommended."
        fi
    else
        echo "System appears functional. No changes suggested."
    fi

    echo
    echo "For detailed cases, see CASES.md"
}

apply_amd() {
    if has_cmdline_flag "pci=realloc=off" && has_cmdline_flag "amd_iommu=off"; then
        echo "Workaround already active. Nothing to do."
        exit 0
    fi

    echo "Applying workaround for AMD CPU systems"
    echo
    echo "This will add to GRUB:"
    echo "  pci=realloc=off amd_iommu=off"
    echo
    echo "Reason:"
    echo "  - pci=realloc=off fixes kernel 6.14+ PCI BAR allocation issues"
    echo "  - amd_iommu=off avoids IOMMU-related USB failures on some AMD systems"
    echo

    confirm
    backup_grub

    CURRENT=$(grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub)

    if echo "$CURRENT" | grep -q 'pci=realloc=off'; then
        sed -i 's|pci=realloc=off|pci=realloc=off amd_iommu=off|' /etc/default/grub
    else
        sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"|GRUB_CMDLINE_LINUX_DEFAULT="\1 pci=realloc=off amd_iommu=off"|' /etc/default/grub
    fi

    echo
    echo "Updated GRUB configuration:"
    grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub

    update-grub
    echo
    echo "Workaround applied. Reboot the system."
}

apply_intel() {
    if has_cmdline_flag "pci=realloc=off"; then
        echo "Workaround already active. Nothing to do."
        exit 0
    fi

    echo "Applying workaround for Intel CPU systems"
    echo
    echo "This will add to GRUB:"
    echo "  pci=realloc=off"
    echo
    echo "Reason:"
    echo "  - pci=realloc=off fixes kernel 6.14+ PCI BAR allocation issues"
    echo

    confirm
    backup_grub

    sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"|GRUB_CMDLINE_LINUX_DEFAULT="\1 pci=realloc=off"|' /etc/default/grub

    echo
    echo "Updated GRUB configuration:"
    grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub

    update-grub
    echo
    echo "Workaround applied. Reboot the system."
}

rollback() {
    BACKUP=$(ls -t /etc/default/grub.backup-* 2>/dev/null | head -1)

    if [ -z "$BACKUP" ]; then
        echo "No backup found. Manual rollback required."
        exit 1
    fi

    echo "Restoring GRUB configuration from backup:"
    echo "  $BACKUP"
    echo

    confirm
    cp "$BACKUP" /etc/default/grub
    update-grub
    echo
    echo "Rollback complete. Reboot the system."
}

show_current() {
    echo "Current GRUB configuration:"
    echo
    grep '^GRUB_CMDLINE_LINUX_DEFAULT=' /etc/default/grub
    echo
    echo "Active kernel parameters:"
    cat /proc/cmdline
}

usage() {
    echo "RTX 5060 Linux Workaround"
    echo "========================="
    echo
    echo "Usage:"
    echo "  ./$SCRIPT_NAME diagnose"
    echo "  sudo ./$SCRIPT_NAME apply-amd [--yes]"
    echo "  sudo ./$SCRIPT_NAME apply-intel [--yes]"
    echo "  sudo ./$SCRIPT_NAME rollback [--yes]"
    echo "  ./$SCRIPT_NAME show"
    echo
}

case "$1" in
    diagnose)
        diagnose
        ;;
    apply-amd)
        apply_amd
        ;;
    apply-intel)
        apply_intel
        ;;
    rollback)
        rollback
        ;;
    show)
        show_current
        ;;
    help|--help|-h)
        usage
        ;;
    *)
        echo "Unknown command: $1"
        echo
        usage
        exit 1
        ;;
esac
