#!/bin/bash
#
#  crosstool-works, to speed up things ..
#  2014 <gokhan@clxdev.net>
#

ctwpwd=`pwd`
confile="${ctwpwd}/ctworks.config"
relfile="${ctwpwd}/ctworks.releases"

dotper="50"

mkdir -p tarballs
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

function readarg() {
   cf="${confile}"
   if [ "${cf}" == "" ]; then
      return
   fi
   if [ ! -e "${cf}" ]; then
      return
   fi
   cs="${1}"
   __rc=`cat "${cf}" | grep "^${cs}=" | awk -F"${cs}=" {'print $2'}`
   if [ "${__rc}" != "" ]; then
      eval "${1}='${__rc}'"
   fi
}

function getarg() {
   cf="${confile}"
   if [ "${cf}" != "" ]; then
      if [ ! -e "${cf}" ]; then
         echo "#" > "${cf}"
         echo "# ctworks configuratin file" >> "${cf}"
         echo "#" >> "${cf}"
         echo >> "${cf}"
      fi
      cs="${1}"
      __rc=`cat "${cf}" | grep "^${cs}=" | awk -F"${cs}=" {'print $2'}`
      if [ "${__rc}" != "" ]; then
         echo " > ${2} [${__rc}]"
         eval "${1}='${__rc}'"
         return
      fi
   fi
   __rc="${4}"
   echo -n " > ${2} "
   if [ "${4}" != "" ]; then
      echo -n "[${4}${5}]: "
   else
      echo -n ": "
   fi
   __q=""
   if [ "${3}" == "pass" ]; then
      stty -echo
      read __q
      stty echo
   else
      read __q
   fi
   if [ "${__q}" != "" ]; then
     __rc="${__q}"
   fi
   if [ "${3}" == "must" -o "${3}" == "pass" ]; then
      if [ "${__rc}" == "" ]; then
         echo " ! Can't continue .."
         echo
         exit
      fi
   fi
   if [ "${cf}" != "" ]; then
      cs="${1}"
      __xc=`cat "${cf}" | grep "^${cs}="`
      if [ "${__xc}" != "" ]; then
         cat "${cf}" | grep -v "^${cs}=" > .tt
         mv .tt "${cf}"
      fi
      echo "${cs}=${__rc}" >> "${cf}"
   fi
   eval "${1}='${__rc}'"
}

function dmgeject() {
   readarg mount_point
   if [ "${mount_point}" == "" -o "${1}" == "" ]; then
      getarg mount_point "Mount point" "must" "disk"
   fi
   if [ "`mount | grep "${ctwpwd}/${mount_point}"`" == "" ]; then
      echo " > DMG not mounted."
   else
      hdiutil detach -force "./${mount_point}" | oformat
   fi
}

function dmgcreate() {
   readarg dmg
   if [ "${dmg}" == "" -o "${1}" == "" ]; then
      getarg dmg "DMG file to create" "must" "disk.dmg"
   fi
   if [ -e "${dmg}" ]; then
      echo " ! DMG file (${dmg}) already exist."
      return
   fi
   readarg dmgsize
   if [ "${dmgsize}" == "" -o "${1}" == "" ]; then
      getarg dmgsize "Please specify DMG size" "must" "10g"
   fi
   readarg mount_point
   if [ "${mount_point}" == "" -o "${1}" == "" ]; then
      getarg mount_point "Mount point" "must" "disk"
   fi
   if [ "`mount | grep "${ctwpwd}/${mount_point}"`" != "" ]; then
      echo " > Mount point (${mount_point}) not available (already mounted)."
      return
   fi
   hdiutil create ./${dmg} -ov -volname "crosstool-ng" -fs "Case-sensitive Journaled HFS+" -type UDIF -size "${dmgsize}" | oformat
   sync
}

function dmgattach() {
   getarg dmg "DMG file to use" "must" "disk.dmg"
   getarg mount_point "Mount point" "must" "disk"
   if [ "`mount | grep "${ctwpwd}/${mount_point}"`" != "" ]; then
      echo " > Disk ${dmg} already mounted."
      return
   fi
   if [ ! -f "${dmg}" ]; then
      dmgcreate "noask"
      sleep 1
      sync
   fi
   if [ "`mount | grep "${ctwpwd}/${mount_point}"`" != "" ]; then
      echo " > Disk ${dmg} already mounted."
      return
   fi
   mkdir -p "${mount_point}"
   hdiutil attach -mountpoint "./${mount_point}" "./${dmg}" | oformat
   echo
}

function gethash() {
   cat "${relfile}" | grep "^${1};" | awk -F";" {'print $2'}
}
function geturl() {
   cat "${relfile}" | grep "^${1};" | awk -F";" {'print $3'}
}

function getpkg() {
   geturl "${1}" | awk -F"/" {'print $NF'}
}

function getrel() {
   pkg=`getpkg "${1}"`
   if [ "${pkg}" == "" ]; then
     echo " ! Specified release(${1}) not found."
     exit
   fi
   if [ -e "${pkg}" ]; then
     if [ "`gethash "${1}"`" == "`md5 ${pkg} | awk -F" = " {'print $2'}`" ]; then
        if [ "${2}" == "silent" ]; then
           return 1
        fi
        echo " > Package ${pkg} for release(${1}) already exist."
        echo
        exit
     fi
   fi
   wget --progress=dot "`geturl "${1}"`" -O "${pkg}" 2>&1 | oformat ">" "Downloading ${pkg}
"
   return 0
}

function gettool() {
   cat "${relfile}" | awk -F ";" {'print $1'} | oformat ">" "Supported Linaro releases;~" "-" " - "
   release=`cat .p | tail -1`
   echo
   getarg release "Please select release you want to use" "must" "${release}"
   while true; do
      getrel "${release}" "silent"
      if [ "${?}" == "1" ]; then
         break
      fi
   done
   ls configs/${release}-* | grep -v "\.config$" | awk -F"/" {'print $NF'} | oformat ">" "Available configurations;~" "-" " - "
   build_config=`cat .p | tail -1`
   echo
   getarg build_config "Please select configuration you want to build" "must" "${build_config}"
}

function ctpatch() {
   echo
   getarg patch "Shall I apply ctwork patches?" "must" "Y" "/n"
   readarg build_config
   if [ "${patch}" == "y" -o "${q}" == "Y" -o "${q}" == "" ]; then
      pbase="${ctwpwd}/patches/${1}"
      if [ -e "${pbase}.patch" ]; then
         patch -p1 < "${pbase}.patch" 2>&1 | oformat "-" "Applying ${1}.patch"
      fi
      if [ -e "${pbase}-${build_config}.patch" ]; then
         patch -p1 < "${pbase}-${build_config}.patch" 2>&1 | oformat ">" "Applying ${pbase}-${build_config}.patch"
      fi
   fi
   echo
}

function ctcpcf() {
   readarg build_config
   cbase="${ctwpwd}/configs/${build_config}"
   if [ -f "${cbase}" ]; then
      echo | oformat ">" "Copying configuration ${cbase}" "."
      np=`echo "${ctwpwd}" | sed 's/\\//\\\\\\//g'`
      echo "cat '${cbase}' | sed 's/__CTWORKS_DIR__/${np}/g' > .config" > .ctcpcf
      source .ctcpcf
      rm -f .ctcpcf
   fi
}

function ctprepare() {
   gettool
   readarg release
   dmgattach
   readarg mount_point
   cd "${mount_point}"
   pkg=`getpkg "${release}"`
   pkd=`echo "${pkg}" | awk -F"\.tar" {'print $1'}`
   rm -rf "${pkd}"
   tar -jxvf ../${pkg} 2>&1 | oformat ">" "Extracting ${pkg} " "."
   cd "${pkd}"
   ctpatch "${pkd}"
   ctcpcf
}

function ctconfig() {
   gettool
   readarg release
   dmgattach
   readarg mount_point
   cd "${mount_point}"
   pkg=`getpkg "${release}"`
   pkd=`echo "${pkg}" | awk -F"\.tar" {'print $1'}`
   if [ ! -d "${pkd}" ]; then
      tar -jxvf ../${pkg} 2>&1 | oformat ">" "Extracting ${pkg} " "."
      cd "${pkd}"
      ctpatch "${pkd}"
      ctcpcf
      cd ..
   fi
   cd "${pkd}"
   config_args="--enable-local"
   if [ "${release}" == "14.09" ]; then
      config_args="--local"
   fi
   getarg config_args "Additional args for configure" "" "${config_args}"
   macports_home="/opt/local"
   getarg macports_home "MacPorts installation directory" "must" "${macports_home}"

   gp="${macports_home}/bin"
   cat <<_EOF_ >> envsetup.inc
   export sed="${gp}/gsed"
   export objcopy="${gp}/gobjcopy"
   export objdump="${gp}/gobjdump"
   export ranlib="${gp}/granlib"
   export readelf="${gp}/greadelf"
   export libtool="${gp}/glibtool"
   export libtoolize="${gp}/glibtoolize"
_EOF_
   echo
   source envsetup.inc
   ./configure \
      ${config_args} \
   | oformat ">" "Issuing configure .."
   if [ "`cat .p | grep "Bailing out"`" != "" ]; then
      echo
      exit
   fi
   echo
   td=`pwd | awk -F"${ctwpwd}" {'print $2'}`
   echo "
   cd .${td}
   make
   ./ct-ng menuconfig
   ulimit -n 2048
   ./ct-ng build
   " | oformat ">" "Please run below commands to build toolchain"
   cd ../..
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

function ctgetrel() {
   cat "${relfile}" | awk -F ";" {'print $1'} | oformat ">" "Supported Linaro releases;~" "-" " - "
   rel=`cat .p | tail -1`
   echo
   echo -n "   Please select release you want to download [${rel}] : "
   read cr
   if [ "${cr}" != "" ]; then
      rel="${cr}"
   fi
   getrel "${rel}"
}

function cthelp() {
   echo "
  1. Download crosstool-ng packages from Linaro releases storage server (http://releases.linaro.org)
	> ${0} get

  2. Create case sensitive file system in a disk image:
	> ${0} create
     or you may use existing one;
	> ${0} attach

  3. Run with \"prepare\" switch to extract crosstool-ng package and apply patches etc.
	> ${0} prepare

  4. Run with \"config\" switch to configure crosstool-ng and follow instructions displayed to build toolchain
	> ${0} configure

  5. Run with \"eject\" switch to unmount disk image.
	> ${0} eject

  Notes:
   - You may edit ctworks.config file to change your previously saved ctworks-configuration
     If you remove some lines from this file, it will be asked again.

   - You may need to restart from a step when something goes wrong;
     ./ct-ng list-steps
     RESTART=libc_start_files ./ct-ng build
"
}

if [ ! -e "${relfile}" ]; then
  cat <<_EOF_ > "${relfile}"
14.08;204e3e477db00c2c9c5d19e03548eb8a;http://releases.linaro.org/14.08/components/toolchain/binaries/crosstool-ng-linaro-1.13.1-4.9-2014.08.tar.bz2
14.09;8a01fde555f1127885b16b55793cfb65;http://releases.linaro.org/14.09/components/toolchain/binaries/crosstool-ng-linaro-1.13.1-4.9-2014.09.tar.bz2
_EOF_
fi

echo
if [ "${1}" == "create" ]; then
   dmgcreate
elif [ "${1}" == "attach" ]; then
   dmgattach
elif [ "${1}" == "eject" ]; then
   dmgeject
elif [ "${1}" == "get" ]; then
   ctgetrel
elif [ "${1}" == "prepare" ]; then
   ctprepare
elif [ "${1}" == "configure" ]; then
   ctconfig
elif [ "${1}" == "help" ]; then
   cthelp
else
   echo " ! Nothing to do, try get|prepare|configure|create|attach|eject|help"
fi
echo

