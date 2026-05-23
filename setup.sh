#!/usr/bin/env bash
# Script to setup yocto image for Raspberry Pi Zero 2 W.
# Author: reboot-required.

set -euo pipefail

SCRIPTDIR="$(cd "$(dirname "$0")" && pwd)"
if [[ -z "$SCRIPTDIR" ]]; then
    echo "ERROR: could not determine script directory — run as ./setup.sh, not sourced" >&2
    exit 1
fi
LAYERSDIR="$SCRIPTDIR/layers"
BUILDDIR="$SCRIPTDIR/build"

POKY_REF="scarthgap-5.0.16"   # pinned release tag
LAYER_REF="scarthgap"          # branch (meta-raspberrypi / meta-oe have no release tags)

clone_or_skip() {
    local url="$1"
    local dest="$2"
    local ref="$3"
    if [ -d "$dest/.git" ]; then
        echo "  [skip] $dest already exists"
    else
        echo "  [clone] $url -> $dest (ref: $ref)"
        git clone --branch "$ref" --depth 1 "$url" "$dest"
    fi
}

echo "==> Ensuring layers/ directory exists"
mkdir -p "$LAYERSDIR"

echo "==> Cloning external layers"
clone_or_skip "https://git.yoctoproject.org/poky"                  "$LAYERSDIR/poky"              "$POKY_REF"
clone_or_skip "https://git.yoctoproject.org/meta-raspberrypi"       "$LAYERSDIR/meta-raspberrypi"  "$LAYER_REF"
clone_or_skip "https://github.com/openembedded/meta-openembedded"   "$LAYERSDIR/meta-openembedded" "$LAYER_REF"

echo "==> Writing conf/bblayers.conf"
mkdir -p "$BUILDDIR/conf"
cat > "$BUILDDIR/conf/bblayers.conf" <<BBLAYERS
# Managed by setup.sh — do not edit by hand.

POKY_BBLAYERS_CONF_VERSION = "2"

BBPATH = "\${TOPDIR}"
BBFILES ?= ""

BBLAYERS ?= " \\
    $SCRIPTDIR/layers/poky/meta \\
    $SCRIPTDIR/layers/poky/meta-poky \\
    $SCRIPTDIR/layers/meta-raspberrypi \\
    $SCRIPTDIR/layers/meta-openembedded/meta-oe \\
    $SCRIPTDIR/meta-cirthfb \\
    "
BBLAYERS

echo "==> Writing conf/local.conf"
cat > "$BUILDDIR/conf/local.conf" <<LOCALCONF
# Managed by setup.sh — do not edit by hand.

MACHINE = "raspberrypi0-2w-64"

DISTRO ?= "poky"
PACKAGE_CLASSES ?= "package_rpm"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"

# systemd
INIT_MANAGER = "systemd"

# Raspberry Pi extras
RPI_EXTRA_CONFIG = "dtparam=spi=on"

# Shared download/sstate caches — survives build/ wipes
DL_DIR ?= "\${HOME}/.yocto/downloads"
SSTATE_DIR ?= "\${HOME}/.yocto/sstate-cache"

BB_DISKMON_DIRS ??= "\\
    STOPTASKS,\${TMPDIR},1G,100K \\
    STOPTASKS,\${DL_DIR},1G,100K \\
    STOPTASKS,\${SSTATE_DIR},1G,100K \\
    STOPTASKS,/tmp,100M,100K \\
    ABORT,\${TMPDIR},100M,1K \\
    ABORT,\${DL_DIR},100M,1K \\
    ABORT,\${SSTATE_DIR},100M,1K \\
    ABORT,/tmp,10M,1K \\
    "

LICENSE_FLAGS_ACCEPTED = "synaptics-killswitch"
LOCALCONF

echo ""
echo "============================================================"
echo " Setup complete!"
echo "============================================================"
echo ""
echo " To start a build, run:"
echo ""
echo "   source layers/poky/oe-init-build-env build"
echo "   bitbake core-image-base"
echo ""
echo " Downloads : ~/.yocto/downloads"
echo " sstate    : ~/.yocto/sstate-cache"
echo "============================================================"
