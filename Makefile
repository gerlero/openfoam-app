# Build configuration
SHELL = bash
FOAM_VERSION = 2112
APP_NAME = OpenFOAM-v$(FOAM_VERSION)
APP_HOMEPAGE = https://github.com/gerlero/openfoam$(FOAM_VERSION)-app
APP_VERSION = ''
SOURCE_TARBALL_URL = https://sourceforge.net/projects/openfoam/files/v$(FOAM_VERSION)/OpenFOAM-v$(FOAM_VERSION).tgz
SOURCE_TARBALL = $(shell basename $(SOURCE_TARBALL_URL))
DMG_FILESYSTEM = 'Case-sensitive APFS'
BUILD_DMG_SIZE = 5g
WMAKE_NJOBS = ''
FINAL_DMG_FORMAT = UDRO
DIST_NAME = openfoam$(FOAM_VERSION)-app-$(shell uname -m)
INSTALL_DIR = /Applications


# Build targets
app: build/$(APP_NAME).app
dmg: build/$(APP_NAME).dmg
build: build/$(APP_NAME)-build.dmg
fetch-source: $(SOURCE_TARBALL)
install-dependencies: Brewfile.lock.json
zip: build/$(DIST_NAME).zip
install: $(INSTALL_DIR)/$(APP_NAME).app


# Build rules
VOLUME = /Volumes/$(APP_NAME)
VOLUME_ID_FILE = $(VOLUME)/.vol_id

APP_CONTENTS = build/$(APP_NAME).app/Contents/Info.plist \
	           build/$(APP_NAME).app/Contents/MacOS/launch \
	           build/$(APP_NAME).app/Contents/MacOS/openfoam \
	           build/$(APP_NAME).app/Contents/Resources/LICENSE \
	           build/$(APP_NAME).app/Contents/Resources/icon.icns \
	           build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg


$(INSTALL_DIR)/$(APP_NAME).app: build/$(APP_NAME).app
	cp -r build/$(APP_NAME).app $(INSTALL_DIR)/

build/$(DIST_NAME).zip: build/$(APP_NAME).app
	cd build && zip -r $(DIST_NAME).zip $(APP_NAME).app
	shasum -a 256 build/$(DIST_NAME).zip

build/$(APP_NAME).app: $(APP_CONTENTS)

build/$(APP_NAME).app/Contents/Info.plist: Contents/Info.plist | build/$(APP_NAME).app/Contents/MacOS/launch build/$(APP_NAME).app/Contents/Resources/icon.icns
	mkdir -p build/$(APP_NAME).app/Contents
	cp Contents/Info.plist build/$(APP_NAME).app/Contents/
	sed -i '' "s|{{APP_VERSION}}|$(APP_VERSION)|g" build/$(APP_NAME).app/Contents/Info.plist

build/$(APP_NAME).app/Contents/MacOS/openfoam: build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg Contents/MacOS/openfoam
	mkdir -p build/$(APP_NAME).app/Contents/MacOS/
	cp Contents/MacOS/openfoam build/$(APP_NAME).app/Contents/MacOS/
	sed -i '' "s|{{APP_HOMEPAGE}}|$(APP_HOMEPAGE)|g" build/$(APP_NAME).app/Contents/MacOS/openfoam
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	cat $(VOLUME_ID_FILE)
	sed -i '' "s|{{VOLUME_ID}}|$$(cat $(VOLUME_ID_FILE))|g" build/$(APP_NAME).app/Contents/MacOS/openfoam
	hdiutil detach $(VOLUME)

build/$(APP_NAME).app/Contents/MacOS/launch: Contents/MacOS/launch | build/$(APP_NAME).app/Contents/MacOS/openfoam
	mkdir -p build/$(APP_NAME).app/Contents/MacOS
	cp Contents/MacOS/launch build/$(APP_NAME).app/Contents/MacOS/

build/$(APP_NAME).app/Contents/Resources/LICENSE: LICENSE
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp LICENSE build/$(APP_NAME).app/Contents/Resources/

build/$(APP_NAME).app/Contents/Resources/icon.icns: icon.icns
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp icon.icns build/$(APP_NAME).app/Contents/Resources/

build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg: build/$(APP_NAME).dmg
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp build/$(APP_NAME).dmg build/$(APP_NAME).app/Contents/Resources/

build/$(APP_NAME).dmg: build/$(APP_NAME)-shrunk.dmg
	hdiutil convert build/$(APP_NAME)-shrunk.dmg -format $(FINAL_DMG_FORMAT) -o build/$(APP_NAME).dmg -ov

build/$(APP_NAME)-shrunk.dmg: build/$(APP_NAME)-build.dmg
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	cp build/$(APP_NAME)-build.dmg build/$(APP_NAME)-shrunk.dmg
	hdiutil attach build/$(APP_NAME)-shrunk.dmg
	uuidgen > $(VOLUME_ID_FILE)
	cat $(VOLUME_ID_FILE)
	rm -rf $(VOLUME)/build
	rm -f $(VOLUME)/.DS_Store
	rm -rf $(VOLUME)/.fseventsd || true
	hdiutil detach $(VOLUME)
	hdiutil resize -sectors min build/$(APP_NAME)-shrunk.dmg

build/$(APP_NAME)-build.dmg: $(SOURCE_TARBALL) Brewfile.lock.json configure.sh Brewfile icon.icns
	brew bundle check --verbose --no-upgrade
	cat Brewfile.lock.json
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	mkdir -p build
	hdiutil create \
		-fs $(DMG_FILESYSTEM) \
		-size $(BUILD_DMG_SIZE) \
	    -volname $(APP_NAME) \
		build/$(APP_NAME)-build.dmg \
		-ov -attach
	tar -xzf $(SOURCE_TARBALL) --strip-components 1 -C $(VOLUME)
	cp icon.icns $(VOLUME)/.VolumeIcon.icns
	SetFile -c icnC $(VOLUME)/.VolumeIcon.icns
	SetFile -a C $(VOLUME)
	cp Brewfile $(VOLUME)/
	cp Brewfile.lock.json $(VOLUME)/
	cd $(VOLUME) \
		&& $(SHELL) -ex "$(CURDIR)/configure.sh" \
		&& source etc/bashrc \
		&& foamSystemCheck \
		&& ( ./Allwmake -j $(WMAKE_NJOBS) -s -q -k; ./Allwmake -j $(WMAKE_NJOBS) -s )
	hdiutil detach $(VOLUME)

$(SOURCE_TARBALL): sha256sums.txt
	curl -L -o $(SOURCE_TARBALL) $(SOURCE_TARBALL_URL)
	shasum -a 256 -c sha256sums.txt

Brewfile.lock.json: Brewfile
	brew bundle -f


# Non-build targets and rules
test: test-dmg test-shell

test-dmg:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg \
	 || hdiutil attach build/$(APP_NAME).dmg \
	 || hdiutil attach build/$(APP_NAME)-build.dmg 
	rm -rf build/test/test-dmg
	mkdir -p build/test/test-dmg
	cd build/test/test-dmg \
		&& source $(VOLUME)/etc/bashrc \
		&& foamInstallationTest \
		&& $(SHELL) -ex "$(CURDIR)/test.sh"
	hdiutil detach $(VOLUME)

test-shell:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -rf build/test/test-shell
	mkdir -p build/test/test-shell
	build/$(APP_NAME).app/Contents/MacOS/openfoam -c foamInstallationTest
	cd build/test/test-shell \
		&& "$(CURDIR)/build/$(APP_NAME).app/Contents/MacOS/openfoam" < "$(CURDIR)/test.sh"
	hdiutil detach $(VOLUME)

clean-build:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -f build/$(APP_NAME).dmg build/$(APP_NAME)-shrunk.dmg build/$(APP_NAME)-build.dmg build/$(DIST_NAME).zip
	rm -rf build/$(APP_NAME).app build/test/test-dmg build/test/test-shell
	rmdir build/test || true
	rmdir build || true

clean: clean-build
	rm -f $(SOURCE_TARBALL) Brewfile.lock.json

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app


# Set special targets
.PHONY: app dmg build fetch-source install-dependencies zip install test test-dmg test-shell clean-build clean uninstall
.PRECIOUS: build/$(APP_NAME)-build.dmg
.INTERMEDIATE: build/$(APP_NAME)-shrunk.dmg
.SECONDARY: $(SOURCE_TARBALL) Brewfile.lock.json build/$(APP_NAME)-build.dmg build/$(APP_NAME).dmg
.DELETE_ON_ERROR:
