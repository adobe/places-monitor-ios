# sourcedrop vars
ROOT_DIR = $(shell git rev-parse --show-toplevel)

LIB_VERSION = $(shell grep 'EXTENSION_VERSION =' ../../code/src/ACPPlacesMonitor.m | sed 's/.*EXTENSION_VERSION.*=.*\@\"\(.*\)\".*/\1/')

ZIP_DIR = AdobeMobileLibrary-apple-$(SDK_VERSION)-src
COMBINED_SRC_ZIP_DIR = $(ROOT_DIR)/bin/$(ZIP_DIR)

# xcode compatability
XCODEBUILD_VERSION = $(shell xcodebuild -version | grep Xcode | sed 's/Xcode[[:space:]]*\([0-9]*\)\..*/\1/')
XCODEBUILD_COMPATIBLE = $(shell [ $(XCODEBUILD_VERSION) -gt 7 ] && echo true)

export EXTENSION_NAME = ACPPlacesMonitor
SUBMAKE_FILE_PATH=../../tools/makefiles/

# targets
check-xcode-version:
# check xcodebuild version (requires version 7 or greater)
ifeq ($(XCODEBUILD_COMPATIBLE),true)
	@echo "Running make with xcodebuild version:" $(XCODEBUILD_VERSION)
else
	$(error Failed to run make, incompatible xcodebuild version (requires v7+))
endif

all: check-xcode-version clean art
	make all-no-clean -f $(SUBMAKE_FILE_PATH)makefile.ios
	#make all-no-clean -f makefile.ios-extension
	#make all-no-clean -f makefile.tvos
	#make all-no-clean -f $(SUBMAKE_FILE_PATH)makefile.watchos

build-shallow: art
	make build-shallow -f $(SUBMAKE_FILE_PATH)makefile.ios
	#make build-shallow -f makefile.ios-extension
	#make build-shallow -f makefile.tvos
	#make build-shallow -f $(SUBMAKE_FILE_PATH)makefile.watchos

disable-code-coverage:
	make disable-code-coverage -f $(SUBMAKE_FILE_PATH)makefile.ios

unit-test:
	make unit-test -f $(SUBMAKE_FILE_PATH)makefile.ios

functional-test:
	#make functional-test -f $(SUBMAKE_FILE_PATH)makefile.ios

coverage:
	make coverage -f $(SUBMAKE_FILE_PATH)makefile.ios

release:
	make all -f $(SUBMAKE_FILE_PATH)makefile.ios

clean:
	make clean -f $(SUBMAKE_FILE_PATH)makefile.ios
	make clean -f $(SUBMAKE_FILE_PATH)makefile.ios-extension
	make clean -f $(SUBMAKE_FILE_PATH)makefile.tvos
	make clean -f $(SUBMAKE_FILE_PATH)makefile.watchos

internalPod:
	@echo ${LIB_VERSION}
	make release
	sh ../../tools/cocoapod-uploader/spec_new_pod.sh ${LIB_VERSION} ACPPlacesMonitor places-monitor


sourcedrop: clean art
	@echo "######################################################################"
	@echo "### source drop"
	@echo "######################################################################"

	make sourcedrop -f $(SUBMAKE_FILE_PATH)makefile.ios
	make sourcedrop -f $(SUBMAKE_FILE_PATH)makefile.ios-extension
	make sourcedrop -f $(SUBMAKE_FILE_PATH)makefile.tvos
	make sourcedrop -f $(SUBMAKE_FILE_PATH)makefile.watchos

	mkdir $(COMBINED_SRC_ZIP_DIR)
	cp $(ROOT_DIR)/bin/AdobeMobileLibrary-$(SDK_VERSION)-iOS-src.zip $(COMBINED_SRC_ZIP_DIR)
	cp $(ROOT_DIR)/bin/AdobeMobileLibrary-$(SDK_VERSION)-iOS-extension-src.zip $(COMBINED_SRC_ZIP_DIR)
	cp $(ROOT_DIR)/bin/AdobeMobileLibrary-$(SDK_VERSION)-tvOS-src.zip $(COMBINED_SRC_ZIP_DIR)
	cp $(ROOT_DIR)/bin/AdobeMobileLibrary-$(SDK_VERSION)-watchOS-src.zip $(COMBINED_SRC_ZIP_DIR)

	@echo "### Must Supply ZIP Password for Source Drop"
	cd $(ROOT_DIR)/bin && zip -erXq $(ZIP_DIR).zip $(ZIP_DIR)/

	-rm -rf $(COMBINED_SRC_ZIP_DIR)

art:
	@echo "                                                                      "
	@echo "////==============================================================////"
	@echo "//------------------------------------------------------------------//"
	@echo "|                                                                    |"
	@echo "|              %%%%%%%%%     ##%%%%%%       ##      %%               |"
	@echo "|             ##             ##     %%      ##    %%                 |"
	@echo "|             ##             ##      %%     ##  %%                   |"
	@echo "|              %%%%%%%%      ##      %%     ##%%                     |"
	@echo "|                     ##     ##      %%     ##  %%                   |"
	@echo "|                     ##     ##     %%      ##    %%                 |"
	@echo "|             %%%%%%%%%      ##%%%%%%       ##      %%  (v5)         |"
	@echo "|                                                                    |"
	@echo "//------------------------------------------------------------------//"
	@echo "////==============================================================////"
	@echo "                                                                      "
	@echo "      .--..--..--..--..--..--.        __________________________      "
	@echo "    .' \  (\`._   (_)     _   \       |                          |    "
	@echo "  .'    |  '._)         (_)  |       |  BUILD IT.  BUILD IT!!!  |     "
	@echo "  \ _.')\      .----..---.   /       |   _______________________|     "
	@echo "  |(_.'  |    /    .-\-.  \  |       / /                              "
	@echo "  \     0|    |   ( O| O) | o|      / /                               "
	@echo "   |  _  |  .--.____.'._.-.  |     /_/                                "
	@echo "   \ (_) | o         -\` .-\`  |                                      "
	@echo "    |    \   |\`-._ _ _ _ _\ /                                        "
	@echo "    \    |   |  \`. |_||_|   |                                        "
	@echo "    | o  |    \_      \     |     -.   .-.                            "
	@echo "    |.-.  \     \`--..-'   O |     \`.\`-' .'                         "
	@echo "  _.'  .' |     \`-.-'      /-.__   ' .-'                             "
	@echo ".' \`-.\` '.|='=.='=.='=.='=|._/_ \`-'.'                              "
	@echo "\`-._  \`.  |________/\_____|    \`-.'                                "
	@echo "   .'   ).| '=' '='\/ '=' |                                           "
	@echo "   \`._.\`  '---------------'                                         "
	@echo "           //___\   //___\\                                           "
	@echo "             ||       ||                                              "
	@echo "             ||_.-.   ||_.-.                                          "
	@echo "            (_.--__) (_.--__)                                         "
	@echo "                                                                      "
	@echo "______________________________________________________________________"
