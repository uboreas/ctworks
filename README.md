# crosstool-works
Patches and configurations to build Linaro toolchains on OS X (>=10.9) host systems.
This version provides crosstool-ng patches for various Linaro releases and for target platforms. Patches for further releases may be added to this repository.

## Notes
* Patch files located under "patches" directory and named as (crosstool-ng-linaro-version-release).patch
* ctworks.sh script applies patches automatically according to selected crosstool-ng package.
* You can configure ctworks to use with different releases (and patches).

## Toolchains Built and Tested
    arm-linux-gnueabi
        Tested with S5PV210, Cortex-A8, 32-bit LSB, Linux 2.6.35.7
    arm-linux-gnueabihf-raspbian
        Tested with Raspberry Pi, Model-B, 32-bit LSB, Linux 3.6.11
    mips-linux-uclibc
        Tested with Carambola2 (Atheros AR9330, MIPS 24Kc V7.4), 32-bit MSB, Linux 3.7.9
    mipsel-linux-uclibc
        Tested with Ralink RT5350, MIPS 24KEc V4.12, 32-bit LSB, Linux 3.3.8
    x86_64-linux-gnu
        Tested with Ubuntu VM, 64-bit LSB
    aarch64-linux-gnu
        Tested with Amlogic-S905, 64-bit LSB

## Usage
  * Download crosstool-ng packages from Linaro releases storage server (http://releases.linaro.org)

	> ./ctworks.sh get

  * Create case sensitive file system in a disk image (or you may use existing one):

	> ./ctworks.sh create|attach

  * Run with "prepare" switch to extract crosstool-ng package and apply patches etc.

	> ./ctworks.sh prepare

  * Run with "config" switch to configure crosstool-ng and follow instructions displayed to build toolchain

	> ./ctworks.sh configure

  * Run with "eject" switch to unmount disk image.

	> ./ctworks.sh eject

  * Notes:

   - You may edit ctworks.config file to change your previously saved ctworks-configuration
     If you remove some lines from this file, it will be asked again.

   - You may need to restart from a step when something goes wrong;
     ./ct-ng list-steps
     RESTART=libc_start_files ./ct-ng build

### Prerequisites

* Xcode and Command line tools

	> xcode-select --install

* MacPorts should be installed. Required ports as follows (openwrt requires some of them also);

	> sudo port install binutils gawk gsed grep gnutar gmake file findutils unrar wget coreutils e2fsprogs ossp-uuid asciidoc fastjar flex getopt gtk2 intltool jikes hs-zlib p5-extutils-makemaker python26 rsync ruby sdcc unzip bison autoconf help2man

- ln -s /path/to/ports/bin/gsed /path/to/ports/bin/sed

### Resources

	http://releases.linaro.org/
	https://developer.apple.com/library/ios/technotes/tn2339/_index.html
	https://www.macports.org/install.php

### Testbed

	$ uname -a
	Darwin gPro.local 15.5.0 Darwin Kernel Version 15.5.0: Tue Apr 19 18:36:36 PDT 2016; root:xnu-3248.50.21~8/RELEASE_X86_64 x86_64
	$ gcc --version
	Configured with: --prefix=/Applications/Xcode.app/Contents/Developer/usr --with-gxx-include-dir=/usr/include/c++/4.2.1
	Apple LLVM version 7.3.0 (clang-703.0.31)
	Target: x86_64-apple-darwin15.5.0
	Thread model: posix
	InstalledDir: /Applications/Xcode.app/Contents/Developer/Toolchains/XcodeDefault.xctoolchain/usr/bin
	$ /opt/local/bin/port version
	Version: 2.3.4

#### Enjoy!
