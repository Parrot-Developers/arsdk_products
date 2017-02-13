
ARSDK_WINDOWS_CONFIG_DIR := $(call my-dir)

# Include common product.mk
include $(ARSDK_WINDOWS_CONFIG_DIR)/../../common/config/product.mk

# Use our own json, ncurses version
prebuilt.json.override := 1
prebuilt.ncurses.override := 1

# Setup TARGET_OS
TARGET_OS := windows
TARGET_OS_FLAVOUR := msys
TARGET_ARCH := x64

# TODO: MinGW does not create static libs compatible with MSVC:
# some library functions have been inlined leading to linker errors
TARGET_FORCE_STATIC := 0
TARGET_GLOBAL_CFLAGS += -mno-ms-bitfields
