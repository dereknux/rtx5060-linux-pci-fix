CASES.md — RTX 5060 on Linux
===========================

This document describes real-world hardware configurations where the
NVIDIA RTX 5060 fails to initialize correctly on Linux kernels 6.14+,
along with confirmed workarounds.

------------------------------------------------------------

CASE 1: AMD CPU + Kernel 6.14+ (Requires Full Workaround)
---------------------------------------------------------

Hardware:
- CPU: AMD (Ryzen-based systems)
- GPU: NVIDIA RTX 5060
- Kernel: 6.14.x
- Driver: NVIDIA 590.xx

Symptoms:
- System boots normally
- NVIDIA driver fails to initialize
- nvidia-smi reports communication failure
- Removing or simplifying GRUB parameters breaks the driver after reboot

Observed behavior:
- System may appear functional when parameters are partially present
- Normalizing GRUB or removing amd_iommu=off causes driver failure
- Driver only works reliably when both parameters are active

Confirmed workaround:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off amd_iommu=off"

Explanation:
- Kernel 6.14+ may fail to reallocate PCI BAR space for RTX 5060
- On affected AMD systems, IOMMU interferes with BAR reassignment
- Disabling AMD IOMMU is required for stable driver initialization

Status:
- Confirmed working
- System remains stable across reboots only with full workaround

------------------------------------------------------------

CASE 2: AMD CPU + Kernel 6.14+ (Partial Workaround Insufficient)
----------------------------------------------------------------

Symptoms:
- pci=realloc=off alone allows temporary or partial functionality
- After reboot or GRUB normalization, NVIDIA driver stops responding

Conclusion:
- pci=realloc=off alone is NOT sufficient on some AMD platforms
- amd_iommu=off is mandatory in these cases

------------------------------------------------------------

CASE 3: Intel CPU + Kernel 6.14+
--------------------------------

Hardware:
- CPU: Intel
- GPU: NVIDIA RTX 5060
- Kernel: 6.14+

Symptoms:
- nvidia-smi fails
- System boots normally
- No USB or IOMMU-related side effects

Confirmed workaround:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off"

Explanation:
- Same PCI BAR allocation issue affects RTX 5060
- Intel systems do not require IOMMU changes

Status:
- Confirmed working

------------------------------------------------------------

CASE 4: Kernel 6.8 or Older
---------------------------

Status:
- Not affected

Action:
- Install NVIDIA driver normally (550+)
- No GRUB workaround required

------------------------------------------------------------

COMMON ISSUE: USB problems on AMD systems
-----------------------------------------

Cause:
- Disabling AMD IOMMU can affect USB controllers on some platforms

Notes:
- This issue was NOT observed on all AMD systems
- When required for RTX 5060 stability, amd_iommu=off takes precedence

------------------------------------------------------------

ROLLBACK
--------

Automatic rollback:
sudo ./rtx5060-linux-workaround.sh rollback

Manual rollback:
- Edit /etc/default/grub
- Remove added parameters
- Run update-grub
- Reboot

------------------------------------------------------------

NOTES
-----

- These cases document observed behavior, not vendor guidance
- A system working without the workaround does not imply it is unaffected
- Some systems require the workaround to survive reboot and GRUB cleanup
- Hardware revisions and BIOS versions may affect results
