#!/bin/bash
#
# Run by the build (BOARD_RECOVERY_IMAGE_PREPARE) on the assembled recovery
# ramdisk tree, just before it is packed.
#
#   prepare-ramdisk.sh <recovery root dir> <path to sepolicy-allow>
#
set -e
root=$1
sepolicy_allow=$2

# Samsung RKP marks any process exec'd as "/sbin/adbd", and every root
# process that process starts is demoted to uid 2000 (shell) on exec. In
# recovery that leaves adb shell unable to run anything in /sbin. RKP only
# compares the exec path, so run adbd from another name. adbd also runs in
# the recovery domain rather than su, which is enforced on this kernel.
mv -f "$root/sbin/adbd" "$root/sbin/twrpadbd"
sed -i 's#^service adbd /sbin/adbd --root_seclabel=u:r:su:s0 #service adbd /sbin/twrpadbd --root_seclabel=u:r:recovery:s0 #' \
    "$root/init.rc"
grep -q '^service adbd /sbin/twrpadbd --root_seclabel=u:r:recovery:s0 ' "$root/init.rc" || {
    echo "prepare-ramdisk.sh: adbd service line in init.rc not found" >&2
    exit 1
}

# ro.* properties keep the first value set, so edit in place instead of
# appending. ro.adb.secure=0: TWRP has no UI to authorize an adb key.
sed -i -e 's/^ro\.secure=1$/ro.secure=0/' -e 's/^ro\.adb\.secure=1$/ro.adb.secure=0/' \
    "$root/prop.default"
for prop in ro.adb.secure=0 sys.usb.ffs.aio_compat=1; do
    grep -q "^${prop%%=*}=" "$root/prop.default" || echo "$prop" >> "$root/prop.default"
done

# The kernel has config_always_enforce: "permissive recovery;" is ignored,
# so give recovery and adbd explicit access to everything instead.
"$sepolicy_allow" "$root/sepolicy" "$root/sepolicy.tmp" recovery adbd
mv -f "$root/sepolicy.tmp" "$root/sepolicy"
