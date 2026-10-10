# TWRP device tree — Samsung Galaxy Tab Active2 (SM-T395, `gtactive2lte`)

TWRP 9.0 device tree for the Samsung Galaxy Tab Active2 LTE (Exynos 7870 variant,
model **SM-T395**). **Boots on real hardware** with a working display and
touch, after one manual post-build step (see [Status](#status)). adb is not
fully working yet.

## Device

| | |
|---|---|
| Model | SM-T395 (Galaxy Tab Active2, LTE, Exynos variant) |
| Codename | `gtactive2lte` (confirmed via `ro.product.device` on real hardware — not `gtexltele`, which shows up in some unrelated build tooling and does not correspond to this device) |
| SoC | Samsung Exynos 7870 Octa |
| Architecture | ARM64 (arm64-v8a primary, armeabi-v7a secondary) |
| Stock Android | 9.0 (Pie), kernel 3.18.91, security patch 2021-10 |
| Bootloader version (as tested) | `T395XXSDCUI7` |
| Partitions | Non-A/B, standard Samsung eMMC layout with a dedicated `RECOVERY` partition |

## Status

**TWRP boots, displays correctly and responds to touch.** Every finding
below comes from the kernel log of real failed boots (`/proc/last_kmsg`,
which on this device also keeps the bootloader's own log), Samsung's separate
SELinux denial buffer (`/proc/avc_msg`, saved by stock recovery to
`/data/log/avc_msg_recovery.log`), and the host's `journalctl -k`.

The old explanation in this README (TIMA/RKP blocking unsigned `RECOVERY`)
was wrong. The kernel boots fine with a TWRP ramdisk and TWRP's `init`
starts; what was failing was TWRP itself, for these reasons:

1. **Forced RGB565 crashed TWRP.** The `decon` framebuffer driver rejects
   16bpp (`decon:16 bpp doesn't support`). TWRP aborted, `init` restarted it
   every ~5 s (each restart blanks/unblanks the panel: the "black flash with
   backlight on, then off" loop) until the kernel panicked. Fixed by removing
   `TARGET_RECOVERY_FORCE_PIXEL_FORMAT`. The earlier 16bpp reading came from a
   chroot under running Android, where SurfaceFlinger owns the display.
2. **Samsung's kernel ignores SELinux permissive domains.** The stock kernel
   has `config_always_enforce`: `setenforce 0` fails and the `permissive
   recovery;` rule TWRP relies on is ignored, so TWRP runs fully confined.
   It then dies on `execmem` (pixelflinger code generation) among other
   denials. **Not yet fixed in the build** — see the manual step below.
3. **The panel is mounted upside down** (`ro.sf.hwrotation=180` on stock).
   Android rotates only the image, so the digitizer is already upright.
   Fixed with `TW_ROTATION := 180`, which fixes touch too (touches were
   reaching the driver, but landing on the mirrored spot).
4. **adbd's v2 USB descriptors are rejected** by this 3.18 kernel's
   functionfs, and the v1 retry then fails too, so the host sees `no
   configurations` / `can't read configurations, error -22`.
   `patches/system_core.patch` makes adbd write v1 descriptors directly; the
   device then enumerates and `adb devices` shows it in `recovery`.

`prebuilt/kernel` also carries the 3-byte Samsung DEFEX patch Magisk applies
(see `device.mk`). It did not fix the boot loop on its own, but it matches
the kernel that boots with Magisk on this device.

### Manual post-build step: SELinux policy

Until this is automated in the build, patch the built policy with
`magiskpolicy` (from a Magisk-rooted device, or any `magiskpolicy` build),
then repack `recovery.img` with the replaced `/sepolicy`:

```
magiskpolicy --load sepolicy --save sepolicy.patched \
    "allow recovery * * *" "permissive recovery" \
    "allow adbd * * *" "permissive adbd" \
    "allow * adbd * *" "allow * recovery * *"
```

The tested image also had `adbd`'s `--root_seclabel=u:r:su:s0` changed to
`u:r:recovery:s0` in `init.rc`, because the `su` domain is enforced too.

### Still open

- **`adb shell`** connects as root (`adbd` runs as uid 0 in `u:r:recovery:s0`
  with `LD_LIBRARY_PATH=/sbin`), but the shell fails with
  `CANNOT LINK EXECUTABLE "/sbin/sh": library "libc++.so" not found`, even
  with `/vendor/lib64` and `/system/lib64` symlinked to `/sbin`. Cause not yet
  found. `adb pull`/`adb push`/`adb reboot` work.
- **`/data` doesn't mount** (`Can't probe device /dev/block/mmcblk0p24`),
  most likely because `/data` is encrypted and `TW_INCLUDE_CRYPTO` was
  dropped to save ramdisk space.
- Flashing through Heimdall usually boots Android afterwards rather than
  recovery; use `adb reboot recovery` from there.

### How to get logs from a failed boot

Boot the failing recovery, force download mode (Power + Vol Down), flash
stock `RECOVERY`, boot Android with root, then read `/proc/last_kmsg`
(its 2 MB buffer spans several boots; find the one whose
`pack_atags: ramdisk size` matches your ramdisk) and `/proc/avc_msg`.

## What's actually verified in this tree

Everything in this device tree was derived from the real, physical SM-T395
(rooted, `adb root` shell), not guessed from generic Exynos 7870
documentation:

- **Partition map** (`recovery.fstab`) — read directly from
  `/dev/block/platform/13540000.dwmmc0/by-name/` and `/proc/partitions` on
  the device. This device has no `VENDOR`/`ODM` partitions and no `/misc`
  partition (Samsung uses its own reboot-reason mechanism instead of the
  standard AOSP BCB convention here).
- **Kernel + device-tree blob** (`prebuilt/kernel`, `prebuilt/dt.img`) —
  extracted byte-for-byte from the real `RECOVERY` partition via
  [AIK](https://github.com/SebaUbuntu/AIK-Linux-mirror). There is no public,
  buildable downstream kernel source for this device, so the real kernel
  binary is packaged as-is (a standard, supported TWRP mechanism — see
  `vendor/omni/build/tasks/kernel.mk`'s `TARGET_PREBUILT_KERNEL` fallback).
  The DTB uses Samsung's proprietary `DTBH` multi-image container format.
- **Boot image header fields** (`BOARD_MKBOOTIMG_ARGS` in `BoardConfig.mk`) —
  `base`/offsets/`os_version`/`board`/`cmdline` all verified to match the
  stock image's header exactly, byte-for-byte, via direct comparison.
- **Framebuffer pixel format** — native 32bpp. Do not force RGB565: the
  `decon` driver rejects 16bpp in recovery (see [Status](#status)).
  `patches/bootable_recovery.patch` adds an `mmap()` single-frame fallback in
  `minuitwrp/graphics_fbdev.cpp`; it is harmless but was written for the
  RGB565 theory and may not be needed.
- **Display rotation** — the panel is mounted upside down
  (`ro.sf.hwrotation=180` on stock), so `TW_ROTATION := 180`.
- **Touch panel** — STMicro `fts_touch` driver (`sec_input` wrapper),
  confirmed via `dmesg`, project string `gtactive2/T395`.

## Building

```
repo init -u https://github.com/minimal-manifest-twrp/platform_manifest_twrp_omni.git -b twrp-9.0
repo sync -j$(nproc)
```

Clone this tree into `device/samsung/gtactive2lte`, then apply everything in
[`patches/`](patches/) (see below — required, the build will not succeed
without them on a modern host).

```
source build/envsetup.sh
lunch omni_gtactive2lte-userdebug
mka recoveryimage
```

### Modern-host build environment notes

This is an old (Android 9-era) build system being built on a current Ubuntu
host, which needs a few environment workarounds unrelated to this device
specifically:

- **Locale**: `soong_ui` hard-requires `C.UTF-8` or `en_US.UTF-8` to be
  present in `locale -a`. If neither is installed, generate one without root:
  ```
  localedef --no-archive -i en_US -f UTF-8 ~/.locales/en_US.UTF-8
  export LOCPATH=~/.locales
  ```
- **`ALLOW_MISSING_DEPENDENCIES=true`** — required. The `twrp-9.0` minimal
  manifest intentionally excludes large chunks of full-AOSP source
  (`external/skia`, `okhttp`, codec libraries, etc.) that recovery doesn't
  need, but their `Android.bp` references remain scattered through
  `frameworks/`, `tools/`, and `external/`, which Soong's global module graph
  still parses. This flag tells Soong to tolerate the resulting undefined
  references instead of hard-failing.
- **`patches/`** — a batch of Python 2→3 fixes (this manifest's build tooling
  predates Python 3 support) and one real `sort`/`comm` locale-collation bug
  (GNU coreutils requires `LC_ALL=C` for byte-order collation in
  `build/make/core/definitions.mk`'s stripped-binary symbol diffing, or `sort`
  and `comm` can disagree on ordering under a non-C locale and the build
  fails non-deterministically).
- Bash, not zsh — `build/envsetup.sh` relies on `BASH_SOURCE` and other
  bashisms.

### `SEANDROIDENFORCE` trailer

Not handled by any build-system variable in this tree (`BOARD_USES_SEANDROIDENFORCE`
is inert here despite existing as a device-tree convention elsewhere) — append it
manually after building if you want the trailer stock images on this device carry:

```
printf 'SEANDROIDENFORCE' >> out/target/product/gtactive2lte/recovery.img
```

## `patches/`

Changes required outside this device tree, against the synced `twrp-9.0`
source, to get a working build:

| Patch | What / why |
|---|---|
| `build_make.patch` | Python 2→3 fixes in `build/make/tools/*.py` (print statements, `ConfigParser`→`configparser`, a `%u` format string bug, an `int`/`str` comparison that was silently always-`False` under genuine Python 2 and needed to stay disabled rather than "fixed" — see comments in the diff); `LC_ALL=C` fix for `sort`/`comm` in `core/definitions.mk`. |
| `bootable_recovery.patch` | An fbdev `mmap()` single-frame fallback (see above), in `minuitwrp/graphics_fbdev.cpp` (the file this device's `libminuitwrp.so` is actually built from — not `bootable/recovery/minui/`, a separate, unused generic copy that's easy to mistake for the real one in this tree). |
| `frameworks_base.patch` | Drops `hwui`'s dependency on `skia_deps`, a module `remove-minimal.xml` deliberately strips from this manifest. `hwui` is never part of the `recoveryimage` build graph; this only unblocks Soong's global parse. |
| `external_clang.patch`, `art.patch` | Python 2→3 and `python_binary_host` version-flag fixes for two more build-time tool scripts. |
| `system_sepolicy.patch` | Python 2→3 fixes for the sepolicy build tool. |
| `system_core.patch` | Makes `adbd` write v1 functionfs descriptors directly. This kernel rejects the v2 block and then fails the v1 retry too, so without this the host sees `no configurations`. |

## License

This device tree is licensed under the [Apache License 2.0](LICENSE), matching
AOSP/TWRP/OmniRom convention. `prebuilt/kernel` and `prebuilt/dt.img` are
binary firmware components extracted directly from this device's own stock
partitions for personal build/porting purposes and are not covered by that
license — see [`NOTICE`](NOTICE).
