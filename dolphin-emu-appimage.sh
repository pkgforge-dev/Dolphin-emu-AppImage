#/bin/sh

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

# Deploy AppImage
VERSION="$(cat ~/version)"
APPIMAGETOOL="https://github.com/pkgforge-dev/appimagetool-uruntime/releases/download/continuous/appimagetool-$ARCH.AppImage"
URUNTIME="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/uruntime2appimage.sh"
SHARUN="https://raw.githubusercontent.com/pkgforge-dev/Anylinux-AppImages/refs/heads/main/useful-tools/quick-sharun.sh"

export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*dwarfs-$ARCH.AppImage.zsync"
export OUTNAME=Dolphin_Emulator-"$VERSION"-anylinux.dwarfs-"$ARCH".AppImage
export DEPLOY_OPENGL=1 
export DEPLOY_VULKAN=1 
export DEPLOY_PIPEWIRE=1

# Bundle all libs
wget --retry-connrefused --tries=30 "$SHARUN" -O ./quick-sharun
chmod +x ./quick-sharun
./quick-sharun /usr/bin/dolphin-*

# Force C locale due to issues with gconv causing crashes
# See https://github.com/pkgforge-dev/Dolphin-emu-AppImage/issues/28
# This is a hack but since dolphin provides internal translations, it isn't a big deal
echo 'LC_ALL=C' >> ./AppDir/.env

# differentiate between nightly builds
if [ "$DEVEL" = 'true' ]; then
	sed -i 's|Name=Dolphin Emulator|Name=Dolphin Emulator Nightly|' ./AppDir/*.desktop
	UPINFO="$(echo "$UPINFO" | sed 's|latest|nightly|')"
fi

# allow the host vulkan to be used for aarch64 given the sad situation
if [ "$ARCH" = 'aarch64' ]; then
	echo 'SHARUN_ALLOW_SYS_VKICD=1' >> ./AppDir/.env
fi

# MAKE APPIMAGE WITH URUNTIME
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime2appimage
chmod +x ./uruntime2appimage
./uruntime2appimage

# dolphin (the file manager) had to ruin the fun for everyone 😭
UPINFO="$(echo "$UPINFO" | sed 's|dwarfs|squashfs|')"
wget --retry-connrefused --tries=30 "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool -n -u "$UPINFO" "$PWD"/AppDir "$PWD"/Dolphin_Emulator-"$VERSION"-anylinux.squashfs-"$ARCH".AppImage

echo "All Done!"
