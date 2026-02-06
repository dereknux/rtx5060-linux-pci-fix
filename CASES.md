Documented Cases - RTX 5060 on Linux
===================================

This file documents real hardware configurations where the NVIDIA RTX 5060
may fail to initialize correctly on Linux kernels 6.14 or newer, along with
the observed behavior and applied workarounds.

------------------------------------------------------------

CASE 1: AMD CPU + Kernel 6.14+ (Driver Fails)
---------------------------------------------

Symptoms:
- nvidia-smi does not detect the GPU
- System boots normally
- NVIDIA driver is installed but non-functional
- USB devices may work initially

Diagnosis typically reports:
- PCI BAR allocation failure
- NVIDIA driver not responding

Applied workaround:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off amd_iommu=off"

Required driver:
nvidia-driver 590 (open or proprietary)

Explanation:
- Kernel 6.14+ may fail to reallocate PCI BAR space for RTX 5060
- AMD IOMMU can interfere with BAR reassignment
- Disabling IOMMU avoids the conflict on affected systems

Status:
- Confirmed working on multiple AMD Ryzen platforms

------------------------------------------------------------

CASE 2: Intel CPU + Kernel 6.14+ (Driver Fails)
-----------------------------------------------

Symptoms:
- nvidia-smi fails
- System boots normally
- USB devices unaffected

Applied workaround:
GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off"

Explanation:
- PCI BAR allocation bug affects RTX 5060
- Intel systems do not require disabling IOMMU

Status:
- Confirmed working on Intel desktop platforms

------------------------------------------------------------

CASE 3: AMD CPU + Kernel 6.14+ (Working with Workaround Applied)
----------------------------------------------------------------

Symptoms:
- NVIDIA driver loads correctly
- nvidia-smi responds
- OpenGL and desktop use the GPU normally

Observation:
- System is already booting with pci=realloc=off enabled
- No PCI BAR errors observed in dmesg

Conclusion:
- System is affected by the kernel issue
- Proper operation depends on the active workaround
- No further action required while workaround remains active

Status:
- Confirmed working state with workaround applied

------------------------------------------------------------

CASE 4: Kernel 6.8 or Older
--------------------------

Status:
- Not affected

Action:
- Install NVIDIA driver normally (version 550 or newer)

------------------------------------------------------------

COMMON ISSUE: USB stops working after applying workaround
---------------------------------------------------------

Cause:
- Disabling AMD IOMMU can break USB on some systems

Solution:
- Use only:
  GRUB_CMDLINE_LINUX_DEFAULT="quiet splash pci=realloc=off"

- Do NOT disable amd_iommu unless required

------------------------------------------------------------

ROLLBACK INSTRUCTIONS
---------------------

To revert any applied workaround:

1) Edit the GRUB configuration file:
   /etc/default/grub

2) Remove the added parameters:
   pci=realloc=off
   amd_iommu=off

3) Update GRUB and reboot:
   update-grub
   reboot

You may also restore the automatic backup created by the script.

------------------------------------------------------------

NOTES
-----

- These cases document observed behavior, not official vendor guidance
- Hardware revisions and BIOS versions may affect results
- A working system does not imply absence of the issue
- If behavior differs, run the diagnostic mode and open an Issue
