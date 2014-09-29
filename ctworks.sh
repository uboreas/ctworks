#!/bin/bash
#
#  crosstoolWorks, to speed up things ..
#  2014 <gokhanp@cmplx.net>
#

pkname="crosstool-ng"
dmgout="./disk.dmg"
mpoint="./disk"
dmgsize="10g"

ctpack=""
ctconf=""
ctvers=""
ctxarg=""
ctmake="make"
dotper="50"
ctwpwd=`pwd`

trap doclean EXIT

function doclean() {
   rm -f .p "${ctwpwd}/.p"
}

function oformat() {
   if [ "${3}" == "." ]; then
      echo -n " ${1} ${2} ."
      i="0"
      while read line; do
         if [ "$((${i} % ${dotper}))" == "0" ]; then
            echo -n "."
         fi
         i=`expr ${i} + 1`
      done
      echo " done"
   else
      echo " ${1} ${2}" | tr "~" "\n"
      rm -f .p
      while read line; do
         echo "   ${4}${line}"
         echo "${line}" >> .p
      done
   fi
}

function dmgerr() {
   if [ "${1}" == "stay" ]; then
      echo | oformat "!" "${2}"
      return
   fi
   echo | oformat "!" "${2}"
   exit
}

function dmgeject() {
   if [ ! -d "${mpoint}" ]; then
      dmgerr "${1}" "Disk ${dmgout} not mounted!"
   else
      hdiutil detach -force "${mpoint}"
   fi
   if [ "${mpoint}" != "/Volumes" ]; then
      rm -rf "${mpoint}"
   fi
}

function dmgattach() {
   if [ ! -f "${dmgout}" ]; then
      dmgerr "" "Disk Image ${dmgout} not found! Create it first.."
   elif [ -d "${mpoint}" ]; then
      dmgerr "${1}" "Disk ${dmgout} already mounted!"
   else
      if [ "${mpoint}" != "/Volumes" ]; then
         mkdir -p "${mpoint}"
      fi
      hdiutil attach -mountpoint "${mpoint}" "${dmgout}"
   fi
}

function dmgcreate() {
   hdiutil create ${dmgout} -ov -volname "${pkname}" -fs "Case-sensitive Journaled HFS+" -type UDIF -size "${dmgsize}"
   dmgattach
}

function gettool() {
   ls | grep "^crosstool" | awk -F ".tar" {'print $1'} | oformat ">" "Available packages;~" "-" " - "
   ctpack=`cat .p | tail -1`
   echo
   echo -n "   Please select package you want to use [${ctpack}] : "
   read cp
   if [ "${cp}" != "" ]; then
      ctpack="${cp}"
   fi
   ls configs | grep -v "\.config$" | oformat ">" "Available configurations;~" "-" " - "
   ctconf=`cat .p | head -1`
   echo
   echo -n "   Please select configuration you want to build [${ctconf}] : "
   read cc
   if [ "${cc}" != "" ]; then
      ctconf="${cc}"
   fi
}

function ctpatch() {
   pbase="../../patches/${1}"
   if [ -e "${pbase}.patch" ]; then
      patch -p1 < "${pbase}.patch" 2>&1 | oformat ">" "Applying ${1}.patch"
   fi
   if [ -e "${pbase}-${2}.patch" ]; then
      patch -p1 < "${pbase}-${2}.patch" 2>&1 | oformat ">" "Applying ${pbase}-${2}.patch"
   fi
   cbase="../../configs/${2}"
   if [ -f "${cbase}" ]; then
      echo | oformat ">" "Copying configuration ${cbase}" "."
      cp "${cbase}" .config
   fi
}

function ctbegin() {
   cd "${mpoint}"
   rm -rf "${ctpack}"
   tar -jxvf ../${ctpack}.tar.* 2>&1 | oformat ">" "Extracting ${ctpack} " "."
   cd crosstool*
   ctpatch "${ctpack}" "${ctconf}"
   ctxarg="--local"
   if [ "`echo "${ctpack}" | grep -- "-1\.2[0-9]+\."`" != "" ]; then
      ctxarg="--enable-local"
      ctvers="new"
   fi
}

function ctboot() {
   gp="/opt/local/bin"
   export sed="${gp}/gsed"
   export objcopy="${gp}/gobjcopy"
   export objdump="${gp}/gobjdump"
   export ranlib="${gp}/granlib"
   export readelf="${gp}/greadelf"
   export libtool="${gp}/glibtool"
   export libtoolize="${gp}/glibtoolize"
   ./configure \
      ${ctxarg} \
   | oformat ">" "Issuing configure .."
   if [ "`cat .p | grep "Bailing out"`" != "" ]; then
      echo
      exit
   fi
}

function ctballs() {
   bbase="../../tarballs"
   if [ ! -d "${bbase}" ]; then
      return
   fi
   mkdir -p .build/tarballs
   echo -n " > Copying tarballs "
   ls "${bbase}" | while read ball; do
      cp "${bbase}/${ball}" ./.build/tarballs/
      echo -n "."
   done
   echo " done"
}

function ctend() {
   td=`pwd | awk -F"${ctwpwd}" {'print $2'}`
   echo "
   cd .${td}
   ${ctmake}
   ./ct-ng menuconfig
   ulimit -n 2048
   ./ct-ng build
   " | oformat ">" "Please run below commands to build tools"
   cd ../..
}

function ctconfig() {
   dmgattach "stay"
   gettool
   ctbegin
   ctboot
   ctballs
   ctend
}

function cthelp() {
   echo "
  0. Change paths within *-*-uclibc files to point this \"configs\" directory like below:
	CT_LIBC_UCLIBC_CONFIG_FILE=`pwd`/configs/uClibc-*.config

  1. Create a case sensitive file system:
	> ${0} dmgcreate

  2. Run ctworks with \"config\" switch
	> ${0} config

  3. Select appropriate package

  4. Select desired configuration

  5. Follow the instructins displayed and wait for compilation.

  6. Copy tarballs from .build directory for later use;
	> cp `pwd`/disk/crosstool*/.build/tarballs/* `pwd`/tarballs/
 
  7. Find toolchain under \"disk\" folder and move it to your workspace

  8. Run ctworks with \"eject\" switch to unmount dmg file if you want to use it later.
	> ${0} eject

  9. Run ctworks with \"clean\" switch to delete dmg file completely.
	> ${0} clean
"
}

echo
if [ "${1}" == "eject" ]; then
   dmgeject
elif [ "${1}" == "attach" ]; then
   dmgattach
elif [ "${1}" == "create" ]; then
   dmgcreate
elif [ "${1}" == "clean" ]; then
   dmgeject "stay"
   rm -f "${dmgout}"
elif [ "${1}" == "config" ]; then
   ctconfig
elif [ "${1}" == "help" ]; then
   cthelp
else
   dmgerr "" "Nothing to do, try create|attach|detach|eject|clean|config|help"
fi
echo

