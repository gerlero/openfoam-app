# Build configuration
SHELL = /bin/bash
OPENFOAM_VERSION = 2506
APP_NAME = OpenFOAM-v$(OPENFOAM_VERSION)

ifeq ($(OPENFOAM_VERSION),2112)
OPENFOAM_PATCH_LEVEL = 220610
else ifeq ($(OPENFOAM_VERSION),2212)
OPENFOAM_PATCH_LEVEL = 230612
else
OPENFOAM_PATCH_LEVEL = 0
endif

OPENFOAM_TARBALL_URL = https://dl.openfoam.com/source/v$(OPENFOAM_VERSION)/OpenFOAM-v$(OPENFOAM_VERSION)$(if $(filter-out 0, $(OPENFOAM_PATCH_LEVEL)),_$(OPENFOAM_PATCH_LEVEL)).tgz
OPENFOAM_GIT_REPO_URL = https://gitlab.com/openfoam/core/openfoam.git
OPENFOAM_GIT_BRANCH =
VOLUME_FILESYSTEM = 'Case-sensitive APFS'
WMAKE_NJOBS =
DMG_FORMAT = UDRO
APP_HOMEPAGE = https://github.com/gerlero/openfoam-app
APP_VERSION =
DIST_NAME = openfoam$(OPENFOAM_VERSION)-app-$(shell uname -m)
INSTALL_DIR = /Applications

PIXI_VERSION = 0.61.0

ifeq ($(shell uname -m),arm64)
pixi_binary_tar = pixi-aarch64-apple-darwin.tar.gz
else
pixi_binary_tar = pixi-$(shell uname -m)-apple-darwin.tar.gz
endif
pixi_binary_url = https://github.com/prefix-dev/pixi/releases/download/v$(PIXI_VERSION)/$(pixi_binary_tar)
ifndef OPENFOAM_GIT_BRANCH
openfoam_tarball = sources/$(shell basename $(OPENFOAM_TARBALL_URL))
endif

volume = /Volumes/$(APP_NAME)


# Build targets
app: build/$(APP_NAME).app
build: build/$(APP_NAME)-build.sparsebundle
fetch-source: $(openfoam_tarball)
zip: build/$(DIST_NAME).zip
install: $(INSTALL_DIR)/$(APP_NAME).app


# Build rules
volume_id_file = $(volume)/.vol_id

app_contents = \
	build/$(APP_NAME).app/Contents/Info.plist \
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

build/$(APP_NAME).app: $(app_contents)
	xattr -c -r $@
	codesign --force --deep --sign - $@

build/$(APP_NAME).app/Contents/Info.plist:
	rm -rf build/$(APP_NAME).app
	mkdir -p build
	osacompile -o build/$(APP_NAME).app launch.applescript
	plutil -replace CFBundleDevelopmentRegion -string "en" $@
	plutil -insert CFBundleVersion -string "$(APP_VERSION)-$(DEPENDENCIES_KIND)-$(shell uname -m)" $@
	plutil -insert CFBundleShortVersionString -string "$(APP_VERSION)" $@
	plutil -replace CFBundleIconFile -string "icon.icns" $@
	rm build/$(APP_NAME).app/Contents/Resources/applet.icns

build/$(APP_NAME).app/Contents/Resources/etc/openfoam: Contents/Resources/etc/openfoam
	mkdir -p build/$(APP_NAME).app/Contents/Resources/etc
	cp Contents/Resources/etc/openfoam build/$(APP_NAME).app/Contents/Resources/etc/
	sed -i '' "s|{{app_name}}|$(APP_NAME)|g" build/$(APP_NAME).app/Contents/Resources/etc/openfoam
	sed -i '' "s|{{app_homepage}}|$(APP_HOMEPAGE)|g" build/$(APP_NAME).app/Contents/Resources/etc/openfoam

build/$(APP_NAME).app/Contents/Resources/volume: Contents/Resources/volume build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp Contents/Resources/volume build/$(APP_NAME).app/Contents/Resources/
	[ ! -d $(volume) ] || hdiutil detach $(volume)
	hdiutil attach build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg
	cat $(volume_id_file)
	sed -i '' "s|{{app_name}}|$(APP_NAME)|g" build/$(APP_NAME).app/Contents/Resources/volume
	sed -i '' "s|{{volume_id}}|$$(cat $(volume_id_file))|g" build/$(APP_NAME).app/Contents/Resources/volume
	hdiutil detach $(volume)

icon_set_files = \
	build/icon.iconset/icon_1024x1024.png \
	build/icon.iconset/icon_512x512@2x.png \
	build/icon.iconset/icon_512x512.png \
	build/icon.iconset/icon_256x256@2x.png \
	build/icon.iconset/icon_256x256.png \
	build/icon.iconset/icon_128x128@2x.png \
	build/icon.iconset/icon_128x128.png \
	build/icon.iconset/icon_64x64@2x.png \
	build/icon.iconset/icon_64x64.png \
	build/icon.iconset/icon_32x32@2x.png \
	build/icon.iconset/icon_32x32.png \
	build/icon.iconset/icon_16x16@2x.png \
	build/icon.iconset/icon_16x16.png

build/$(APP_NAME).app/Contents/Resources/icon.icns: $(icon_set_files)
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	iconutil --convert icns --output build/$(APP_NAME).app/Contents/Resources/icon.icns build/icon.iconset

build/icon.iconset/icon_1024x1024.png: images/icon.png
	mkdir -p build/icon.iconset
	cp images/icon.png build/icon.iconset/icon_1024x1024.png

build/icon.iconset/icon_512x512@2x.png: build/icon.iconset/icon_1024x1024.png
	cp build/icon.iconset/icon_1024x1024.png build/icon.iconset/icon_512x512@2x.png

build/icon.iconset/icon_512x512.png: pixi images/icon.png
	mkdir -p build/icon.iconset
	./pixi run magick images/icon.png -resize 512x512 build/icon.iconset/icon_512x512.png

build/icon.iconset/icon_256x256@2x.png: build/icon.iconset/icon_512x512.png
	cp build/icon.iconset/icon_512x512.png build/icon.iconset/icon_256x256@2x.png

build/icon.iconset/icon_256x256.png: pixi images/icon.png
	mkdir -p build/icon.iconset
	./pixi run magick images/icon.png -resize 256x256 build/icon.iconset/icon_256x256.png

build/icon.iconset/icon_128x128@2x.png: build/icon.iconset/icon_256x256.png
	cp build/icon.iconset/icon_256x256.png build/icon.iconset/icon_128x128@2x.png

build/icon.iconset/icon_128x128.png: pixi images/icon.png
	mkdir -p build/icon.iconset
	./pixi run magick images/icon.png -resize 128x128 build/icon.iconset/icon_128x128.png

build/icon.iconset/icon_64x64@2x.png: build/icon.iconset/icon_128x128.png
	cp build/icon.iconset/icon_128x128.png build/icon.iconset/icon_64x64@2x.png

build/icon.iconset/icon_64x64.png: pixi images/icon.png
	mkdir -p build/icon.iconset
	./pixi run magick images/icon.png -resize 64x64 build/icon.iconset/icon_64x64.png

build/icon.iconset/icon_32x32@2x.png: build/icon.iconset/icon_64x64.png
	cp build/icon.iconset/icon_64x64.png build/icon.iconset/icon_32x32@2x.png

build/icon.iconset/icon_32x32.png: pixi images/icon.png
	mkdir -p build/icon.iconset
	./pixi run magick images/icon.png -resize 32x32 build/icon.iconset/icon_32x32.png

build/icon.iconset/icon_16x16@2x.png: build/icon.iconset/icon_32x32.png
	cp build/icon.iconset/icon_32x32.png build/icon.iconset/icon_16x16@2x.png

build/icon.iconset/icon_16x16.png: pixi images/icon.png
	mkdir -p build/icon.iconset
	./pixi run magick images/icon.png -resize 16x16 build/icon.iconset/icon_16x16.png

build/$(APP_NAME).app/Contents/Resources/LICENSE: LICENSE
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	cp LICENSE build/$(APP_NAME).app/Contents/Resources/

build/$(APP_NAME).app/Contents/%: Contents/%
	mkdir -p $(@D)
	cp -a $< $@

build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg: build/$(APP_NAME)-build.sparsebundle build/$(APP_NAME).app/Contents/Resources/icon.icns
	[ ! -d $(volume) ] || hdiutil detach $(volume)
	rm -f build/$(APP_NAME)-build.sparsebundle.shadow
	hdiutil attach \
		build/$(APP_NAME)-build.sparsebundle \
		-shadow
	cp build/$(APP_NAME).app/Contents/Resources/icon.icns $(volume)/.VolumeIcon.icns
	SetFile -c icnC $(volume)/.VolumeIcon.icns
	SetFile -a C $(volume)
	uuidgen > $(volume_id_file)
	cat $(volume_id_file)
	rm -rf $(volume)/build
	rm -rf $(volume)/**/.git
	rm -f $(volume)/**/.DS_Store
	rm -rf $(volume)/.fseventsd
	mkdir -p build/$(APP_NAME).app/Contents/Resources
	hdiutil create \
		-format $(DMG_FORMAT) \
		-fs $(VOLUME_FILESYSTEM) \
		-srcfolder $(volume) \
		-nocrossdev \
		build/$(APP_NAME).app/Contents/Resources/$(APP_NAME).dmg \
		-ov
	hdiutil detach $(volume)
	rm build/$(APP_NAME)-build.sparsebundle.shadow

