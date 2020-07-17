#!/bin/bash

# command info
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "-help" ]; then
 echo "small config script to install NodeJs"
 echo "bonus.nodejs.sh [on|off]"
 exit 1
fi

source /mnt/hdd/raspiblitz.conf

# add default value to raspi config if needed
if ! grep -Eq "^nodeJS=" /mnt/hdd/raspiblitz.conf; then
  echo "nodeJS=off" >> /mnt/hdd/raspiblitz.conf
fi

# switch on
if [ "$1" = "1" ] || [ "$1" = "on" ]; then
  # check if nodeJS was installed
  nodeJSInstalled=$(node -v 2>/dev/null | grep -c "v1.")
  if ! [ ${nodeJSInstalled} -eq 0 ]; then
    echo "nodeJS is already installed"
  else
    # determine nodeJS VERSION and DISTRO
    echo "Detect CPU architecture ..."
    isARM=$(uname -m | grep -c 'arm')
    isAARCH64=$(uname -m | grep -c 'aarch64')
    isX86_64=$(uname -m | grep -c 'x86_64')
    VERSION="v12.16.3"
  
    # get checksums from -> https://nodejs.org/dist/vx.y.z/SHASUMS256.txt
    # https://nodejs.org/dist/v12.16.3/SHASUMS256.txt
  
    if [ ${isARM} -eq 1 ] ; then
      DISTRO="linux-armv7l"
      CHECKSUM="8fdf1751c985c4e8048b23bbe9e36aa0cad0011c755427694ea0fda9efad6d97"
    elif [ ${isAARCH64} -eq 1 ] ; then
      DISTRO="linux-arm64"
      CHECKSUM="8311f513a7d1911200502dd3e00142cef56d600c851d5870f68d939802205b73"
    elif [ ${isX86_64} -eq 1 ] ; then
      DISTRO="linux-x64"
      CHECKSUM="1956e196e3c3c8ef5f0c45db76d7c1245af4ccdda2b7ab30a57ce91d6e165caa"
    elif [ ${#DISTRO} -eq 0 ]; then
      echo "FAIL: Was not able to determine architecture"
      exit 1
    fi
    echo "VERSION: ${VERSION}"
    echo "DISTRO: ${DISTRO}"
    echo "CHECKSUM: ${CHECKSUM}"
    echo ""
  
    # install latest nodejs
    # https://github.com/nodejs/help/wiki/Installation
    echo "*** Install NodeJS $VERSION-$DISTRO ***"
  
    # download
    cd /home/admin/download
    wget https://nodejs.org/dist/$VERSION/node-$VERSION-$DISTRO.tar.xz
    # checksum
    isChecksumValid=$(sha256sum node-$VERSION-$DISTRO.tar.xz | grep -c "${CHECKSUM}")
    if [ ${isChecksumValid} -eq 0 ]; then
      echo "FAIL: The checksum of node-$VERSION-$DISTRO.tar.xz is NOT ${CHECKSUM}"
      rm -f node-$VERSION-$DISTRO.tar.xz*
      exit 1
    fi
    echo "OK CHECKSUM of nodeJS is OK"
    sleep 3
    # install
    sudo mkdir -p /usr/local/lib/nodejs
    sudo tar -xJvf node-$VERSION-$DISTRO.tar.xz -C /usr/local/lib/nodejs
    rm -f node-$VERSION-$DISTRO.tar.xz* 
    export PATH=/usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin:$PATH
    sudo ln -sf /usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin/node /usr/bin/node
    sudo ln -sf /usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin/npm /usr/bin/npm
    sudo ln -sf /usr/local/lib/nodejs/node-$VERSION-$DISTRO/bin/npx /usr/bin/npx
    # add to PATH permanently
    sudo bash -c "echo 'PATH=\$PATH:/usr/local/lib/nodejs/node-\$VERSION-\$DISTRO/bin/' >> /etc/profile"
    echo ""
  
    # check if nodeJS was installed
    nodeJSInstalled=$(node -v | grep -c "v1.")
    if [ ${nodeJSInstalled} -eq 0 ]; then
      echo "FAIL - Was not able to install nodeJS"
      echo "ABORT - nodeJs install"
      exit 1
    fi
  fi
  # setting value in raspi blitz config
  sudo sed -i "s/^nodeJS=.*/nodeJS=on/g" /mnt/hdd/raspiblitz.conf
  echo "Installed nodeJS $(node -v)"
  exit 0
fi

# switch off
if [ "$1" = "0" ] || [ "$1" = "off" ]; then
  # setting value in raspiblitz config
  sudo sed -i "s/^nodeJS=.*/nodeJS=off/g" /mnt/hdd/raspiblitz.conf
  echo "*** REMOVING NODEJS ***"
  sudo rm -rf /usr/local/lib/nodejs
  echo "OK NodeJS removed."
  exit 0
fi

echo "FAIL - Unknown Parameter $1"
exit 1
