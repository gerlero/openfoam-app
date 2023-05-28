# Build configuration
SHELL = /bin/bash
OPENFOAM_VERSION = 2212
APP_NAME = OpenFOAM-v$(OPENFOAM_VERSION)
SOURCE_TARBALL_URL = https://dl.openfoam.com/source/v$(OPENFOAM_VERSION)/OpenFOAM-v$(OPENFOAM_VERSION).tgz
OPENFOAM_GIT_REPO_URL = https://develop.openfoam.com/Development/openfoam.git
OPENFOAM_GIT_BRANCH =
VOLUME_FILESYSTEM = 'Case-sensitive APFS'
WMAKE_NJOBS =
DEPENDENCIES_KIND = standalone
DMG_FORMAT = UDRO
APP_HOMEPAGE = https://github.com/gerlero/openfoam-app
APP_VERSION =
TEST_DIR = build/test-v$(OPENFOAM_VERSION)

ifeq ($(DEPENDENCIES_KIND),standalone)
DIST_NAME = openfoam$(OPENFOAM_VERSION)-app-$(shell uname -m)
else
DIST_NAME = openfoam$(OPENFOAM_VERSION)-app-$(DEPENDENCIES_KIND)-$(shell uname -m)
endif

INSTALL_DIR = /Applications

ifndef OPENFOAM_GIT_BRANCH
SOURCE_TARBALL = $(shell basename $(SOURCE_TARBALL_URL))
endif


# Build targets
app: build/$(APP_NAME).app
build: build/$(APP_NAME)-build.sparsebundle
deps: build/$(APP_NAME)-deps.sparsebundle
fetch-source: $(SOURCE_TARBALL)

ifeq ($(DEPENDENCIES_KIND),both)
zip:
	$(MAKE) zip DEPENDENCIES_KIND=standalone
	$(MAKE) clean-app
	$(MAKE) zip DEPENDENCIES_KIND=homebrew
	$(MAKE) clean-app
else
zip: build/$(DIST_NAME).zip
endif

install: $(INSTALL_DIR)/$(APP_NAME).app


# Build rules
VOLUME = /Volumes/$(APP_NAME)
VOLUME_ID_FILE = $(VOLUME)/.vol_id

APP_CONTENTS = \
	build/$(APP_NAME).app/Contents/Info.plist \
	build/$(APP_NAME).app/Contents/MacOS/launch \
	build/$(APP_NAME).app/Contents/Resources/etc/openfoam \
	build/$(APP_NAME).app/Contents/Resources/etc/bashrc \
	build/$(APP_NAME).app/Contents/Resources/LICENSE \
	build/$(APP_NAME).app/Contents/Resources/icon.icns \
	build/$(APP_NAME).app/Contents/Resources/volume \
	build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg


$(INSTALL_DIR)/$(APP_NAME).app: build/$(APP_NAME).app
	cp -r build/$(APP_NAME).app $(INSTALL_DIR)/

build/$(DIST_NAME).zip: build/$(APP_NAME).app
	cd build && zip -r --symlinks $(DIST_NAME).zip $(APP_NAME).app
	shasum -a 256 build/$(DIST_NAME).zip

build/$(APP_NAME).app: $(APP_CONTENTS)

build/$(APP_NAME).app/Contents/Info.plist: Contents/Info.plist | build/$(APP_NAME).app/Contents/MacOS/launch build/$(APP_NAME).app/Contents/Resources/icon.icns
	mkdir -p build/$(APP_NAME).app/Contents
	cp Contents/Info.plist build/$(APP_NAME).app/Contents/
	sed -i '' "s|{{APP_VERSION}}|$(APP_VERSION)|g" build/$(APP_NAME).app/Contents/Info.plist
	sed -i '' "s|{{DEPENDENCIES_KIND}}|$(DEPENDENCIES_KIND)|g" build/$(APP_NAME).app/Contents/Info.plist
	sed -i '' "s|{{ARCH}}|$(shell uname -m)|g" build/$(APP_NAME).app/Contents/Info.plist

