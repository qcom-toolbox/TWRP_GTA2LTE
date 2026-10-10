#
# BoardConfig.mk for Samsung Galaxy Tab Active2 (SM-T395 / gtactive2lte)
#
# Values below marked "VERIFIED" were read directly off a physical, rooted
# SM-T395 (adb root shell) or extracted from its real recovery.img with AIK —
# not guessed from generic Exynos 7870 documentation. Values marked "DEFAULT"
# are TWRP build-system conventions that should still work but were not
# independently confirmed against this device.

DEVICE_PATH := device/samsung/gtactive2lte

# --- Architecture ---
TARGET_ARCH := arm64
TARGET_ARCH_VARIANT := armv8-a
TARGET_CPU_ABI := arm64-v8a
TARGET_CPU_ABI2 :=
TARGET_CPU_VARIANT := generic

TARGET_2ND_ARCH := arm
TARGET_2ND_ARCH_VARIANT := armv7-a-neon
TARGET_2ND_CPU_ABI := armeabi-v7a
TARGET_2ND_CPU_ABI2 := armeabi
TARGET_2ND_CPU_VARIANT := generic

# --- Platform (Exynos 7870) ---
TARGET_BOARD_PLATFORM := exynos7870
TARGET_SOC := exynos7870
TARGET_BOOTLOADER_BOARD_NAME := universal7870
TARGET_NO_BOOTLOADER := true

# --- Kernel / boot image geometry ---
# VERIFIED via AIK unpack of the real recovery.img (base/offsets/pagesize
# match the mkbootimg header exactly; do not change without re-verifying).
# These also happen to equal system/core/mkbootimg's own defaults, but they
# are passed explicitly via BOARD_MKBOOTIMG_ARGS rather than relying on that.
BOARD_KERNEL_BASE := 0x10000000
BOARD_KERNEL_PAGESIZE := 2048
# VERIFIED: board/cmdline/os_version/os_patch_level are compared byte-for-byte
# against the real stock recovery.img header - board_name and the encoded
# os_version were both found to differ from stock in an earlier failed boot
# test (empty vs "SRPQE17A011RU", and 16.1.0 - this build system's own
# internal OmniRom PLATFORM_VERSION, not the real Android 9 - vs the real
# encoded 9.0.0/2021-10 from the device). These are appended last on the
# mkbootimg command line in build/make/core/Makefile, so they override the
# defaults/PLATFORM_VERSION-derived values that come before them.
BOARD_MKBOOTIMG_ARGS := --kernel_offset 0x00008000 --ramdisk_offset 0x01000000 --tags_offset 0x00000100 --board SRPQE17A011RU --cmdline "" --os_version 9.0.0 --os_patch_level 2021-10-01
BOARD_KERNEL_IMAGE_NAME := Image
BOARD_USES_SEANDROIDENFORCE := true

# VERIFIED against the real build/make/core/Makefile + vendor/omni/build/tasks
# in this synced twrp-9.0 tree (not assumed): the stock boot image carries a
# separate ~500KB legacy "dt" segment holding the Exynos7870 device tree
# blob. BOARD_KERNEL_SEPARATED_DT enables --dt packing; BOARD_KERNEL_PREBUILT_DT
# is required to skip vendor/omni/build/tasks/dt_image.mk's dtbToolCM step,
# which would otherwise try to build dt.img from a compiled kernel source
# tree that does not exist for this device. With BOARD_KERNEL_PREBUILT_DT set,
# INSTALLED_DTIMAGE_TARGET ($(PRODUCT_OUT)/dt.img) is instead populated by the
# PRODUCT_COPY_FILES rule in device.mk that copies prebuilt/dt.img there.
BOARD_KERNEL_SEPARATED_DT := true
BOARD_KERNEL_PREBUILT_DT := true

TARGET_KERNEL_ARCH := arm64
TARGET_KERNEL_HEADER_ARCH := arm64
# No downstream buildable kernel source was located for this device — see
# device.mk / TARGET_PREBUILT_KERNEL below. vendor/omni/build/tasks/kernel.mk
# explicitly supports this (falls back to TARGET_PREBUILT_KERNEL when
# $(KERNEL_SRC) doesn't exist), confirmed by reading that file directly.
TARGET_PREBUILT_KERNEL := $(DEVICE_PATH)/prebuilt/kernel
BOARD_KERNEL_CMDLINE :=

# --- Recovery ---
RECOVERY_VARIANT := twrp
TARGET_RECOVERY_FSTAB := $(DEVICE_PATH)/recovery.fstab
BOARD_HAS_NO_REAL_SDCARD := false
TW_INTERNAL_STORAGE_PATH := "/data/media"
TW_INTERNAL_STORAGE_MOUNT_POINT := "data"
TW_EXTERNAL_STORAGE_PATH := "/external_sd"
TW_EXTERNAL_STORAGE_MOUNT_POINT := "external_sd"

