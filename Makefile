# Build configuration
SHELL = /bin/bash
OPENFOAM_VERSION = 2312
APP_NAME = OpenFOAM-v$(OPENFOAM_VERSION)

ifeq ($(OPENFOAM_VERSION),2112)
OPENFOAM_PATCH_LEVEL = 220610
else ifeq ($(OPENFOAM_VERSION),2212)
OPENFOAM_PATCH_LEVEL = 230612
else
OPENFOAM_PATCH_LEVEL = 0
endif

OPENFOAM_TARBALL_URL = https://dl.openfoam.com/source/v$(OPENFOAM_VERSION)/OpenFOAM-v$(OPENFOAM_VERSION)$(if $(filter-out 0, $(OPENFOAM_PATCH_LEVEL)),_$(OPENFOAM_PATCH_LEVEL)).tgz
OPENFOAM_GIT_REPO_URL = https://develop.openfoam.com/Development/openfoam.git
OPENFOAM_GIT_BRANCH =
VOLUME_FILESYSTEM = 'Case-sensitive APFS'
WMAKE_NJOBS =
DEPS_KIND = bundled
DMG_FORMAT = UDRO
APP_HOMEPAGE = https://github.com/gerlero/openfoam-app
APP_VERSION =
TEST_DIR = build/test-v$(OPENFOAM_VERSION)
DIST_NAME = openfoam$(OPENFOAM_VERSION)-app-$(shell uname -m)
INSTALL_DIR = /Applications

ifndef OPENFOAM_GIT_BRANCH
OPENFOAM_TARBALL = sources/$(shell basename $(OPENFOAM_TARBALL_URL))
endif

VOLUME = /Volumes/$(APP_NAME)


# Build targets
app: | $(VOLUME)
	$(MAKE) build/$(APP_NAME).app
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
build: | $(VOLUME)
	$(MAKE) $(VOLUME)/platforms
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
deps: | $(VOLUME)
	$(MAKE) $(VOLUME)/Brewfile.lock.json
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
fetch-source: $(OPENFOAM_TARBALL)
zip: | $(VOLUME)
	$(MAKE) build/$(DIST_NAME).zip
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)

install: | $(VOLUME)
	$(MAKE) $(INSTALL_DIR)/$(APP_NAME).app
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)


# Build rules
VOLUME_ID_FILE = $(VOLUME)/.vol_id

APP_CONTENTS = \
	build/$(APP_NAME).app/Contents/Info.plist \
	build/$(APP_NAME).app/Contents/MacOS/launch \
	build/$(APP_NAME).app/Contents/Resources/etc/openfoam \
	build/$(APP_NAME).app/Contents/Resources/etc/bashrc \
	build/$(APP_NAME).app/Contents/Resources/LICENSE \
	build/$(APP_NAME).app/Contents/Resources/icon.icns \
	build/$(APP_NAME).app/Contents/Resources/volume \
	build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg \
	build/$(APP_NAME).app/Contents/MacOS/openfoam \
	build/$(APP_NAME).app/Contents/MacOS/bashrc

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
	sed -i '' "s|{{DEPS_KIND}}|$(DEPS_KIND)|g" build/$(APP_NAME).app/Contents/Info.plist
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

build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg: $(VOLUME)/platforms Contents/Resources/icon.icns
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach \
		build/$(APP_NAME)-build.sparsebundle \
		-shadow
	cp Contents/Resources/icon.icns $(VOLUME)/.VolumeIcon.icns
	SetFile -c icnC $(VOLUME)/.VolumeIcon.icns
	SetFile -a C $(VOLUME)
	uuidgen > $(VOLUME_ID_FILE)
	cat $(VOLUME_ID_FILE)
	rm -rf $(VOLUME)/homebrew
	rm -f $(VOLUME)/usr/bin/brew
	rm $(VOLUME)/Brewfile
	rm $(VOLUME)/Brewfile.lock.json
	rm -rf $(VOLUME)/build
	rm -rf $(VOLUME)/**/.git
	rm -f $(VOLUME)/**/.DS_Store
	rm -rf $(VOLUME)/.fseventsd
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

$(VOLUME)/platforms: $(VOLUME)/etc/prefs.sh $(VOLUME)/Brewfile.lock.json scripts/relativize_install_names.py
	cd $(VOLUME) \
		&& source etc/bashrc \
		&& foamSystemCheck \
		&& ( ./Allwmake -j $(WMAKE_NJOBS) -s -q -k || true ) \
		&& ./Allwmake -j $(WMAKE_NJOBS) -s
	cd $(VOLUME) && "$(CURDIR)/scripts/relativize_install_names.py"

$(VOLUME)/etc/prefs.sh: $(OPENFOAM_TARBALL) scripts/configure.sh | $(VOLUME)
	rm -rf $(VOLUME)/etc
ifdef OPENFOAM_TARBALL
	tar -xzf $(OPENFOAM_TARBALL) --strip-components 1 -C $(VOLUME)
