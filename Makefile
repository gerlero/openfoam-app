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
DEPENDENCIES_KIND = standalone
DMG_FORMAT = UDRO
DIST_NAME = openfoam$(OPENFOAM_VERSION)-app-$(DEPENDENCIES_KIND)-$(shell uname -m)
INSTALL_DIR = /Applications


# Build targets
app: build/$(APP_NAME).app
build: build/$(APP_NAME)-build.sparsebundle
deps: build/$(APP_NAME)-deps.sparsebundle
fetch-source: $(SOURCE_TARBALL)
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
	sed -i '' "s|{{DEPENDENCIES_KIND}}|$(DEPENDENCIES_KIND)|g" build/$(APP_NAME).app/Contents/Info.plist
	sed -i '' "s|{{ARCH}}|$(shell uname -m)|g" build/$(APP_NAME).app/Contents/Info.plist

build/$(APP_NAME).app/Contents/MacOS/openfoam: Contents/MacOS/openfoam | build/$(APP_NAME).app/Contents/MacOS/volume
	mkdir -p build/$(APP_NAME).app/Contents/MacOS/
	cp Contents/MacOS/openfoam build/$(APP_NAME).app/Contents/MacOS/
	sed -i '' "s|{{APP_NAME}}|$(APP_NAME)|g" build/$(APP_NAME).app/Contents/MacOS/openfoam
	sed -i '' "s|{{APP_HOMEPAGE}}|$(APP_HOMEPAGE)|g" build/$(APP_NAME).app/Contents/MacOS/openfoam

build/$(APP_NAME).app/Contents/MacOS/volume: build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg Contents/MacOS/volume
	mkdir -p build/$(APP_NAME).app/Contents/MacOS/
	cp Contents/MacOS/volume build/$(APP_NAME).app/Contents/MacOS/
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	cat $(VOLUME_ID_FILE)
	sed -i '' "s|{{APP_NAME}}|$(APP_NAME)|g" build/$(APP_NAME).app/Contents/MacOS/volume
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

build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg: build/$(APP_NAME)-build.sparsebundle icon.icns
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach \
		build/$(APP_NAME)-build.sparsebundle \
		-shadow
	cp icon.icns $(VOLUME)/.VolumeIcon.icns
	SetFile -c icnC $(VOLUME)/.VolumeIcon.icns
	SetFile -a C $(VOLUME)
	uuidgen > $(VOLUME_ID_FILE)
	cat $(VOLUME_ID_FILE)
	[ $(DEPENDENCIES_KIND) != standalone ] || rm -rf $(VOLUME)/usr/bin/brew
	[ $(DEPENDENCIES_KIND) != standalone ] || rm -rf $(VOLUME)/usr/Library
	[ $(DEPENDENCIES_KIND) != standalone ] || rm -rf $(VOLUME)/usr/.git
	[ $(DEPENDENCIES_KIND) != homebrew ] || rm -rf $(VOLUME)/usr
	[ $(DEPENDENCIES_KIND) != homebrew ] || ln -s $(shell brew --prefix) $(VOLUME)/usr
	rm -rf $(VOLUME)/build
	rm -f $(VOLUME)/**/.DS_Store
	rm -rf $(VOLUME)/.fseventsd || true
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	hdiutil create \
		-format $(DMG_FORMAT) \
		-fs $(VOLUME_FILESYSTEM) \
		-srcfolder $(VOLUME) \
		-nocrossdev \
		build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg \
		-ov
	hdiutil detach $(VOLUME)
	rm build/$(APP_NAME)-build.sparsebundle.shadow

build/$(APP_NAME)-build.sparsebundle: build/$(APP_NAME)-deps.sparsebundle $(SOURCE_TARBALL) configure.sh 
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	mv build/$(APP_NAME)-deps.sparsebundle build/$(APP_NAME)-build.sparsebundle
	hdiutil attach build/$(APP_NAME)-build.sparsebundle
	tar -xzf $(SOURCE_TARBALL) --strip-components 1 -C $(VOLUME)
	cd $(VOLUME) \
		&& $(SHELL) -ex "$(CURDIR)/configure.sh" \
		&& source etc/bashrc \
		&& foamSystemCheck \
		&& ( ./Allwmake -j $(WMAKE_NJOBS) -s -q -k || true ) \
		&& ./Allwmake -j $(WMAKE_NJOBS) -s
	hdiutil detach $(VOLUME)

build/$(APP_NAME)-deps.sparsebundle: Brewfile
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	mkdir -p build
	hdiutil create \
		-size 50g \
		-fs $(VOLUME_FILESYSTEM) \
		-volname $(APP_NAME) \
		build/$(APP_NAME)-deps.sparsebundle \
		-ov -attach
	cp Brewfile $(VOLUME)/
	git clone https://github.com/Homebrew/brew $(VOLUME)/usr
	$(VOLUME)/usr/bin/brew bundle --file $(VOLUME)/Brewfile --verbose
	$(VOLUME)/usr/bin/brew autoremove
	cat $(VOLUME)/Brewfile.lock.json
	hdiutil detach $(VOLUME)

$(SOURCE_TARBALL): $(or $(wildcard $(SOURCE_TARBALL).sha256), \
					$(warning No checksum file found for $(SOURCE_TARBALL); will skip verification))
	curl -L -o $(SOURCE_TARBALL) $(SOURCE_TARBALL_URL)
	[ -z $< ] || shasum -a 256 -c $<


# Non-build targets and rules
test: test-dmg test-openfoam test-bash test-zsh

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
	PATH=$(VOLUME)/usr/bin:$$PATH bash -c \
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
	hdiutil attach build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	rm -rf build/test/test-dmg
	mkdir -p build/test/test-dmg
	cd build/test/test-dmg \
		&& source $(VOLUME)/etc/bashrc \
		&& foamInstallationTest \
		&& $(SHELL) -ex "$(CURDIR)/test.sh"
	hdiutil detach $(VOLUME)

clean-app:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)	
	rm -rf build/$(APP_NAME).app

clean-build: clean-app
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -f build/$(DIST_NAME).zip
	rm -rf build/$(APP_NAME)-build.sparsebundle build/$(APP_NAME)-deps.sparsebundle build/test/test-openfoam build/test/test-bash build/test/test-zsh build/test/test-dmg
	rmdir build/test || true
	rmdir build || true

clean: clean-build
	rm -f $(SOURCE_TARBALL)

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app


# Set special targets
.PHONY: app build deps fetch-source zip install test test-openfoam test-bash test-zsh test-dmg clean-app clean-build clean uninstall
.PRECIOUS: build/$(APP_NAME)-build.sparsebundle
.SECONDARY: $(SOURCE_TARBALL) build/$(APP_NAME)-deps.sparsebundle build/$(APP_NAME)-build.sparsebundle
.DELETE_ON_ERROR:
