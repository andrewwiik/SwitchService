THEOS_PACKAGE_DIR_NAME = debs
ARCHS = armv7 arm64
FINALPACKAGE = 1
SwitchService_LDFLAGS += -Wl,-segalign,4000

include theos/makefiles/common.mk

TWEAK_NAME = SwitchService
SwitchService_FILES = Tweak.xm
SwitchService_FRAMEWORKS = UIKit CoreMotion CoreGraphics AudioToolbox MobileCoreServices
SwitchService_PRIVATE_FRAMEWORKS = ChatKit IMCore AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk

after-install::
	install.exec "killall -9 MobileSMS"
SUBPROJECTS += Preferences
include $(THEOS_MAKE_PATH)/aggregate.mk