else ifdef OPENFOAM_GIT_BRANCH
	rm -rf $(VOLUME)/.git
	git -C $(VOLUME) init -b $(OPENFOAM_GIT_BRANCH)
	git -C $(VOLUME) remote add origin $(OPENFOAM_GIT_REPO_URL)
	git -C $(VOLUME) pull origin $(OPENFOAM_GIT_BRANCH)
	git -C $(VOLUME) submodule update --init --recursive
endif
	cd $(VOLUME) && "$(CURDIR)/scripts/configure.sh"

$(VOLUME)/Brewfile.lock.json: $(VOLUME)/Brewfile | $(VOLUME)/usr
ifeq ($(DEPS_KIND),standalone)
	HOMEBREW_RELOCATABLE_INSTALL_NAMES=1 $(VOLUME)/usr/bin/brew bundle --file $(VOLUME)/Brewfile --cleanup --verbose
	$(VOLUME)/usr/bin/brew list --versions
else
	brew bundle --file $(VOLUME)/Brewfile --no-upgrade
endif
ifeq ($(DEPS_KIND),bundled)
	rm -rf $(VOLUME)/usr
	cd $(VOLUME) && "$(CURDIR)/scripts/bundle_deps.py"
endif

$(VOLUME)/usr: | $(VOLUME)
ifeq ($(DEPS_KIND),standalone)
	git clone https://github.com/Homebrew/brew $(VOLUME)/homebrew
	mkdir -p $(VOLUME)/usr/bin
	ln -s ../../homebrew/bin/brew $(VOLUME)/usr/bin/
else ifeq ($(DEPS_KIND),homebrew)
	ln -s $(shell brew --prefix) $(VOLUME)/usr
else ifeq ($(DEPS_KIND),bundled)
	mkdir $(VOLUME)/usr
else
	$(error Invalid value for DEPS_KIND)
endif

$(VOLUME)/Brewfile: Brewfile | $(VOLUME)
	cp Brewfile $(VOLUME)/

$(VOLUME): | build/$(APP_NAME)-build.sparsebundle
	hdiutil attach build/$(APP_NAME)-build.sparsebundle

build/$(APP_NAME)-build.sparsebundle:
	mkdir -p build
	hdiutil create \
		-size 50g \
		-fs $(VOLUME_FILESYSTEM) \
		-volname $(APP_NAME) \
		build/$(APP_NAME)-build.sparsebundle \
		-ov

$(OPENFOAM_TARBALL): | $(OPENFOAM_TARBALL).sha256
	curl -L -o $(OPENFOAM_TARBALL) $(OPENFOAM_TARBALL_URL)
	[ ! -f $(OPENFOAM_TARBALL).sha256 ] || shasum -a 256 --check $(OPENFOAM_TARBALL).sha256

$(OPENFOAM_TARBALL).sha256:
	$(warning No checksum file found for $(OPENFOAM_TARBALL); will skip verification)


# Non-build targets and rules
test: test-dmg test-openfoam test-bash test-zsh

test-openfoam:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -rf $(TEST_DIR)/test-openfoam
	mkdir -p $(TEST_DIR)/test-openfoam
	build/$(APP_NAME).app/Contents/Resources/etc/openfoam -c foamInstallationTest
	cd $(TEST_DIR)/test-openfoam \
		&& "$(CURDIR)/build/$(APP_NAME).app/Contents/Resources/etc/openfoam" < "$(CURDIR)/scripts/test.sh"
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
		source "$(CURDIR)/scripts/test.sh"'
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
		source "$(CURDIR)/scripts/test.sh"'
	build/$(APP_NAME).app/Contents/Resources/volume eject && [ ! -d $(VOLUME) ]

test-dmg:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	rm -rf $(TEST_DIR)/test-dmg
	mkdir -p $(TEST_DIR)/test-dmg
	cd $(TEST_DIR)/test-dmg \
		&& source $(VOLUME)/etc/bashrc \
		&& foamInstallationTest \
		&& "$(CURDIR)/scripts/test.sh"
	hdiutil detach $(VOLUME)

clean-app:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)	
	rm -rf build/$(APP_NAME).app build/$(APP_NAME)-build.sparsebundle.shadow

clean-build: clean-app
	rm -f build/$(DIST_NAME).zip
	rm -rf build/$(APP_NAME)-build.sparsebundle $(TEST_DIR)/test-openfoam $(TEST_DIR)/test-bash $(TEST_DIR)/test-zsh $(TEST_DIR)/test-dmg
	rmdir $(TEST_DIR) || true
	rmdir build || true

clean: clean-build
	rm -f $(OPENFOAM_TARBALL) Brewfile.lock.json

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app

# Set special targets
.PHONY: app build deps fetch-source zip install test test-openfoam test-bash test-zsh test-dmg clean-app clean-build clean uninstall
.SECONDARY: $(VOLUME) $(OPENFOAM_TARBALL)
.DELETE_ON_ERROR:
