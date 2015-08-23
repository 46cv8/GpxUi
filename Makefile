# OS Specifics
ifeq ($(OS),Windows_NT)
    # Windows
    QTDEBUGDIR :=
    QTRELEASEDIR :=
    DEBUGTARGET := first
    RELEASETARGET := release
    QTSUBDIRS := build/mingw32
    QTFROMBUILDTOROOT := ../../
    QMAKEDEBUGFLAGS := -r -spec win32-g++ "CONFIG+=debug"
    QTMAKEFILES := $(addsuffix /Makefile,$(QTSUBDIRS))
    QTDEBUGMAKEFILE := $(QTMAKEFILES)
else
    UNAMESYS := $(shell uname -s)
    ifeq ($(UNAMESYS),Darwin)

    # Mac
    QTSUBDIRS := build/darwin
    # what QMAKEFLAGS?
    else

    # Linux
    QTDEBUGDIR := build/linux/debug
    QTRELEASEDIR := build/linux/release
    DEBUGTARGET := all
    RELEASETARGET := all
    QTSUBDIRS :=
    QTFROMBUILDTOROOT := ../../../
    QMAKEDEBUGFLAGS := -r -spec linux-g++-64 "CONFIG+=debug" "CONFIG+=declarative_debug" "CONFIG+=qml_debug"
    QMAKERELEASEFLAGS := -r -spec linux-g++-64
    QTDEBUGMAKEFILE := $(QTDEBUGDIR)/Makefile
    QTRELEASEMAKEFILE := $(QTRELEASEDIR)/Makefile
    QTMAKEFILES := $(QTDEBUGMAKEFILE) $(QTRELEASEMAKEFILE)
    endif
endif

# Variables
SUBDIRS = $(QTSUBDIRS) GPX
QTBIN := $(dir $(abspath $(shell which qmake)))

# Version Variables
# some rigamarole to ensure first character after first dash in version string
# is alphabetic since nuget chokes on a number
GPXUI_VERSION := $(shell git describe --tags --dirty | awk -- '{sub(/-/,"-dev-")}; 1')
GPXUI_RCVERSION := $(shell echo $(GPXUI_VERSION) | awk -- 'BEGIN{FS="[.-]"};{print $$1","$$2","$$3",0"};')
GPXUI_ORIGIN := $(word 2,$(shell git remote -v))

# Squirrel Variables
SQUIRRELWIN = build/squirrel.windows/
SQUIRRELWINBASE = $(SQUIRRELWIN)nuget/
SQUIRRELWINBIN = $(SQUIRRELWINBASE)lib/net45/

# WinDeployQt Variables
# if "static" appears in the abspath of qmake.exe, assume we're statically linking
# because that's how qt works, you build the libraries *and* toolset for static
ifneq (,$(findstring static,$(QTBIN)))
    WINDEPLOYQT = populatewinbin
else
    WINDEPLOYQT = windeployqt
endif


# Rules

.PHONY: first all clean test debug release loopdirs populatewinbin windeployqt squirrel.windows

first debug: build/version.h $(QTDEBUGMAKEFILE)
	for dir in $(QTDEBUGDIR) $(SUBDIRS); do \
		echo "Entering $$dir"; \
		make -C $$dir $(DEBUGTARGET); \
		echo "Exiting $$dir"; \
	done

release: build/version.h $(QTRELEASEMAKEFILE)
	for dir in $(QTRELEASEDIR) $(SUBDIRS); do \
		echo "Entering $$dir"; \
		make -C $$dir $(RELEASETARGET); \
		echo "Exiting $$dir"; \
	done

all clean test: build/version.h $(QTMAKEFILES)
	for dir in $(SUBDIRS); do \
		echo "Entering $$dir"; \
		make -C $$dir $@; \
		echo "Exiting $$dir"; \
	done

$(QTDEBUGMAKEFILE): GpxUi.pro
	mkdir -p $(dir $@)
	cd $(dir $@); qmake $(QTFROMBUILDTOROOT)$< $(QMAKEDEBUGFLAGS)

$(QTRELEASEMAKEFILE): GpxUi.pro
	mkdir -p $(dir $@)
	cd $(dir $@); qmake $(QTFROMBUILDTOROOT)$< $(QMAKERELEASEFLAGS)

build/version.h: .git/HEAD .git/index
	mkdir -p build
	@echo "#define GPXUI_VERSION \"$(GPXUI_VERSION)\"" > $@
	@echo "#define GPXUI_RCVERSION $(GPXUI_RCVERSION)" >> $@
	@echo "#define GPXUI_ORIGIN \"$(GPXUI_ORIGIN)\"" >> $@

populatewinbin: release
	mkdir -p $(SQUIRRELWINBIN)
	cp GPX/src/gpx/win32_obj/gpx.exe $(SQUIRRELWINBIN)
	cp build/mingw32/release/GpxUi.exe $(SQUIRRELWINBIN)
	cp README.md $(SQUIRRELWINBIN)
	cp RELEASE.md $(SQUIRRELWINBIN)
	cp LICENSE $(SQUIRRELWINBIN)
	cp Squirrel.COPYING $(SQUIRRELWINBIN)

windeployqt: populatewinbin
	windeployqt --release-with-debug-info --no-plugins --no-translations $(SQUIRRELWINBIN)GpxUi.exe

squirrel.windows: $(WINDEPLOYQT)
	nuget pack gpx.nuspec -Version $(GPXUI_VERSION) -BasePath $(SQUIRRELWINBASE) -OutputDirectory $(SQUIRRELWIN)
	Squirrel --releasify build/squirrel.windows/GpxUi.$(GPXUI_VERSION).nupkg --releaseDir=$(SQUIRRELWIN)release
