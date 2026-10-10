#
# Samsung Galaxy Tab Active2 (SM-T395, Exynos7870 LTE variant)
# Real codename confirmed via `adb shell getprop ro.product.device` on physical hardware: gtactive2lte
# (the task brief's "gtexltele" does not match any real device; see build notes)
#
PRODUCT_MAKEFILES := \
    $(LOCAL_DIR)/omni_gtactive2lte.mk

COMMON_LUNCH_MENU_CHOICES := \
    omni_gtactive2lte-userdebug
