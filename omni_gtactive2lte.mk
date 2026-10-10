#
# omni_gtactive2lte.mk - product definition for Samsung Galaxy Tab Active2 (SM-T395)
#

$(call inherit-product, $(SRC_TARGET_DIR)/product/languages_full.mk)
$(call inherit-product, build/target/product/embedded.mk)

# Inherit generic tablet characteristics
$(call inherit-product, $(SRC_TARGET_DIR)/product/full_base_telephony.mk)

# Inherit the device-specific proprietary/board config
$(call inherit-product, device/samsung/gtactive2lte/device.mk)

PRODUCT_DEVICE := gtactive2lte
PRODUCT_NAME := omni_gtactive2lte
PRODUCT_BRAND := samsung
PRODUCT_MODEL := SM-T395
PRODUCT_MANUFACTURER := samsung

PRODUCT_GMS_CLIENTID_BASE := android-samsung

PRODUCT_BUILD_PROP_OVERRIDES += \
    TARGET_DEVICE=gtactive2lte \
    PRODUCT_NAME=gtactive2ltexx
