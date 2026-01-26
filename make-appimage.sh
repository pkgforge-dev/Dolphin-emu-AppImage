#/bin/sh

set -eu

ARCH=$(uname -m)
export ARCH
export OUTPATH=./dist
export ADD_HOOKS="self-updater.bg.hook"
export UPINFO="gh-releases-zsync|${GITHUB_REPOSITORY%/*}|${GITHUB_REPOSITORY#*/}|latest|*$ARCH.AppImage.zsync"
export DEPLOY_LOCALE=1
export DEPLOY_OPENGL=1 
export DEPLOY_VULKAN=1 
export DEPLOY_PIPEWIRE=1
export ANYLINUX_LIB=1

# Deploy dependencies
quick-sharun /usr/bin/dolphin-*

# Additional changes can be done in between here

# Turn AppDir into AppImage
quick-sharun --make-appimage