build/$(APP_NAME)-build.sparsebundle: $(openfoam_tarball) pixi environment.tar configure.sh
	[ ! -d $(volume) ] || hdiutil detach $(volume)
	rm -f build/$(APP_NAME)-build.sparsebundle.shadow
	mkdir -p build
	hdiutil create \
		-size 50g \
		-fs $(VOLUME_FILESYSTEM) \
		-volname $(APP_NAME) \
		build/$(APP_NAME)-build.sparsebundle \
		-ov
	hdiutil attach build/$(APP_NAME)-build.sparsebundle
ifdef openfoam_tarball
	tar -xzf $(openfoam_tarball) --strip-components 1 -C $(volume)
else ifdef OPENFOAM_GIT_BRANCH
	rm -rf $(volume)/.git
	git -C $(volume) init -b $(OPENFOAM_GIT_BRANCH)
	git -C $(volume) remote add origin $(OPENFOAM_GIT_REPO_URL)
	git -C $(volume) pull origin $(OPENFOAM_GIT_BRANCH)
	git -C $(volume) submodule update --init --recursive
endif
	./pixi run pixi-unpack --output-directory $(volume) environment.tar
	rm -f $(volume)/activate.sh
	cd $(volume) && "$(CURDIR)/configure.sh"
	cd $(volume) \
		&& source etc/bashrc \
		&& foamSystemCheck \
		&& ( ./Allwmake -j $(WMAKE_NJOBS) -s -q -k || true ) \
		&& ./Allwmake -j $(WMAKE_NJOBS) -s
	hdiutil detach $(volume)

environment.tar: pixi pixi.lock
	./pixi run pixi-pack --environment openfoam

pixi: $(pixi_binary_tar)
	tar -xzf $(pixi_binary_tar) -C .

$(pixi_binary_tar): | $(pixi_binary_tar).sha256
	curl -L -o $(pixi_binary_tar) $(pixi_binary_url)
	shasum -a 256 --check $(pixi_binary_tar).sha256

$(pixi_binary_tar).sha256:
	curl -L -o $(pixi_binary_tar).sha256 $(pixi_binary_url).sha256

$(openfoam_tarball): | $(openfoam_tarball).sha256
	curl -L -o $(openfoam_tarball) $(OPENFOAM_TARBALL_URL)
	[ ! -f $(openfoam_tarball).sha256 ] || shasum -a 256 --check $(openfoam_tarball).sha256

$(openfoam_tarball).sha256:
	$(warning No checksum file found for $(openfoam_tarball); will skip verification)


# Non-build targets and rules
test: pixi
	[ ! -d $(volume) ] || hdiutil detach $(volume)	
	./pixi run build/$(APP_NAME).app/Contents/Resources/etc/openfoam pytest
	build/$(APP_NAME).app/Contents/Resources/volume eject && [ ! -d $(volume) ]

clean-app:
	[ ! -d $(volume) ] || hdiutil detach $(volume)	
	rm -rf build/$(APP_NAME).app build/$(APP_NAME)-build.sparsebundle.shadow

clean-build: clean-app
	rm -f build/$(DIST_NAME).zip
	rm -rf build/$(APP_NAME)-build.sparsebundle
	rm -rf build/icon.iconset
	rmdir build || true

clean: clean-build
	rm -f $(openfoam_tarball) $(openfoam_tarball).sha256 $(pixi_binary_tar) $(pixi_binary_tar).sha256 pixi environment.tar

uninstall:
	rm -rf $(INSTALL_DIR)/$(APP_NAME).app

# Set special targets
.PHONY: app build deps fetch-source zip install test clean-app clean-build clean uninstall
.SECONDARY: $(openfoam_tarball) $(openfoam_tarball).sha256 $(pixi_binary_tar) $(pixi_binary_tar).sha256 pixi environment.tar $(icon_set_files)
.DELETE_ON_ERROR:
