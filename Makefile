SHELL = bash

FOAM_VERSION = 2112
SOURCE_TARBALL_URL = https://sourceforge.net/projects/openfoam/files/v$(FOAM_VERSION)/OpenFOAM-v$(FOAM_VERSION).tgz
SOURCE_TARBALL_SHA256 = 3e838731e79db1c288acc27aad8cc8a43d9dac1f24e5773e3b9fa91419a8c3f7

TARGET = app

APP_NAME = OpenFOAM-v$(FOAM_VERSION)
DMG_FILESYSTEM = 'Case-sensitive APFS'
FINAL_DMG_FORMAT = UDRO

BUILD_DMG_SIZE = 5g

DIST_NAME = openfoam$(FOAM_VERSION)-app-$(shell uname -m)
INSTALL_DIR = ~/Applications/


SOURCE_TARBALL = $(shell basename $(SOURCE_TARBALL_URL))
BUILD_DMG_FILE = build/$(APP_NAME)-build.dmg
FINAL_DMG_FILE = build/$(APP_NAME).dmg
VOLUME = /Volumes/$(APP_NAME)
VOLUME_ID_FILE = $(VOLUME)/.vol_id
APP_BUNDLE = build/$(APP_NAME).app
APP_DMG_FILE = $(APP_BUNDLE)/Contents/Resources/$(APP_NAME).dmg
ZIPPED_APP_BUNDLE = build/$(DIST_NAME).zip
INSTALLED_APP_BUNDLE = $(INSTALL_DIR)/$(APP_NAME).app


default: $(TARGET)
app: $(APP_BUNDLE)
dmg: $(FINAL_DMG_FILE)
build: $(BUILD_DMG_FILE)
fetch-source: $(SOURCE_TARBALL)
install-dependencies: Brewfile.lock.json
zip: $(ZIPPED_APP_BUNDLE)
install: $(INSTALLED_APP_BUNDLE)


$(ZIPPED_APP_BUNDLE): $(APP_BUNDLE)
	cd $(<D) && zip -r $(CURDIR)/$(ZIPPED_APP_BUNDLE) $(<F)
	shasum -a 256 $(ZIPPED_APP_BUNDLE)

$(INSTALLED_APP_BUNDLE): $(APP_BUNDLE)
	cp -r $(APP_BUNDLE) $(INSTALLED_APP_BUNDLE)

$(APP_BUNDLE): $(FINAL_DMG_FILE) Info.plist launch openfoam icon.icns LICENSE
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp Info.plist $(APP_BUNDLE)/Contents/
	cp launch $(APP_BUNDLE)/Contents/MacOS/
	cp openfoam $(APP_BUNDLE)/Contents/MacOS/
	sed -i '' "s/{{FOAM_VERSION}}/$(FOAM_VERSION)/g" $(APP_BUNDLE)/Contents/MacOS/openfoam
	cp icon.icns $(APP_BUNDLE)/Contents/Resources/
	cp LICENSE $(APP_BUNDLE)/Contents/Resources/
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	cp $(FINAL_DMG_FILE) $(APP_DMG_FILE)
	hdiutil attach $(APP_DMG_FILE)
	cat $(VOLUME_ID_FILE)
	sed -i '' "s/{{VOLUME_ID}}/$$(cat $(VOLUME_ID_FILE))/g" $(APP_BUNDLE)/Contents/MacOS/openfoam
	hdiutil detach $(VOLUME)

TEMP_DMG_FILE = build/temp.dmg
$(FINAL_DMG_FILE): $(BUILD_DMG_FILE)
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	cp $(BUILD_DMG_FILE) $(TEMP_DMG_FILE)
	hdiutil attach $(TEMP_DMG_FILE)
	uuidgen > $(VOLUME_ID_FILE)
	cat $(VOLUME_ID_FILE)
	rm -rf $(VOLUME)/build
	rm -f $(VOLUME)/.DS_Store
	rm -rf $(VOLUME)/.fseventsd || true
	hdiutil detach $(VOLUME)
	hdiutil resize -sectors min $(TEMP_DMG_FILE)
	hdiutil convert $(TEMP_DMG_FILE) -format $(FINAL_DMG_FORMAT) -o $(FINAL_DMG_FILE)
	rm $(TEMP_DMG_FILE)

$(BUILD_DMG_FILE): $(SOURCE_TARBALL) Brewfile.lock.json icon.icns Brewfile configure.sh
	echo "$(SOURCE_TARBALL_SHA256)  $(SOURCE_TARBALL)" | shasum -a 256 -c -
	brew bundle check --verbose --no-upgrade
	cat Brewfile.lock.json
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	mkdir -p build
	hdiutil create -fs $(DMG_FILESYSTEM) -size $(BUILD_DMG_SIZE) -volname $(APP_NAME) $(BUILD_DMG_FILE)
	hdiutil attach $(BUILD_DMG_FILE)
	tar -xzf $(SOURCE_TARBALL) --strip-components 1 -C $(VOLUME)
	cp icon.icns $(VOLUME)/.VolumeIcon.icns
	SetFile -c icnC $(VOLUME)/.VolumeIcon.icns
	SetFile -a C $(VOLUME)
	cp Brewfile $(VOLUME)/
	cp Brewfile.lock.json $(VOLUME)/
	cd $(VOLUME) \
		&& $(SHELL) -ex $(CURDIR)/configure.sh \
		&& source etc/bashrc \
		&& foamSystemCheck \
		&& ( ./Allwmake -j $(WMAKE_NJOBS) -s -q -k; ./Allwmake -j $(WMAKE_NJOBS) -s )
	hdiutil detach $(VOLUME)

$(SOURCE_TARBALL):
	curl -L -o $(SOURCE_TARBALL) $(SOURCE_TARBALL_URL)

Brewfile.lock.json: Brewfile
	brew bundle -f


TEST_DIR = build/test
test: test-dmg test-shell

test-dmg:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach $(FINAL_DMG_FILE)
	rm -rf $(TEST_DIR)
	mkdir -p $(TEST_DIR)
	cd $(TEST_DIR) \
		&& source $(VOLUME)/etc/bashrc \
		&& foamInstallationTest \
		&& $(SHELL) -ex $(CURDIR)/test.sh
	hdiutil detach $(VOLUME)

test-shell:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -rf $(TEST_DIR)
	mkdir -p $(TEST_DIR)
	$(APP_BUNDLE)/Contents/MacOS/openfoam -c foamInstallationTest
	cd $(TEST_DIR) \
		&& $(CURDIR)/$(APP_BUNDLE)/Contents/MacOS/openfoam < $(CURDIR)/test.sh
	hdiutil detach $(VOLUME)


clean-build:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -f $(BUILD_DMG_FILE) $(FINAL_DMG_FILE) $(ZIPPED_APP_BUNDLE) $(TEMP_DMG_FILE)
	rm -rf $(APP_BUNDLE) $(TEST_DIR)
	rmdir build || true

clean: clean-build
	rm -f $(SOURCE_TARBALL) Brewfile.lock.json


uninstall:
	rm -rf $(INSTALLED_APP_BUNDLE)


.PHONY: default app dmg build fetch-source install-dependencies zip install test test-dmg test-shell clean-build clean uninstall
