# architectures
# source: https://en.wikipedia.org/wiki/List_of_iOS_devices#RAM,_Processor,_and_Highest_supported_iOS_release

# device architectures
ARCH_ARM64 = arm64
ARCH_ARMV7S = armv7s
# armv7 == 32-bit processor - used in iPhone 5 and iPhone 5c, which can run up to iOS 10.3.3...so we have to leave it in for now
ARCH_ARMV7 = armv7

# simulator architectures
ARCH_X86_64 = x86_64
# i386 == 32-bit simulator - cocoapods complains when this is missing so leaving it in
ARCH_I386 = i386

# platforms
SDK_IOS = iphoneos
SDK_IOS_SIMULATOR = iphonesimulator

# configurations
BUILD_IOS_TARGET_VERSION = IPHONEOS_DEPLOYMENT_TARGET=10.0
BUILDFLAGS_BITCODE = BITCODE_GENERATION_MODE=bitcode OTHER_CFLAGS='-fembed-bitcode -Wno-error=unused-command-line-argument'
BUILDFLAGS = GCC_TREAT_WARNINGS_AS_ERRORS=YES GCC_GENERATE_DEBUGGING_SYMBOLS=NO STRIP_INSTALLED_PRODUCT=YES STRIP_STYLE=ALL GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS NDEBUG=1 NS_BLOCK_ASSERTIONS=1 COMPILEFORAPP'
CORE_LIB_NAME = lib$(EXTENSION_NAME)_iOS.a
DERIVED_DATA = -derivedDataPath
DESTINATION = -destination
ENABLE_COVERAGE = -enableCodeCoverage YES
EXTENSION_NAME = ACPPlacesMonitor
RELEASE = -configuration Release
SDK_VERSION = $(shell grep 'NSString\* const ACPPlacesMonitorExtensionVersion' $(ROOT_DIR)/ACPPlacesMonitor/ACPPlacesMonitorConstants.m | sed 's/.*NSString\* const ACPPlacesMonitorExtensionVersion.*=.*\@\"\(.*\)\".*/\1/')
TEST_DERIVED_DATA = $(DERIVED_DATA) '$(TEST_DERIVED_DATA_PATH)'
TEST_DESTINATION = $(DESTINATION) 'platform=iOS Simulator,name=iPhone 8'
XCODEBUILD = xcodebuild
XCODEBUILD_COMPATIBLE = $(shell [ $(XCODEBUILD_VERSION) -gt 7 ] && echo true)
XCODEBUILD_VERSION = $(shell xcodebuild -version | grep Xcode | sed 's/Xcode[[:space:]]*\([0-9]*\)\..*/\1/')

# directories
BIN_DIR = $(ROOT_DIR)/bin/iOS/
BUILD_DIR = Build/
BUILD_TEMP_DIR = $(BIN_DIR)build_temp/
DEV_BUILD_DIR = devbuild
DOC_DIR = $(ROOT_DIR)/doc
INCLUDE_DIR = $(ROOT_DIR)/code/src/include
LIBRARY_NAME = $(LIB_BASE_NAME)/
PRODUCTS_DIR = Products/
RELEASE_DIR_IPHONE = $(BUILD_DIR)$(PRODUCTS_DIR)Release-$(SDK_IOS)/
RELEASE_DIR_SIMULATOR = $(BUILD_DIR)$(PRODUCTS_DIR)Release-$(SDK_IOS_SIMULATOR)/
ROOT_DIR = .

# environments
WORKSPACE_NAME = $(EXTENSION_NAME).xcworkspace
PROJECT_FILE = $(EXTENSION_NAME).xcodeproj
BUILD_SCHEME = $(EXTENSION_NAME)_iOS
TEST_DERIVED_DATA_PATH = $(EXTENSION_NAME)/out
TEST = test

# files
DOCUMENTATION = documentation.html
LIB_BASE_NAME = lib$(EXTENSION_NAME)_iOS
LICENSE_FILE = LICENSE.md
LIPO_LIB_PHONE = $(BUILD_DIR)$(LIB_BASE_NAME)
RELEASE_NOTES = ReleaseNotes.txt
UNIT_TEST_REPORT = $(TEST_DERIVED_DATA_PATH)/build/reports/iosUnitTestReport
UNIT_TEST_REPORT_HTML = $(UNIT_TEST_REPORT).html
UNIT_TEST_REPORT_XML = $(UNIT_TEST_REPORT).xml
FUNCTIONAL_TEST_REPORT = $(TEST_DERIVED_DATA_PATH)/build/reports/FunctionalTests/iosFunctionalTestReport
FUNCTIONAL_TEST_REPORT_HTML = $(FUNCTIONAL_TEST_REPORT).html
FUNCTIONAL_TEST_REPORT_XML = $(FUNCTIONAL_TEST_REPORT).xml

# targets
check-xcode-version:
	# check xcodebuild version (requires version 7 or greater)
	@echo "build version: " $(XCODEBUILD_VERSION)
ifeq ($(XCODEBUILD_COMPATIBLE),true)
	@echo "Running make with xcodebuild version:" $(XCODEBUILD_VERSION)
else
	$(error Failed to run make, incompatible xcodebuild version (requires v7+))
endif

all: check-xcode-version clean arm64 armv7s armv7 x86_64 i386 lipo copy-files

all-no-clean: arm64 armv7s armv7 i386 x86_64 lipo copy-files

setup: update-pods

update: update-pods

build: clean build-shallow

test: unit-test

update-pods:
	(pod repo update && pod update)

build-shallow: check-xcode-version x86_64

armv7:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS) \
		-arch $(ARCH_ARMV7) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS_BITCODE) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARMV7).a

armv7s:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS) \
		-arch $(ARCH_ARMV7S) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS_BITCODE) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARMV7S).a

arm64:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS) \
		-arch $(ARCH_ARM64) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS_BITCODE) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARM64).a

i386:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
	  -workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS_SIMULATOR) \
		-arch $(ARCH_I386) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME)-$(ARCH_I386).a

x86_64:
	@echo "######################################################################"
	@echo "### Building: "$@
	@echo "######################################################################"
	$(XCODEBUILD) $(RELEASE) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		-sdk $(SDK_IOS_SIMULATOR) \
		-arch $(ARCH_X86_64) \
		-derivedDataPath $(BUILD_TEMP_DIR) \
		$(BUILD_IOS_TARGET_VERSION) $(BUILDFLAGS)
	mv $(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME)-$(ARCH_X86_64).a

lipo:
	@echo "######################################################################"
	@echo "### Running: "$@
	@echo "######################################################################"
	xcrun lipo -create \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARMV7S).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARMV7).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_IPHONE)$(LIB_BASE_NAME)-$(ARCH_ARM64).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME)-$(ARCH_X86_64).a \
		$(BUILD_TEMP_DIR)$(RELEASE_DIR_SIMULATOR)$(LIB_BASE_NAME)-$(ARCH_I386).a \
		-output $(BIN_DIR)$(LIB_BASE_NAME).a
	@echo "============================================================"
	@echo "Universal binary created:"
	@echo $(LIB_BASE_NAME).a
	lipo -info $(BIN_DIR)$(LIB_BASE_NAME).a
	@echo "============================================================"

unit-test:
	@echo "######################################################################"
	@echo "### Unit Testing iOS"
	@echo "######################################################################"
	$(XCODEBUILD) $(TEST) \
		-workspace $(WORKSPACE_NAME) \
		-scheme $(BUILD_SCHEME) \
		$(TEST_DESTINATION) \
		$(TEST_DERIVED_DATA) \
		$(ENABLE_COVERAGE)

coverage:
	@echo "######################################################################"
	@echo "### Unit Test Coverage iOS"
	@echo "######################################################################"
	rm -rf $(TEST_DERIVED_DATA_PATH)/coverage
	mkdir $(TEST_DERIVED_DATA_PATH)/coverage

	# capture coverage from object files
	lcov --capture --directory \
		$(TEST_DERIVED_DATA_PATH)/Build/Intermediates.noindex/$(EXTENSION_NAME).build/Test-iphonesimulator/$(EXTENSION_NAME)_iOS.build/ \
		--output-file $(TEST_DERIVED_DATA_PATH)/coverage/test.info

	# remove non-source results
	lcov --remove $(TEST_DERIVED_DATA_PATH)/coverage/test.info '*/code/unitTests/*' '*/tools/*' '*/v1/*' '*/usr/include/*' \
		'/Applications/Xcode.app/*' '*/bourbon-core-cpp/*' '*/bourbon-ios-unit-tests/util/*' \
		-o $(TEST_DERIVED_DATA_PATH)/coverage/all.info

	# generate html report from results
	genhtml $(TEST_DERIVED_DATA_PATH)/coverage/all.info \
		--output-directory $(TEST_DERIVED_DATA_PATH)/reports/coverage

clean:
	@echo "######################################################################"
	@echo "### Cleaning..."
	@echo "######################################################################"
	-rm -rf $(BUILD_TEMP_DIR)
	-rm -rf $(BIN_DIR)$(LIBRARY_NAME)


