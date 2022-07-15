# Build configuration
SHELL = bash
OPENFOAM_VERSION = 2206
APP_NAME = OpenFOAM-v$(OPENFOAM_VERSION)
APP_HOMEPAGE = https://github.com/gerlero/openfoam-app
APP_VERSION = ''
SOURCE_TARBALL_URL = https://dl.openfoam.com/source/v$(OPENFOAM_VERSION)/OpenFOAM-v$(OPENFOAM_VERSION).tgz
SOURCE_TARBALL = $(shell basename $(SOURCE_TARBALL_URL))
VOLUME_FILESYSTEM = 'Case-sensitive APFS'
WMAKE_NJOBS = ''
DMG_FORMAT = UDRO
DIST_NAME = openfoam$(OPENFOAM_VERSION)-app-homebrew-$(shell uname -m)
INSTALL_DIR = /Applications


# Build targets
app: build/$(APP_NAME).app
dmg: build/$(APP_NAME).dmg
build: build/$(APP_NAME)-build.sparsebundle
fetch-source: $(SOURCE_TARBALL)
install-dependencies: Brewfile.lock.json
zip: build/$(DIST_NAME).zip
install: $(INSTALL_DIR)/$(APP_NAME).app


# Build rules
VOLUME = /Volumes/$(APP_NAME)
VOLUME_ID_FILE = $(VOLUME)/.vol_id

APP_CONTENTS = \
	build/$(APP_NAME).app/Contents/Info.plist \
	build/$(APP_NAME).app/Contents/MacOS/openfoam \
	build/$(APP_NAME).app/Contents/MacOS/volume \
	build/$(APP_NAME).app/Contents/MacOS/launch \
	build/$(APP_NAME).app/Contents/MacOS/bashrc \
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
	sed -i '' "s|{{ARCH}}|$(shell uname -m)|g" build/$(APP_NAME).app/Contents/Info.plist

build/$(APP_NAME).app/Contents/MacOS/openfoam: Contents/MacOS/openfoam | build/$(APP_NAME).app/Contents/MacOS/volume
	mkdir -p build/$(APP_NAME).app/Contents/MacOS/
	cp Contents/MacOS/openfoam build/$(APP_NAME).app/Contents/MacOS/
	sed -i '' "s|{{APP_HOMEPAGE}}|$(APP_HOMEPAGE)|g" build/$(APP_NAME).app/Contents/MacOS/openfoam

build/$(APP_NAME).app/Contents/MacOS/volume: build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg Contents/MacOS/volume
	mkdir -p build/$(APP_NAME).app/Contents/MacOS/
	cp Contents/MacOS/volume build/$(APP_NAME).app/Contents/MacOS/
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	cat $(VOLUME_ID_FILE)
	sed -i '' "s|{{VOLUME_ID}}|$$(cat $(VOLUME_ID_FILE))|g" build/$(APP_NAME).app/Contents/MacOS/volume
	hdiutil detach $(VOLUME)

build/$(APP_NAME).app/Contents/MacOS/launch: Contents/MacOS/launch | build/$(APP_NAME).app/Contents/MacOS/openfoam
	mkdir -p build/$(APP_NAME).app/Contents/MacOS
	cp Contents/MacOS/launch build/$(APP_NAME).app/Contents/MacOS/

build/$(APP_NAME).app/Contents/MacOS/bashrc: Contents/MacOS/bashrc | build/$(APP_NAME).app/Contents/MacOS/volume
	mkdir -p build/$(APP_NAME).app/Contents/MacOS
	cp Contents/MacOS/bashrc build/$(APP_NAME).app/Contents/MacOS/

build/$(APP_NAME).app/Contents/Resources/LICENSE: LICENSE
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp LICENSE build/$(APP_NAME).app/Contents/Resources/

build/$(APP_NAME).app/Contents/Resources/icon.icns: icon.icns
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp icon.icns build/$(APP_NAME).app/Contents/Resources/

build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg: build/$(APP_NAME).dmg
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp build/$(APP_NAME).dmg build/$(APP_NAME).app/Contents/Resources/

build/$(APP_NAME).dmg: build/$(APP_NAME).sparsebundle
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach build/$(APP_NAME).sparsebundle
	uuidgen > $(VOLUME_ID_FILE)
	cat $(VOLUME_ID_FILE)
	rm -rf $(VOLUME)/build
	rm -f $(VOLUME)/.DS_Store
	rm -rf $(VOLUME)/.fseventsd || true
	hdiutil detach $(VOLUME)
	hdiutil resize \
		-sectors min \
		build/$(APP_NAME).sparsebundle
	hdiutil convert \
		build/$(APP_NAME).sparsebundle \
		-format $(DMG_FORMAT) \
		-o build/$(APP_NAME).dmg -ov

