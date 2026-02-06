[License: MIT] https://opensource.org/licenses/MIT
https://img.shields.io/badge/License-MIT-yellow.svg

Fix RTX 5060 on Linux
====================

Documented fixes for Linux systems where the NVIDIA RTX 5060
is not properly detected on Linux kernels 6.14 or newer.

------------------------------------------------------------

IMPORTANT NOTES
---------------
- This project is NOT affiliated with NVIDIA
- Use only if your RTX 5060 is NOT working correctly
- Changes affect GRUB / PCI subsystem parameters
- An automatic GRUB backup is created before any modification

------------------------------------------------------------

HOW TO USE
----------

1) DIAGNOSIS (no system changes)

Runs checks for GPU, kernel, CPU and NVIDIA driver status:

curl -s https://raw.githubusercontent.com/dereknux/linux-rtx5060-fix/main/rtx5060-linux-workaround.sh | bash -s diagnose

------------------------------------------------------------

EXAMPLE DIAGNOSIS OUTPUT
-----------------------
GPU: RTX 5060 detected
Kernel: 6.14.0-37-generic
CPU: AMD Ryzen
Driver: NVIDIA not responding
Problem: PCI BAR allocation bug detected
Recommendation: Use apply-amd

------------------------------------------------------------

2) IF THE DIAGNOSIS INDICATES AN AMD CPU

Apply the fix for systems using AMD CPUs:

curl -s https://raw.githubusercontent.com/dereknux/linux-rtx5060-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-amd

------------------------------------------------------------

3) IF THE DIAGNOSIS INDICATES AN INTEL CPU

Apply the fix for systems using Intel CPUs:

curl -s https://raw.githubusercontent.com/dereknux/linux-rtx5060-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-intel

------------------------------------------------------------

WHAT THIS FIX DOES
------------------

For AMD CPUs:

Adds the following parameters to GRUB:
pci=realloc=off amd_iommu=off

Reason:
- pci=realloc=off fixes a Linux kernel 6.14+ bug related to PCI BAR allocation on RTX 5060
- amd_iommu=off avoids a known AMD IOMMU issue that may break USB devices

------------------------------------------------------------

For Intel CPUs:

Adds the following parameter to GRUB:
pci=realloc=off

------------------------------------------------------------

DOCUMENTED CASES
----------------
See the CASES.md file for:
- complete step-by-step instructions
- real GRUB configuration examples (before/after)
- alternative solutions if something does not work
- full rollback instructions

------------------------------------------------------------

REVERTING CHANGES
-----------------
To undo the fix:
- edit /etc/default/grub
- remove the added parameters (pci=realloc=off and/or amd_iommu=off)
- run update-grub
- reboot the system

You can also manually restore the automatically created backup.

------------------------------------------------------------

PROBLEMS OR QUESTIONS?
----------------------
Before opening an Issue:
- read CASES.md
- run the diagnosis
- include the collected information in your report