build/$(APP_NAME).app/Contents/Resources/etc/openfoam: Contents/Resources/etc/openfoam | build/$(APP_NAME).app/Contents/Resources/volume
	mkdir -p build/$(APP_NAME).app/Contents/Resources/etc
	cp Contents/Resources/etc/openfoam build/$(APP_NAME).app/Contents/Resources/etc/
	sed -i '' "s|{{APP_NAME}}|$(APP_NAME)|g" build/$(APP_NAME).app/Contents/Resources/etc/openfoam
	sed -i '' "s|{{APP_HOMEPAGE}}|$(APP_HOMEPAGE)|g" build/$(APP_NAME).app/Contents/Resources/etc/openfoam

build/$(APP_NAME).app/Contents/Resources/volume: Contents/Resources/volume build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp Contents/Resources/volume build/$(APP_NAME).app/Contents/Resources/
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	cat $(VOLUME_ID_FILE)
	sed -i '' "s|{{APP_NAME}}|$(APP_NAME)|g" build/$(APP_NAME).app/Contents/Resources/volume
	sed -i '' "s|{{VOLUME_ID}}|$$(cat $(VOLUME_ID_FILE))|g" build/$(APP_NAME).app/Contents/Resources/volume
	hdiutil detach $(VOLUME)

build/$(APP_NAME).app/Contents/Resources/LICENSE: LICENSE
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp LICENSE build/$(APP_NAME).app/Contents/Resources/

build/$(APP_NAME).app/Contents/%: Contents/%
	mkdir -p $(@D)
	cp -a $< $@

build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg: build/$(APP_NAME)-build.sparsebundle build/$(APP_NAME).app/Contents/Resources/icon.icns
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach \
		build/$(APP_NAME)-build.sparsebundle \
		-shadow
	cp build/$(APP_NAME).app/Contents/Resources/icon.icns $(VOLUME)/.VolumeIcon.icns
	SetFile -c icnC $(VOLUME)/.VolumeIcon.icns
	SetFile -a C $(VOLUME)
	uuidgen > $(VOLUME_ID_FILE)
	cat $(VOLUME_ID_FILE)
	rm -rf $(VOLUME)/homebrew
	[ ! -L $(VOLUME)/usr ] || rm $(VOLUME)/usr
	rm -rf $(VOLUME)/build
	rm -rf $(VOLUME)/**/.git
	rm -f $(VOLUME)/**/.DS_Store
ifeq ($(DEPENDENCIES_KIND),standalone)
	rm $(VOLUME)/usr/bin/brew
	rm $(VOLUME)/Brewfile
	rm $(VOLUME)/Brewfile.lock.json
else ifeq ($(DEPENDENCIES_KIND),homebrew)
	rm -rf $(VOLUME)/usr
	ln -s $(shell brew --prefix) $(VOLUME)/usr
else
	$(error Invalid value for DEPENDENCIES_KIND)
endif
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
ifdef SOURCE_TARBALL
	tar -xzf $(SOURCE_TARBALL) --strip-components 1 -C $(VOLUME)
else ifdef OPENFOAM_GIT_BRANCH
	git -C $(VOLUME) init -b $(OPENFOAM_GIT_BRANCH)
	git -C $(VOLUME) remote add origin $(OPENFOAM_GIT_REPO_URL)
	git -C $(VOLUME) pull origin $(OPENFOAM_GIT_BRANCH)
	git -C $(VOLUME) submodule update --init --recursive
endif
	cd $(VOLUME) \
		&& "$(CURDIR)/configure.sh" \
		&& source etc/bashrc \
		&& foamSystemCheck \
		&& ( ./Allwmake -j $(WMAKE_NJOBS) -s -q -k || true ) \
		&& ./Allwmake -j $(WMAKE_NJOBS) -s
	hdiutil detach $(VOLUME)

build/$(APP_NAME)-deps.sparsebundle: Brewfile $(if $(filter homebrew,$(DEPENDENCIES_KIND)),Brewfile.lock.json)
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	mkdir -p build
	hdiutil create \
		-size 50g \
		-fs $(VOLUME_FILESYSTEM) \
		-volname $(APP_NAME) \
		build/$(APP_NAME)-deps.sparsebundle \
		-ov -attach
	cp Brewfile $(VOLUME)/
