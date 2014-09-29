# crosstoolWorks
Patches and configurations to build Linaro's toolchains on OS X 10.9 (Mavericks) host system.
This initial version provides OSX patch for Linaro 14.08 Release. Patches for further releases may be added to this repository (if required).

## Notes
* Patch files located under "patches" directory and named as (crosstool-package-version).patch
* ctworks script applies patches automatically according to selected crosstool-ng package.
* Packages under "tarballs" directory automatically copied into the crosstool's .build/tarballs directory (to prevent re-downloading them).
* You can place different packages and patches to work together.

## Toolchains Built and Tested
    arm-linux-gnueabi
        Tested with S5PV210, Cortex-A8, 32-bit LSB, Linux 2.6.35.7
    arm-linux-gnueabihf-raspbian
        Tested on Raspberry Pi, Model-B, 32-bit LSB, Linux 3.6.11
    mips-linux-uclibc
        Tested on Carambola2 (Atheros AR9330, MIPS 24Kc V7.4), 32-bit MSB, Linux 3.7.9
    mipsel-linux-uclibc
        Tested with Ralink RT5350, MIPS 24KEc V4.12, 32-bit LSB, Linux 3.3.8
    x86_64-linux-gnu
        Tested on Ubuntu VM, 64-bit LSB

## Before Begin
Download crosstool-NG package from Linaro 14.08 release;

	cd /path/to/ctworks
	wget "http://releases.linaro.org/14.08/components/toolchain/binaries/crosstool-ng-linaro-1.13.1-4.9-2014.08.tar.bz2"

## Usage
  0. Change paths within x-x-uclibc files to point this "configs" directory like below:

	CT_LIBC_UCLIBC_CONFIG_FILE=/path/to/ctworks/configs/uClibc-x.x.config

  1. Create a case sensitive file system:

	./ctworks.sh dmgcreate

  2. Run ctworks with "config" switch

	./ctworks.sh config

  3. Select appropriate package

  4. Select desired configuration

  5. Follow the instructins displayed and wait for compilation.

  6. Copy tarballs from .build directory for later use;

	cp /path/to/ctworks/disk/crosstool*/.build/tarballs/* /path/to/ctworks/tarballs/
 
  7. Find toolchain under "disk" folder and move it to your workspace

  8. Run ctworks with "eject" switch to unmount dmg file if you want to use it later.

	./ctworks.sh eject

  9. Run ctworks with "clean" switch to delete dmg file completely.

	./ctworks.sh clean

## Linaro Resources
14.08 Release
> https://wiki.linaro.org/Cycles/1408/Release

Linux and Windows Binaries
> http://releases.linaro.org/14.08/components/toolchain/binaries/

crosstool-NG package from 14.08 Release
> http://releases.linaro.org/14.08/components/toolchain/binaries/crosstool-ng-linaro-1.13.1-4.9-2014.08.tar.bz2

