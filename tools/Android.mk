LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)
LOCAL_MODULE := sepolicy-allow
LOCAL_SRC_FILES := sepolicy-allow.c
LOCAL_STATIC_LIBRARIES := libsepol
LOCAL_CFLAGS := -Wall -Werror
LOCAL_MODULE_HOST_OS := linux
include $(BUILD_HOST_EXECUTABLE)

# prepare-ramdisk.sh (BOARD_RECOVERY_IMAGE_PREPARE) runs this tool while the
# recovery ramdisk is being assembled.
$(PRODUCT_OUT)/ramdisk-recovery.cpio: $(LOCAL_INSTALLED_MODULE)