TARGET_USERIMAGES_USE_EXT4 := true
# F2FS support dropped (real device fstab is ext4-only, and sload.f2fs +
# mkfs.f2fs cost ~1.6MB of ramdisk space we don't have to spare - see the
# ramdisk-size note below).
BOARD_SYSTEMIMAGE_PARTITION_TYPE := ext4
BOARD_USERDATAIMAGE_PARTITION_TYPE := ext4
BOARD_CACHEIMAGE_PARTITION_TYPE := ext4
BOARD_FLASH_BLOCK_SIZE := 131072
BOARD_BOOTIMAGE_PARTITION_SIZE := 33554432   # VERIFIED: mmcblk0p10, 32768 blocks
BOARD_RECOVERYIMAGE_PARTITION_SIZE := 39845888  # VERIFIED: mmcblk0p11, 38912 blocks
BOARD_SYSTEMIMAGE_PARTITION_SIZE := 3221225472  # VERIFIED: mmcblk0p18, 3145728 blocks
BOARD_USERDATAIMAGE_PARTITION_SIZE := 11936989184  # VERIFIED: mmcblk0p24, 11657216 blocks
BOARD_CACHEIMAGE_PARTITION_SIZE := 209715200  # VERIFIED: mmcblk0p19, 204800 blocks

# --- Graphics ---
# VERIFIED from the kernel log of a real failed boot (/proc/last_kmsg): do NOT
# force RGB_565. This device's decon framebuffer driver rejects 16bpp
# ("decon:16 bpp doesn't support"), TWRP then aborts (SIGABRT), init restarts
# it every ~5s - each restart blanks/unblanks the panel, which is the
# backlight on/off boot loop - until the kernel panics. The earlier 16bpp
# reading came from a chroot test under running Android, where SurfaceFlinger
# owns the display, so fb0's sysfs values didn't reflect what recovery sees.
# Leave the driver's native 32bpp format.

# VERIFIED: the panel is mounted upside down (ro.sf.hwrotation=180 on stock).
# Android rotates only the image, not touch, so the digitizer is already
# upright - rotating the framebuffer is all TWRP needs for both to line up.
TW_ROTATION := 180

# DEFAULT: standard Mali-T830 (Exynos7870 GPU) framebuffer path used by other
# Exynos7870 Samsung devices; not independently probed on this unit.
TARGET_USES_HWC2 := true
TW_NO_SCREEN_BLANK := true
TW_NO_SCREEN_TIMEOUT := true
TW_THEME := portrait_hdpi
BOARD_USES_DRM_HWCOMPOSER := false

# --- Touch input ---
# VERIFIED via `dmesg` on the real device: STMicro fts_touch driver
# (irq 113, digitizer range 1599x2559, project "gtactive2/T395").
TW_INPUT_BLACKLIST := "hall_sensor_input"
TW_EXCLUDE_TWRPAPP := true

# --- microSD ---
# VERIFIED via /fstab.samsungexynos7870 on the real device: external SD is on
# the dwmmc2 controller (SDHCI2), voldmanaged, vfat. See recovery.fstab.
TW_FLASH_FROM_STORAGE := true

# --- Ramdisk fixups ---
# VERIFIED on the device: moves adbd off the /sbin/adbd path (Samsung RKP
# demotes its children to uid 2000), relaxes adb props and patches the
# SELinux policy for this always-enforcing kernel. See tools/prepare-ramdisk.sh.
# Recursive (=) so the out-dir variables expand when the recipe runs.
BOARD_RECOVERY_IMAGE_PREPARE = device/samsung/gtactive2lte/tools/prepare-ramdisk.sh \
    $(TARGET_RECOVERY_ROOT_OUT) $(HOST_OUT_EXECUTABLES)/sepolicy-allow

# --- misc TWRP flags ---
# No custom sepolicy or extra required recovery modules exist for this
# device, so BOARD_SEPOLICY_DIRS / TARGET_RECOVERY_DEVICE_MODULES are
# intentionally omitted rather than pointed at directories/modules that
# don't exist (the latter is actually a required-module-name list consumed
# by bootable/recovery/Android.mk, not a path — confirmed by reading it).

# --- Ramdisk size ---
# The first real flash attempt failed to boot with "Invalid Ramdisk Length"
# from Samsung's sboot, which enforces its own hard ramdisk-size ceiling
# independent of the RECOVERY partition size (undocumented, not derivable
# from any source in this tree - a genuinely real Samsung Exynos bootloader
# constraint, confirmed by comparing against the stock recovery ramdisk,
# which is 7.8MB and boots fine, vs our first attempt at 14.7MB, which
# doesn't). Trimming aggressively below to find a size that actually boots;
# TW_INCLUDE_CRYPTO is bundled with TW_INCLUDE_FBE/FBE_METADATA_DECRYPT as
# one all-or-nothing block on SDK 28 (confirmed in bootable/recovery/
# Android.mk - there is no way to keep general crypto while dropping FBE
# specifically), and the real device's stock fstab has no fileencryption=
# flag on /data, so FBE is confirmed unused here - dropping the whole
# crypto block is a reasonable trade for now. This drops encrypted /data
# decrypt support, SSH/SFTP (bundled with nano's flag, oddly), the nano
# editor, bash (toybox's sh remains), MTP, and timezone data. Re-add
# selectively once a working baseline confirms the real size ceiling.
TW_EXCLUDE_NANO := true
TW_EXCLUDE_BASH := true
TW_EXCLUDE_MTP := true
TW_EXCLUDE_TZDATA := true
TW_EXCLUDE_PYTHON := true
TW_EXCLUDE_ENCRYPTED_BACKUPS := true