# xcframework helpers
FW_LIB = lib$(EXTENSION_NAME)_iOS.a
PATH_TO_LIB = Products/usr/local/lib/$(FW_LIB)
PATH_TO_BIN = bin/iOS
FRAMEWORK_NAME = $(PATH_TO_BIN)/$(EXTENSION_NAME).xcframework
PATH_TO_HEADERS = ACPPlacesMonitor/include
XCFRAMEWORKS_BUILDFLAGS = SKIP_INSTALL=NO GCC_TREAT_WARNINGS_AS_ERRORS=YES GCC_GENERATE_DEBUGGING_SYMBOLS=NO GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS NDEBUG=1 NS_BLOCK_ASSERTIONS=1 COMPILEFORAPP'
XCFRAMEWORKS_BUILDFLAGS_SIM = SKIP_INSTALL=NO GCC_TREAT_WARNINGS_AS_ERRORS=YES GCC_GENERATE_DEBUGGING_SYMBOLS=NO GCC_PREPROCESSOR_DEFINITIONS='$GCC_PREPROCESSOR_DEFINITIONS NDEBUG=1 NS_BLOCK_ASSERTIONS=1'

# ios device
FAT_IOS = ./build/ios/$(FW_LIB)
PATH_IOS_ARM64 = ./build/ios-arm64.xcarchive
PATH_IOS_ARMV7 = ./build/ios-armv7.xcarchive
PATH_IOS_ARMV7S = ./build/ios-armv7s.xcarchive

# ios simulator
FAT_IOS_SIM = ./build/ios-simulator/$(FW_LIB)
PATH_IOS_SIM_ARM64 = ./build/ios-simulator-arm64.xcarchive
PATH_IOS_SIM_X86_64 = ./build/ios-simulator-x86_64.xcarchive
PATH_IOS_SIM_I386 = ./build/ios-simulator-i386.xcarchive

archives: archive-ios combine

archive-ios: archive-ios-device archive-ios-simulator
archive-ios-device:
	xcodebuild archive -workspace $(WORKSPACE_NAME) -scheme $(BUILD_SCHEME) -arch $(ARCH_ARM64) -archivePath $(PATH_IOS_ARM64) -sdk iphoneos $(XCFRAMEWORKS_BUILDFLAGS)
	xcodebuild archive -workspace $(WORKSPACE_NAME) -scheme $(BUILD_SCHEME) -arch $(ARCH_ARMV7) -archivePath $(PATH_IOS_ARMV7) -sdk iphoneos $(XCFRAMEWORKS_BUILDFLAGS)
	xcodebuild archive -workspace $(WORKSPACE_NAME) -scheme $(BUILD_SCHEME) -arch $(ARCH_ARMV7S) -archivePath $(PATH_IOS_ARMV7S) -sdk iphoneos $(XCFRAMEWORKS_BUILDFLAGS)

archive-ios-simulator:
	xcodebuild archive -workspace $(WORKSPACE_NAME) -scheme $(BUILD_SCHEME) -arch $(ARCH_ARM64) -archivePath $(PATH_IOS_SIM_ARM64) -sdk iphonesimulator $(XCFRAMEWORKS_BUILDFLAGS_SIM)
	xcodebuild archive -workspace $(WORKSPACE_NAME) -scheme $(BUILD_SCHEME) -arch $(ARCH_X86_64) -archivePath $(PATH_IOS_SIM_X86_64) -sdk iphonesimulator $(XCFRAMEWORKS_BUILDFLAGS_SIM)
	xcodebuild archive -workspace $(WORKSPACE_NAME) -scheme $(BUILD_SCHEME) -arch $(ARCH_I386) -archivePath $(PATH_IOS_SIM_I386) -sdk iphonesimulator $(XCFRAMEWORKS_BUILDFLAGS_SIM)

combine: clean-archive-dirs
	# combine ios device & sim libs
	xcrun lipo -create $(PATH_IOS_ARM64)/$(PATH_TO_LIB) $(PATH_IOS_ARMV7)/$(PATH_TO_LIB) $(PATH_IOS_ARMV7S)/$(PATH_TO_LIB) -output $(FAT_IOS)
	xcrun lipo -create $(PATH_IOS_SIM_ARM64)/$(PATH_TO_LIB) $(PATH_IOS_SIM_X86_64)/$(PATH_TO_LIB) $(PATH_IOS_SIM_I386)/$(PATH_TO_LIB) -output $(FAT_IOS_SIM)

clean-archive-dirs:
	rm -rf "./build/ios" && mkdir "./build/ios"
	rm -rf "./build/ios-simulator" && mkdir "./build/ios-simulator"

xcframeworks: archives
	mkdir -p $(PATH_TO_BIN)
	rm -rf $(FRAMEWORK_NAME)
	@echo "######################################################################"
	@echo "############### Creating combined XCFramework for iOS ################"
	@echo "###############  $(FRAMEWORK_NAME) ################"
	@echo "######################################################################"
	xcodebuild -create-xcframework -library $(FAT_IOS) -headers $(PATH_TO_HEADERS) -library $(FAT_IOS_SIM) -headers $(PATH_TO_HEADERS) -output $(FRAMEWORK_NAME)
