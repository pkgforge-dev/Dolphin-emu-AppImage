#/bin/sh

set -ex

export APPIMAGE_EXTRACT_AND_RUN=1
export ARCH="$(uname -m)"
APPIMAGETOOL="https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
LIB4BN="https://raw.githubusercontent.com/VHSgunzo/sharun/refs/heads/main/lib4bin"
GRON="https://raw.githubusercontent.com/xonixx/gron.awk/refs/heads/main/gron.awk"
ICON="https://github.com/dolphin-emu/dolphin/blob/master/Data/dolphin-emu.png?raw=true"
URUNTIME="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-$ARCH"
URUNTIME_LITE="https://github.com/VHSgunzo/uruntime/releases/latest/download/uruntime-appimage-dwarfs-lite-$ARCH"
UPINFO="gh-releases-zsync|$(echo "$GITHUB_REPOSITORY" | tr '/' '|')|latest|*dwarfs-$ARCH.AppImage.zsync"
REPO="https://github.com/dolphin-emu/dolphin.git"

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
	VERSION=$(wget https://api.github.com/repos/dolphin-emu/dolphin/tags -O - \
		| ./gron.awk | grep -v "nJoy" |awk -F'=|"' '/name/ {print $3; exit}')
	git clone --branch "$VERSION" --single-branch "$REPO" ./dolphin
fi
echo "$VERSION" > ~/version

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

# Prepare AppDir
mkdir -p ./AppDir
cd ./AppDir

echo '[Desktop Entry]
Version=1.0
Icon=dolphin-emu
Exec=dolphin-emu
Terminal=false
Type=Application
Categories=Game;Emulator;
Name=Dolphin Emulator
GenericName=Wii/GameCube Emulator
StartupWMClass=dolphin-emu
Comment=A Wii/GameCube Emulator' > ./dolphin-emu.desktop

cp -v /usr/local/share/icons/hicolor/256x256/apps/dolphin-emu.png  ./
cp -v /usr/local/share/icons/hicolor/256x256/apps/dolphin-emu.png  ./.DirIcon

# Bundle all libs
wget --retry-connrefused --tries=30 "$LIB4BN" -O ./lib4bin
chmod +x ./lib4bin
xvfb-run -a -- ./lib4bin -p -v -e -s -k \
	/usr/local/bin/dolphin-* \
	/usr/lib/gconv/* \
	/usr/lib/libGLX* \
	/usr/lib/libEGL* \
	/usr/lib/dri/* \
	/usr/lib/libvulkan* \
	/usr/lib/qt6/plugins/iconengines/* \
	/usr/lib/qt6/plugins/imageformats/* \
	/usr/lib/qt6/plugins/platforms/* \
	/usr/lib/qt6/plugins/platformthemes/* \
	/usr/lib/qt6/plugins/styles/* \
	/usr/lib/qt6/plugins/xcbglintegrations/* \
	/usr/lib/qt6/plugins/wayland-*/* \
	/usr/lib/pipewire-0.3/* \
	/usr/lib/spa-0.2/*/* \
	/usr/lib/alsa-lib/*

# copy locales, the dolphin binary expects them here
mkdir -p ./Source/Core
cp -r /usr/local/bin/DolphinQt ./Source/Core
find ./Source/Core/DolphinQt -type f ! -name 'dolphin-emu.mo' -delete

# when compiled portable this directory needs a capital S
cp -rv /usr/local/bin/Sys ./bin/Sys

# Prepare sharun
ln ./sharun ./AppRun
./sharun -g

# MAKE APPIMAGE WITH URUNTIME
cd ..
wget --retry-connrefused --tries=30 "$URUNTIME" -O ./uruntime
wget --retry-connrefused --tries=30 "$URUNTIME_LITE" -O ./uruntime-lite
chmod +x ./uruntime*

#Add udpate info to runtime
echo "Adding update information \"$UPINFO\" to runtime..."
./uruntime-lite --appimage-addupdinfo "$UPINFO"

echo "Generating AppImage..."
./uruntime --appimage-mkdwarfs -f \
	--set-owner 0 --set-group 0 \
	--no-history --no-create-timestamp \
	--compression zstd:level=22 -S26 -B8 \
	--header uruntime-lite \
	-i ./AppDir -o Dolphin_Emulator-"$VERSION"-anylinux.dwarfs-"$ARCH".AppImage

echo "Generating zsync file..."
zsyncmake *.AppImage -u *.AppImage

# dolphin (the file manager) had to ruin the fun for everyone 😭
UPINFO="$(echo "$UPINFO" | sed 's|dwarfs|squashfs|')"

wget --retry-connrefused --tries=30 "$APPIMAGETOOL" -O ./appimagetool
chmod +x ./appimagetool
./appimagetool --comp zstd \
	--mksquashfs-opt -Xcompression-level --mksquashfs-opt 22 \
	-n -u "$UPINFO" "$PWD"/AppDir "$PWD"/Dolphin_Emulator-"$VERSION"-anylinux.squashfs-"$ARCH".AppImage

echo "All Done!"