build/$(APP_NAME).sparsebundle: build/$(APP_NAME)-build.sparsebundle
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	cp -r build/$(APP_NAME)-build.sparsebundle build/$(APP_NAME).sparsebundle

build/$(APP_NAME)-build.sparsebundle: $(SOURCE_TARBALL) Brewfile.lock.json configure.sh Brewfile icon.icns
	brew bundle check --verbose --no-upgrade
	cat Brewfile.lock.json
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	mkdir -p build
	hdiutil create \
		-size 50g \
		-fs $(VOLUME_FILESYSTEM) \
		-volname $(APP_NAME) \
		build/$(APP_NAME)-build.sparsebundle \
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
		&& ( ./Allwmake -j $(WMAKE_NJOBS) -s -q -k || true ) \
		&& ./Allwmake -j $(WMAKE_NJOBS) -s
	hdiutil detach $(VOLUME)

$(SOURCE_TARBALL): $(or $(wildcard $(SOURCE_TARBALL).sha256), \
					$(warning No checksum file found for $(SOURCE_TARBALL); will skip verification))
	curl -L -o $(SOURCE_TARBALL) $(SOURCE_TARBALL_URL)
	[ -z $< ] || shasum -a 256 -c $<

Brewfile.lock.json: Brewfile
	brew bundle -f


# Non-build targets and rules
test: test-openfoam test-bash test-zsh

test-openfoam:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -rf build/test/test-openfoam
	mkdir -p build/test/test-openfoam
	build/$(APP_NAME).app/Contents/MacOS/openfoam -c foamInstallationTest
	cd build/test/test-openfoam \
		&& "$(CURDIR)/build/$(APP_NAME).app/Contents/MacOS/openfoam" < "$(CURDIR)/test.sh"
	build/$(APP_NAME).app/Contents/MacOS/volume eject && [ ! -d $(VOLUME) ]

test-bash:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -rf build/test/test-bash
	mkdir -p build/test/test-bash
	bash -c \
		'source build/$(APP_NAME).app/Contents/MacOS/bashrc; \
		set -ex; \
		foamInstallationTest; \
		cd build/test/test-bash; \
		source "$(CURDIR)/test.sh"'
	build/$(APP_NAME).app/Contents/MacOS/volume eject && [ ! -d $(VOLUME) ]

test-zsh:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -rf build/test/test-zsh
	mkdir -p build/test/test-zsh
	zsh -c \
		'source build/$(APP_NAME).app/Contents/MacOS/bashrc; \
		set -ex; \
		foamInstallationTest; \
		cd build/test/test-zsh; \
		source "$(CURDIR)/test.sh"'
	build/$(APP_NAME).app/Contents/MacOS/volume eject && [ ! -d $(VOLUME) ]

test-dmg:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach build/$(APP_NAME).dmg
	rm -rf build/test/test-dmg
	mkdir -p build/test/test-dmg
	cd build/test/test-dmg \
		&& source $(VOLUME)/etc/bashrc \
		&& foamInstallationTest \
		&& $(SHELL) -ex "$(CURDIR)/test.sh"
	hdiutil detach $(VOLUME)

clean-build:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -f build/$(APP_NAME).dmg build/$(DIST_NAME).zip
	rm -rf build/$(APP_NAME).app build/$(APP_NAME)-build.sparsebundle build/test/test-openfoam build/test/test-bash build/test/test-zsh build/test/test-dmg
	rmdir build/test || true
	rmdir build || true

clean: clean-build
	rm -f $(SOURCE_TARBALL) Brewfile.lock.json

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app


# Set special targets
.PHONY: app dmg build fetch-source install-dependencies zip install test test-openfoam test-bash test-zsh test-dmg clean-build clean uninstall
.PRECIOUS: build/$(APP_NAME)-build.sparsebundle
.SECONDARY: $(SOURCE_TARBALL) Brewfile.lock.json build/$(APP_NAME)-build.sparsebundle build/$(APP_NAME).dmg
.INTERMEDIATE: build/$(APP_NAME).sparsebundle
.DELETE_ON_ERROR:
