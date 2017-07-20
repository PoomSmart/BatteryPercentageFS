PACKAGE_VERSION = 0.0.3
TARGET = iphone:clang:latest:5.0

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = BatteryPercentageFS
BatteryPercentageFS_FILES = Switch.xm
BatteryPercentageFS_LIBRARIES = flipswitch substrate
BatteryPercentageFS_INSTALL_PATH = /Library/Switches

include $(THEOS_MAKE_PATH)/bundle.mk
