[License: MIT] https://opensource.org/licenses/MIT
https://img.shields.io/badge/License-MIT-yellow.svg

Fix RTX 5060 on Linux
====================

Documented fixes and workarounds for Linux systems where the NVIDIA RTX 5060
is not properly detected or initialized on Linux kernels 6.14 or newer.

------------------------------------------------------------

IMPORTANT NOTES
---------------
- This project is NOT affiliated with NVIDIA
- Use only if your RTX 5060 is NOT working correctly
- Changes affect GRUB / PCI subsystem parameters
- An automatic GRUB backup is created before any modification
- If your system is already working, no action is required

------------------------------------------------------------

HOW TO USE
----------

1) DIAGNOSIS (no system changes)

Runs checks for GPU, kernel, CPU, driver status and active boot parameters:

curl -s https://raw.githubusercontent.com/dereknux/linux-rtx5060-fix/main/rtx5060-linux-workaround.sh | bash -s diagnose

------------------------------------------------------------

EXAMPLE DIAGNOSIS OUTPUT
-----------------------
GPU: NVIDIA detected
Kernel: 6.14.0-37-generic
CPU: AMD
Driver: NVIDIA not responding
Problem: PCI BAR allocation error detected

Assessment:
Workaround may be required on this AMD system.
Suggested command: sudo ./rtx5060-linux-workaround.sh apply-amd

------------------------------------------------------------

2) IF THE DIAGNOSIS INDICATES AN AMD CPU

Apply the workaround for systems using AMD CPUs:

curl -s https://raw.githubusercontent.com/dereknux/linux-rtx5060-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-amd

Optional (skip confirmation prompt):

curl -s https://raw.githubusercontent.com/dereknux/linux-rtx5060-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-amd --yes

------------------------------------------------------------

3) IF THE DIAGNOSIS INDICATES AN INTEL CPU

Apply the workaround for systems using Intel CPUs:

curl -s https://raw.githubusercontent.com/dereknux/linux-rtx5060-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-intel

Optional (skip confirmation prompt):

curl -s https://raw.githubusercontent.com/dereknux/linux-rtx5060-fix/main/rtx5060-linux-workaround.sh | sudo bash -s apply-intel --yes

------------------------------------------------------------

WHAT THIS WORKAROUND DOES
-------------------------

For AMD CPUs:

Adds the following parameters to GRUB:
pci=realloc=off amd_iommu=off

Reason:
- pci=realloc=off works around a Linux kernel 6.14+ PCI BAR allocation issue affecting RTX 5060
- amd_iommu=off avoids IOMMU-related issues that may prevent proper device initialization on some AMD systems

------------------------------------------------------------

For Intel CPUs:

Adds the following parameter to GRUB:
pci=realloc=off

------------------------------------------------------------

DOCUMENTED CASES
----------------
See the CASES.md file for:
- documented real-world hardware combinations
- GRUB configuration examples (before/after)
- alternative solutions if the workaround is not required
- full rollback instructions

------------------------------------------------------------

REVERTING CHANGES
-----------------
To undo the workaround:
- edit /etc/default/grub
- remove the added parameters (pci=realloc=off and/or amd_iommu=off)
- run update-grub
- reboot the system

You can also restore the automatically created backup using:

sudo ./rtx5060-linux-workaround.sh rollback

------------------------------------------------------------

PROBLEMS OR QUESTIONS?
----------------------
Before opening an Issue:
- read CASES.md
- run the diagnosis command
- include the collected output in your report
