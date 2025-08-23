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
	patchelf         \
	pipewire-audio   \
	pulseaudio       \
	pulseaudio-alsa  \
	qt6ct            \
	sdl2             \
	speexdsp         \
	strace           \
	vulkan-headers   \
	vulkan-nouveau   \
	vulkan-radeon    \
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
