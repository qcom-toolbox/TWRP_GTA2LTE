#
# device.mk - board/recovery packaging rules for gtactive2lte
#
LOCAL_PATH := device/samsung/gtactive2lte

DEVICE_PATH := device/samsung/gtactive2lte

# Kernel and device-tree blob are prebuilt binaries pulled directly from the
# real recovery partition of a physical SM-T395 (rooted, verified via adb) —
# no buildable downstream kernel source for this device was found publicly,
# so both are packaged as-is rather than compiled from source.
# prebuilt/kernel carries one 3-byte patch at offset 0x1238fc: Samsung DEFEX's
# execve hook "mov w2, #-221" (821B8012) -> "mov w2, #-32768" (E2FF8F12), the
# same patch magiskboot applies. It is byte-identical to the kernel in the
# Magisk-patched BOOT that boots on this device. Unpatched, DEFEX's
# recovery-mode safeplace policy kills TWRP's root child processes.
# TARGET_PREBUILT_KERNEL lives in BoardConfig.mk (that's the phase
# vendor/omni/build/tasks/kernel.mk actually reads it from).
# dt.img has no source to build from either (BOARD_KERNEL_PREBUILT_DT in
# BoardConfig.mk skips the dtbToolCM build step) so it's copied straight to
# the product-out root, which is where INSTALLED_DTIMAGE_TARGET expects it.
PRODUCT_COPY_FILES += \
    $(LOCAL_PATH)/recovery.fstab:recovery/root/etc/recovery.fstab \
    $(LOCAL_PATH)/prebuilt/dt.img:dt.img

PRODUCT_PACKAGES += \
    fstab.samsungexynos7870
