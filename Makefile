SHELL = /bin/zsh

FOAM_VERSION = 2112

TARGET = app

APP_NAME = OpenFOAM-v$(FOAM_VERSION)
DMG_FILESYSTEM = 'Case-sensitive APFS'
FINAL_DMG_FORMAT = UDRO

BUILD_DMG_SIZE = 5g

DIST_NAME = openfoam$(FOAM_VERSION)-app-$(shell uname -m)
INSTALL_DIR = ~/Applications/

SOURCE_TARBALL = OpenFOAM-v$(FOAM_VERSION).tgz
SOURCE_TARBALL_URL = https://sourceforge.net/projects/openfoam/files/v$(FOAM_VERSION)/OpenFOAM-v$(FOAM_VERSION).tgz


DEPENDENCIES = Brewfile.lock.json
BUILD_DMG_FILE = build/$(APP_NAME)-build.dmg
FINAL_DMG_FILE = build/$(APP_NAME).dmg
VOLUME = /Volumes/$(APP_NAME)
APP_BUNDLE = build/$(APP_NAME).app
ZIPPED_APP_BUNDLE = build/$(DIST_NAME).zip
INSTALLED_APP_BUNDLE = $(INSTALL_DIR)/$(APP_NAME).app

default: $(TARGET)
zip: $(ZIPPED_APP_BUNDLE)
app: $(APP_BUNDLE)
dmg: $(FINAL_DMG_FILE)
build: $(BUILD_DMG_FILE)
fetch-source: $(SOURCE_TARBALL)
install-dependencies: $(DEPENDENCIES)
install: $(INSTALLED_APP_BUNDLE)

$(ZIPPED_APP_BUNDLE): $(APP_BUNDLE)
	cd build && zip -r ../$(ZIPPED_APP_BUNDLE) $(APP_NAME).app
	shasum -a 256 $(ZIPPED_APP_BUNDLE)

$(INSTALLED_APP_BUNDLE): $(APP_BUNDLE)
	cp -r $(APP_BUNDLE) $(INSTALLED_APP_BUNDLE)

$(APP_BUNDLE): $(FINAL_DMG_FILE)
	mkdir $(APP_BUNDLE)
	mkdir $(APP_BUNDLE)/Contents
	mkdir $(APP_BUNDLE)/Contents/MacOS
	mkdir $(APP_BUNDLE)/Contents/Resources
	cp Info.plist $(APP_BUNDLE)/Contents/
	cp launch $(APP_BUNDLE)/Contents/MacOS/
	cp openfoam $(APP_BUNDLE)/Contents/MacOS/
	sed -i '' "s/{{FOAM_VERSION}}/$(FOAM_VERSION)/g" $(APP_BUNDLE)/Contents/MacOS/openfoam
	cp icon.icns $(APP_BUNDLE)/Contents/Resources/
	cp LICENSE $(APP_BUNDLE)/Contents/Resources/
	cp $(FINAL_DMG_FILE) $(APP_BUNDLE)/Contents/Resources/

TEMP_DMG_FILE = build/temp.dmg
$(FINAL_DMG_FILE): $(BUILD_DMG_FILE)
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	cp $(BUILD_DMG_FILE) $(TEMP_DMG_FILE)
	hdiutil attach $(TEMP_DMG_FILE)
	rm -rf $(VOLUME)/build
	rm -f $(VOLUME)/.DS_Store
	rm -rf $(VOLUME)/.fseventsd || true
	hdiutil detach $(VOLUME)
	hdiutil resize -sectors min $(TEMP_DMG_FILE)
	hdiutil convert $(TEMP_DMG_FILE) -format $(FINAL_DMG_FORMAT) -o $(FINAL_DMG_FILE)
	rm $(TEMP_DMG_FILE)

$(BUILD_DMG_FILE): $(SOURCE_TARBALL) $(DEPENDENCIES)
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
	echo 'export WM_COMPILER=Clang' >> $(VOLUME)/etc/prefs.sh
	echo 'export CPATH=$$(brew --prefix)/include' >> $(VOLUME)/etc/prefs.sh
	echo 'export LIBRARY_PATH=$$(brew --prefix)/lib' >> $(VOLUME)/etc/prefs.sh
	cd $(VOLUME) && bin/tools/foamConfigurePaths \
		-adios-path '$$(brew --prefix)/opt/adios2' \
		-boost-path '$$(brew --prefix)/opt/boost' \
		-cmake-path '$$(brew --prefix)/opt/cmake' \
		-fftw-path '$$(brew --prefix)/opt/fftw' \
		-kahip-path '$$(brew --prefix)/opt/kahip' \
		-metis-path '$$(brew --prefix)/opt/metis' \
		-scotch-path '$$(brew --prefix)/opt/scotch'
	echo 'export FOAM_DYLD_LIBRARY_PATH="$$DYLD_LIBRARY_PATH"' >> $(VOLUME)/etc/bashrc
	cd $(VOLUME) && source etc/bashrc && foamSystemCheck && ( ./Allwmake -j $(WMAKE_NJOBS) -s -q -k; ./Allwmake -j $(WMAKE_NJOBS) -s )
	hdiutil detach $(VOLUME)

$(SOURCE_TARBALL):
	curl -L -o $(SOURCE_TARBALL) $(SOURCE_TARBALL_URL)

$(DEPENDENCIES): Brewfile
	brew bundle

TEST_DIR = build/test
test-dmg:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	hdiutil attach $(FINAL_DMG_FILE)
	source $(VOLUME)/etc/bashrc && foamInstallationTest
	rm -rf $(TEST_DIR)/
	mkdir -p $(TEST_DIR)
	source $(VOLUME)/etc/bashrc && cp -r "$$FOAM_TUTORIALS"/incompressible/simpleFoam/pitzDaily $(TEST_DIR)/
	source $(VOLUME)/etc/bashrc && cd $(TEST_DIR)/pitzDaily \
		&& blockMesh \
		&& simpleFoam
	source $(VOLUME)/etc/bashrc && cp -r "$$FOAM_TUTORIALS"/basic/laplacianFoam/flange $(TEST_DIR)/
	source $(VOLUME)/etc/bashrc && cd $(TEST_DIR)/flange \
		&& cp -r 0.orig 0 \
		&& ansysToFoam "$$FOAM_TUTORIALS"/resources/geometry/flange.ans -scale 0.001 \
		&& decomposePar \
		&& mpirun -np 4 --oversubscribe laplacianFoam -parallel \
		&& reconstructPar
	hdiutil detach $(VOLUME)

clean-build:
	[ ! -d $(VOLUME) ] || hdiutil detach $(VOLUME)
	rm -f $(BUILD_DMG_FILE) $(FINAL_DMG_FILE) $(ZIPPED_APP_BUNDLE) $(TEMP_DMG_FILE)
	rm -rf $(APP_BUNDLE) $(TEST_DIR)
	rmdir build || true

clean-all: clean-build
	rm -f $(SOURCE_TARBALL) Brewfile.lock.json

uninstall:
	rm -rf $(INSTALLED_APP_BUNDLE)

.PHONY: default zip app dmg build fetch-source install-dependencies install test-dmg clean-build clean-all uninstall