ifeq ($(DEPENDENCIES_KIND),standalone)
	git clone https://github.com/Homebrew/brew $(VOLUME)/homebrew
	mkdir -p $(VOLUME)/usr/bin
	ln -s ../../homebrew/bin/brew $(VOLUME)/usr/bin/
	$(VOLUME)/usr/bin/brew bundle --file $(VOLUME)/Brewfile --verbose
	$(VOLUME)/usr/bin/brew autoremove
	$(VOLUME)/usr/bin/brew list --versions
else ifeq ($(DEPENDENCIES_KIND),homebrew)
	brew bundle check --verbose --no-upgrade
	cp Brewfile.lock.json $(VOLUME)/
	ln -s $(shell brew --prefix) $(VOLUME)/usr
else
	$(error Invalid value for DEPENDENCIES_KIND)
endif
	hdiutil detach $(VOLUME)

$(SOURCE_TARBALL): $(or $(wildcard $(SOURCE_TARBALL).sha256), \
					$(warning No checksum file found for $(SOURCE_TARBALL); will skip verification))
	curl -L -o $(SOURCE_TARBALL) $(SOURCE_TARBALL_URL)
	[ -z $< ] || shasum -a 256 -c $<

Brewfile.lock.json: Brewfile
	brew bundle


# Non-build targets and rules
test: test-dmg test-openfoam test-bash test-zsh

test-openfoam:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -rf $(TEST_DIR)/test-openfoam
	mkdir -p $(TEST_DIR)/test-openfoam
	build/$(APP_NAME).app/Contents/Resources/etc/openfoam -c foamInstallationTest
	cd $(TEST_DIR)/test-openfoam \
		&& "$(CURDIR)/build/$(APP_NAME).app/Contents/Resources/etc/openfoam" < "$(CURDIR)/test.sh"
	build/$(APP_NAME).app/Contents/Resources/volume eject && [ ! -d $(VOLUME) ]

test-bash:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -rf $(TEST_DIR)/test-bash
	mkdir -p $(TEST_DIR)/test-bash
	PATH=$(VOLUME)/usr/opt/bash/bin:$$PATH bash -c \
		'source build/$(APP_NAME).app/Contents/Resources/etc/bashrc; \
		set -ex; \
		foamInstallationTest; \
		cd $(TEST_DIR)/test-bash; \
		source "$(CURDIR)/test.sh"'
	build/$(APP_NAME).app/Contents/Resources/volume eject && [ ! -d $(VOLUME) ]

test-zsh:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -rf $(TEST_DIR)/test-zsh
	mkdir -p $(TEST_DIR)/test-zsh
	zsh -c \
		'source build/$(APP_NAME).app/Contents/Resources/etc/bashrc; \
		set -ex; \
		foamInstallationTest; \
		cd $(TEST_DIR)/test-zsh; \
		source "$(CURDIR)/test.sh"'
	build/$(APP_NAME).app/Contents/Resources/volume eject && [ ! -d $(VOLUME) ]

test-dmg:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	rm -rf $(TEST_DIR)/test-dmg
	mkdir -p $(TEST_DIR)/test-dmg
	cd $(TEST_DIR)/test-dmg \
		&& source $(VOLUME)/etc/bashrc \
		&& foamInstallationTest \
		&& bash -ex "$(CURDIR)/test.sh"
	hdiutil detach $(VOLUME)

clean-app:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)	
	rm -rf build/$(APP_NAME).app

clean-build: clean-app
	rm -f build/$(DIST_NAME).zip
	rm -rf build/$(APP_NAME)-build.sparsebundle build/$(APP_NAME)-deps.sparsebundle $(TEST_DIR)/test-openfoam $(TEST_DIR)/test-bash $(TEST_DIR)/test-zsh $(TEST_DIR)/test-dmg
	rmdir $(TEST_DIR) || true
	rmdir build || true

clean: clean-build
	rm -f $(SOURCE_TARBALL) Brewfile.lock.json

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app


# Set special targets
.PHONY: app build deps fetch-source zip install test test-openfoam test-bash test-zsh test-dmg clean-app clean-build clean uninstall
.PRECIOUS: build/$(APP_NAME)-build.sparsebundle
.SECONDARY: $(SOURCE_TARBALL) Brewfile.lock.json build/$(APP_NAME)-deps.sparsebundle build/$(APP_NAME)-build.sparsebundle
.DELETE_ON_ERROR:
