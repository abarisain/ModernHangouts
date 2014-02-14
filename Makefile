include theos/makefiles/common.mk

ARCHS=armv7 armv7s arm64
TARGET_IPHONEOS_DEPLOYMENT_VERSION = 7.0
TARGET_CC = xcrun -sdk iphoneos clang 
TARGET_CXX = xcrun -sdk iphoneos clang++
TARGET_LD = xcrun -sdk iphoneos clang++
SHARED_CFLAGS = -fobjc-arc

TWEAK_NAME = ModernHangouts
ModernHangouts_FILES = Tweak.xm
ModernHangouts_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 SpringBoard"
