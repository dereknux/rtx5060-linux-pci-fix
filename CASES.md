Documented Cases - RTX 5060 on Linux
===================================

This file documents real hardware configurations where RTX 5060
fails to initialize correctly on Linux kernels 6.14 or newer,
along with the applied fixes.

------------------------------------------------------------

CASE 1: AMD CPU + Kernel 6.14+
-----------------------------

Symptoms:
- nvidia-smi does not detect the GPU
- System boots normally
- USB devices may work initially
- NVIDIA driver is installed but non-functional

Diagnosis output usually reports:
- PCI BAR allocation failure
- NVIDIA driver not responding

Applied fix:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off amd_iommu=off"

Required driver:
nvidia-driver 590 (open or proprietary)

Explanation:
- Kernel 6.14+ fails to correctly reallocate PCI BAR space for RTX 5060
- AMD IOMMU interferes with BAR reassignment and may break USB
- Disabling IOMMU avoids the conflict on affected systems

Status:
- Confirmed working on multiple AMD Ryzen platforms

------------------------------------------------------------

CASE 2: Intel CPU + Kernel 6.14+
-------------------------------

Symptoms:
- nvidia-smi fails
- System boots normally
- USB devices unaffected

Applied fix:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off"

Explanation:
- PCI BAR allocation bug affects RTX 5060
- Intel systems do not require disabling IOMMU

Status:
- Confirmed working on Intel desktop platforms

------------------------------------------------------------

CASE 3: Kernel 6.8 or Older
--------------------------

Status:
- Not affected

Action:
- Install NVIDIA driver normally (version 550 or newer)

------------------------------------------------------------

COMMON ISSUE: USB stops working after applying fix
--------------------------------------------------

Cause:
- Disabling AMD IOMMU can break USB on some systems

Solution:
- Use only:
  GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off"

- Do NOT disable amd_iommu unless required

------------------------------------------------------------

ROLLBACK INSTRUCTIONS
---------------------

To revert any applied fix:

1) Edit the GRUB configuration file:
   /etc/default/grub

2) Remove the added parameters:
   pci=realloc=off
   amd_iommu=off

3) Update GRUB and reboot:
   update-grub
   reboot

You may also restore the automatic backup created before applying the fix.

------------------------------------------------------------

NOTES
-----

- These cases document observed behavior, not official vendor guidance
- Hardware revisions and BIOS versions may affect results
- If your case differs, run the diagnostic mode and open an Issue
