#/bin/sh

set -ex

REPO="https://github.com/dolphin-emu/dolphin.git"
GRON="https://raw.githubusercontent.com/xonixx/gron.awk/refs/heads/main/gron.awk"
export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"

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
(
	cd ./dolphin 
	mkdir ./build 
	cd ./build

	git submodule update --init --recursive
	cmake .. -DLINUX_LOCAL_DEV=true -DCMAKE_POLICY_VERSION_MINIMUM=3.5
	make -j $(nproc)
	sudo make install

	sudo cp -r ../Data/Sys /usr/local/bin
	sudo cp -r ./Source/Core/DolphinQt /usr/local/bin
  )

# Deploy AppImage
[ -n "$VERSION" ] && echo "$VERSION" > ~/version
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
./quick-sharun /usr/local/bin/dolphin-*

# copy locales, the dolphin binary expects them here
mkdir -p ./AppDir/Source/Core
cp -r /usr/local/bin/DolphinQt ./AppDir/Source/Core
find ./AppDir/Source/Core/DolphinQt -type f ! -name 'dolphin-emu.mo' -delete

# when compiled portable this directory needs a capital S
cp -rv /usr/local/bin/Sys ./AppDir/bin/Sys

# Force C locale due to issues with gconv causing crashes
# See https://github.com/pkgforge-dev/Dolphin-emu-AppImage/issues/28
# This is a hack but since dolphin provides internal translations, it isn't a big deal
echo 'LC_ALL=C' >> ./AppDir/.env

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
