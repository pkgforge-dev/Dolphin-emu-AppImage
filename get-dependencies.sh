#!/bin/sh

set -eu

echo "Installing package dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel       \
	bluez-libs       \
	bzip2            \
	cmake            \
	enet             \
	hidapi           \
	kvantum          \
	libusb           \
	lz4              \
	lzo              \
	mesa             \
	pipewire-audio   \
	pipewire-jack    \
	qt6ct            \
	qt6-wayland      \
	sdl2             \
	speexdsp         \
	vulkan-headers   \
	xcb-util-cursor  \
	xxhash           \
	xz

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
get-debloated-pkgs --add-common ! gtk3

# Comment this out if you need an AUR package
#make-aur-package PACKAGENAME

echo "Building dolphin..."
echo "---------------------------------------------------------------"
REPO="https://github.com/dolphin-emu/dolphin.git"
GRON="https://raw.githubusercontent.com/xonixx/gron.awk/refs/heads/main/gron.awk"

# Determine to build nightly or stable
if [ "${DEVEL-}" = 'true' ]; then
	echo "Making nightly build of dolphin-emu..."
	VERSION="$(git ls-remote "$REPO" HEAD | cut -c 1-9 | head -1)"
	UPINFO="$(echo "$UPINFO" | sed 's|latest|nightly|')"
	git clone "$REPO" ./dolphin
else
	echo "Making stable build of dolphin-emu..."
	wget "$GRON" -O ./gron.awk
	chmod +x ./gron.awk
	VERSION=$(wget https://api.github.com/repos/dolphin-emu/dolphin/tags -O - | \
		./gron.awk | grep -v "nJoy" | awk -F'=|"' '/name/ {print $3}' | \
		sort -V -r | head -1)
	git clone --branch "$VERSION" --single-branch "$REPO" ./dolphin
fi
echo "$VERSION" > ~/version

# BUILD DOLPHIN
cd ./dolphin 

# HACK
qpaheader=$(find /usr/include -type f -name 'qplatformnativeinterface.h' -print -quit)
sed -i "s|#include <qpa/qplatformnativeinterface.h>|#include <$qpaheader>|" ./Source/Core/DolphinQt/MainWindow.cpp

mkdir ./build 
cd ./build
git submodule update --init --recursive
cmake .. \
	-DDISTRIBUTOR=pkgforge-dev   \
	-DCMAKE_INSTALL_PREFIX=/usr  \
    -DENABLE_ANALYTICS=OFF       \
	-DENABLE_LLVM=OFF            \
	-DUSE_DISCORD_PRESENCE=OFF   \
    -DENABLE_AUTOUPDATE=OFF      \
	-DENCODE_FRAMEDUMPS=OFF      \
	-DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j $(nproc)
sudo make install
