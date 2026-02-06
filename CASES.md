CASES.md - RTX 5060 on Linux
===========================

This document describes real hardware configurations where the RTX 5060
fails or may fail to initialize correctly on Linux kernels 6.14+,
along with tested workarounds.

------------------------------------------------------------

CASE 1: AMD CPU + Kernel 6.14+ (Driver Failure)
-----------------------------------------------

Symptoms:
- nvidia-smi fails to communicate with the driver
- System boots normally
- NVIDIA driver is installed but non-functional

Observed logs:
- PCI BAR allocation errors
- NVIDIA probe failure

Workaround:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off amd_iommu=off"

Explanation:
- Kernel 6.14+ may fail to reallocate PCI BAR space for RTX 5060
- AMD IOMMU interferes with PCI reallocation on affected systems

Status:
- Confirmed working on multiple AMD Ryzen platforms

------------------------------------------------------------

CASE 2: Intel CPU + Kernel 6.14+ (Driver Failure)
-------------------------------------------------

Symptoms:
- nvidia-smi fails
- System boots normally
- USB devices unaffected

Workaround:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off"

Explanation:
- Same PCI BAR allocation issue
- Intel systems do not require IOMMU changes

Status:
- Confirmed working on Intel desktop systems

------------------------------------------------------------

CASE 3: AMD CPU + Kernel 6.14+ (Working With Workaround)
--------------------------------------------------------

Symptoms:
- NVIDIA driver loads correctly
- nvidia-smi responds
- Desktop and OpenGL work normally

Observation:
- System is already booting with pci=realloc=off enabled

Conclusion:
- System is affected by the kernel issue
- Proper operation depends on the active workaround

------------------------------------------------------------

CASE 4: Kernel 6.8 or Older
--------------------------

Status:
- Not affected

Action:
- Install NVIDIA driver normally (version 550 or newer)

------------------------------------------------------------

COMMON ISSUE: USB stops working after workaround
-------------------------------------------------

Cause:
- amd_iommu=off may break USB on some AMD systems

Solution:
- Use only:
  GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off"

------------------------------------------------------------

ROLLBACK
--------

Manual:
- Remove added GRUB parameters
- Run update-grub
- Reboot

Script-based:
sudo ./rtx5060-linux-workaround.sh rollback

------------------------------------------------------------

NOTES
-----
- This documents observed behavior, not vendor guidance
- BIOS versions and hardware revisions may affect results
- A working system does not imply absence of the issue
