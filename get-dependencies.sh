#!/bin/sh

set -ex
EXTRA_PACKAGES="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/get-debloated-pkgs.sh"

echo "Installing build dependencies..."
echo "---------------------------------------------------------------"
pacman -Syu --noconfirm \
	base-devel       \
	bluez-libs       \
	bzip2            \
	cmake            \
	curl             \
	enet             \
	git              \
	hidapi           \
	libusb           \
	libx11           \
	libxi            \
	libxrandr        \
	lz4              \
	lzo              \
	mesa             \
	pipewire-audio   \
	pulseaudio       \
	pulseaudio-alsa  \
	qt6ct            \
	sdl2             \
	speexdsp         \
	strace           \
	vulkan-headers   \
	wget             \
	xcb-util-cursor  \
	xorg-server-xvfb \
	xxhash           \
	xz               \
	zstd             \
	zsync

echo "Installing debloated packages..."
echo "---------------------------------------------------------------"
wget --retry-connrefused --tries=30 "$EXTRA_PACKAGES" -O ./get-debloated-pkgs.sh
chmod +x ./get-debloated-pkgs.sh
./get-debloated-pkgs.sh --add-common

echo "Building dolphin..."
echo "---------------------------------------------------------------"
REPO="https://github.com/dolphin-emu/dolphin.git"
GRON="https://raw.githubusercontent.com/xonixx/gron.awk/refs/heads/main/gron.awk"

# Determine to build nightly or stable
if [ "$DEVEL" = 'true' ]; then
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

# BUILD DOLPHIN
cd ./dolphin 
mkdir ./build 
cd ./build
git submodule update --init --recursive
cmake .. -DLINUX_LOCAL_DEV=true -DCMAKE_POLICY_VERSION_MINIMUM=3.5
make -j $(nproc)
sudo make install
