Fix RTX 5060 on Linux (PCI BAR / GRUB Workaround)
================================================

Documented workarounds for Linux systems where the NVIDIA RTX 5060
fails to initialize correctly on Linux kernels 6.14 or newer.
The issue is typically related to PCI BAR allocation and IOMMU
behavior on affected platforms.

Repository:
https://github.com/dereknux/rtx5060-linux-pci-fix

License:
MIT

------------------------------------------------------------

IMPORTANT NOTES
---------------
- This project is NOT affiliated with NVIDIA
- Use only if your RTX 5060 is NOT working correctly
- This is a documented workaround, not a kernel patch
- Changes affect GRUB / PCI subsystem parameters
- An automatic GRUB backup is created before any modification
- If your system is already working, no action is required

------------------------------------------------------------

HOW TO USE
----------

1) DIAGNOSIS (no system changes)

Run a diagnostic to check GPU detection, kernel version,
CPU vendor, driver status and active boot parameters:

curl -s https://raw.githubusercontent.com/dereknux/rtx5060-linux-pci-fix/main/rtx5060-linux-workaround.sh | bash -s diagnose

------------------------------------------------------------

EXAMPLE DIAGNOSIS OUTPUT (one possible scenario)
------------------------------------------------
GPU: NVIDIA detected
Kernel: 6.14.0-37-generic
CPU: AMD
Driver: NVIDIA not responding
Problem: PCI BAR allocation error detected

Assessment:
Workaround may be required on this AMD system.
Suggested command: sudo ./rtx5060-linux-workaround.sh apply-amd

------------------------------------------------------------

2) AMD CPU SYSTEMS

Apply the workaround for AMD-based systems:

curl -s https://raw.githubusercontent.com/dereknux/rtx5060-linux-pci-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-amd

Optional (skip confirmation):

curl -s https://raw.githubusercontent.com/dereknux/rtx5060-linux-pci-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-amd --yes

Important note for AMD systems:
- On some AMD platforms, using only pci=realloc=off is NOT sufficient
- Systems may boot or appear functional temporarily, but fail after GRUB normalization
- If the NVIDIA driver fails after reboot, amd_iommu=off is REQUIRED

------------------------------------------------------------

3) INTEL CPU SYSTEMS

Apply the workaround for Intel-based systems:

curl -s https://raw.githubusercontent.com/dereknux/rtx5060-linux-pci-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-intel

Optional (skip confirmation):

curl -s https://raw.githubusercontent.com/dereknux/rtx5060-linux-pci-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-intel --yes

------------------------------------------------------------

WHAT THIS WORKAROUND DOES
-------------------------

AMD systems:
- Ensures the following GRUB parameters are set:
  pci=realloc=off amd_iommu=off

- pci=realloc=off works around a kernel 6.14+ PCI BAR allocation issue
- amd_iommu=off avoids IOMMU-related conflicts observed on some AMD systems
- In affected setups, both parameters are required for driver stability

Intel systems:
- Ensures the following GRUB parameter is set:
  pci=realloc=off

- Intel systems do not require IOMMU changes

------------------------------------------------------------

DOCUMENTED CASES
----------------
See CASES.md for:
- real-world hardware combinations
- confirmed failure and recovery scenarios
- GRUB configuration examples (before/after)
- alternative approaches for edge cases
- full rollback instructions

------------------------------------------------------------

REVERTING CHANGES
-----------------
Manual rollback:
- Edit /etc/default/grub
- Remove added parameters
- Run update-grub
- Reboot

Automatic rollback using the script:

sudo ./rtx5060-linux-workaround.sh rollback

------------------------------------------------------------

PROBLEMS OR QUESTIONS?
----------------------
Before opening an Issue:
- read CASES.md
- run the diagnostic command
- include the collected output
