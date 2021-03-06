#!/bin/bash
# bash_build_software.sh contains functions for compiling some select software packages
#
# Copyright (C) 2015-2019, Andrew Kroshko, all rights reserved.
#
# Author: Andrew Kroshko
# Maintainer: Andrew Kroshko <akroshko.public+devel@gmail.com>
# Created: Wed Sep 19, 2018
# Version: 20191209
# URL: https://github.com/akroshko/cic-bash-common
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or (at
# your option) any later version.
#
# This program is distributed in the hope that it will be useful, but
# WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
# General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see http://www.gnu.org/licenses/.
#
# The software packages are generally ones that are unavailable in Debian or ones
# that I wish to compile myself.

# TODO: not yet
# set -e

main () {
    # this is my general command for building software that is unavailable or a
    # different version than the curren Debian

    # assumes I'm in directory with appropriate subdirectories
    sudo true || { echo 'Failed to sudo!' 1>&2; return 1; }
    # at least for now, download and build a few select pieces of software
    [[ ! -d "$HOME/cic-external-vcs" ]] && mkdir -p "$HOME/cic-external-vcs"
    pushd . >/dev/null
    # this is the directory with appropriate subdirectories
    cd "$HOME/cic-external-vcs"
    # TODO: update this as something better and potentially less destructive
    [[ ! -d "$HOME/cic-external-vcs/conkeror-external" ]]             && git clone git://repo.or.cz/conkeror.git                     conkeror-external
    [[ ! -d "$HOME/cic-external-vcs/urxvt-perls-external" ]]          && git clone https://github.com/akroshko/urxvt-perls.git       urxvt-perls-external
    [[ ! -d "$HOME/cic-external-vcs/feh-external" ]]                  && git clone https://git.finalrewind.org/feh                   feh-exteneral
    [[ ! -d "$HOME/cic-external-vcs/girara-external" ]]               && git clone https://git.pwmt.org/pwmt/girara.git              girara-external
    [[ ! -d "$HOME/cic-external-vcs/zathura-external" ]]              && git clone https://git.pwmt.org/pwmt/zathura.git             zathura-external
    [[ ! -d "$HOME/cic-external-vcs/zathura-cb-external" ]]           && git clone https://git.pwmt.org/pwmt/zathura-cb.git          zathura-cb-external
    [[ ! -d "$HOME/cic-external-vcs/zathura-djvu-external" ]]         && git clone https://git.pwmt.org/pwmt/zathura-djvu.git        zathura-djvu-external
    [[ ! -d "$HOME/cic-external-vcs/zathura-pdf-poppler-external" ]]  && git clone https://git.pwmt.org/pwmt/zathura-pdf-poppler.git zathura-pdf-poppler-external
    [[ ! -d "$HOME/cic-external-vcs/zathura-pdf-mupdf-external" ]]    && git clone https://git.pwmt.org/pwmt/zathura-pdf-mupdf.git   zathura-pdf-mupdf-external
    [[ ! -d "$HOME/cic-external-vcs/zathura-ps-external" ]]           && git clone https://git.pwmt.org/pwmt/zathura-ps.git          zathura-ps-external
    # now build, copied from build-software, and should be synced up
    h2 "pip"
    curl https://bootstrap.pypa.io/get-pip.py | sudo python
    curl https://bootstrap.pypa.io/get-pip.py | sudo python3
    # basic build tool use by more and more things
    sudo /usr/local/bin/pip3 install meson
    # skip my non-graphical server for now
    # TODO: something more robust? check if some X11 libraries exist or not
    if [[ "$HOSTNAME" == *server* ]]; then
        warn "This is a computer without X11 and can't build any further without working X11 installation!"
        return 0
    fi
    h2 "wayback downloader"
    sudo gem install wayback_machine_downloader
    build-software-feh
    build-software-mupdf
    # TODO: compile against downloaded poppler
    # build-software-xpdf
    # TODO: why not dockapps here?
    build-software-zathura
    build-software-yacreader
    # finally try out any local software
    # TODO: consistent naming
    if type -P build-software-local.sh; then
        h2 "Building local software!"
        build-software-local.sh
    fi
    popd >/dev/null
}

build-software-zathura () {
    # TODO: more robust specification of different versions and have checks to make sure branches don't hang around
    ################################################################################
    h2 "girara"
    [[ ! -d "girara-external" ]] && { yell "Directory girara-external not found!"; return 1; }
    sudo true || { echo 'Failed to sudo!' 1>&2; return 1; }
    pushd . >/dev/null
    cd girara-external
    check-host-main && git pull
    if git rev-parse --verify develop >/dev/null; then
        git checkout develop
    else
        git checkout --track -b develop origin/develop
    fi
    git checkout 53b862825d7fdb0618d6b7b8680bc7ef53407925
    [[ -d ./build ]] && \rm -rf ./build
    meson build
    cd build
    ninja
    sudo ninja install
    cd ..
    [[ -d ./build ]] && \rm -rf ./build
    git checkout develop
    popd >/dev/null
    ################################################################################
    h2 "zathura"
    [[ ! -d "zathura-external" ]] && yell "Directory zathura-external not found!" && return 1
    pushd . >/dev/null
    cd zathura-external
    check-host-main && git pull
    if git rev-parse --verify develop >/dev/null; then
        git checkout develop
    else
        git checkout --track -b develop origin/develop
    fi
    # TODO: temporary until I upgrade debian, Debian's synctex version not new enough
    # this branch is from April 5th 2018, so other ones can be adjusted accordingly if they cease working
    git checkout 9fe07d39d09058a3c8ac5dfdc169cda36ba45896
    [[ -d ./build ]] && \rm -rf ./build
    meson build
    cd build
    ninja
    sudo ninja install
    cd ..
    [[ -d ./build ]] && \rm -rf ./build
    # TODO: this is temporary too
    git checkout develop
    popd >/dev/null
    ################################################################################
    h2 "zathura-poppler"
    # TODO: do I still need this
    # sudo cp /usr/lib/pkgconfig/girara-gtk3.pc /usr/lib/pkgconfig/girara-gtk.pc
    pushd . >/dev/null
    [[ ! -d "zathura-pdf-poppler-external" ]] && yell "Directory zathura-pdf-poppler-external not found!" && return 1
    cd zathura-pdf-poppler-external
    check-host-main && git pull
    if git rev-parse --verify develop >/dev/null; then
        git checkout develop
    else
        git checkout --track -b develop origin/develop
    fi
    git checkout ebdd7185db0421e411b08667e849596a13c5abda
    [[ -d ./build ]] && \rm -rf ./build
    meson build
    cd build
    ninja
    sudo ninja install
    cd ..
    [[ -d ./build ]] && \rm -rf ./build
    git checkout develop
    popd >/dev/null
    ################################################################################
    h2 "zathura-mupdf"
    # TODO: do I still need this
    # sudo cp /usr/lib/pkgconfig/girara-gtk3.pc /usr/lib/pkgconfig/girara-gtk.pc
    pushd . >/dev/null
    [[ ! -d "zathura-pdf-mupdf-external" ]] && yell "Directory zathura-pdf-mupdf-external not found!" && return 1
    cd zathura-pdf-mupdf-external
    check-host-main && git pull
    if git rev-parse --verify develop >/dev/null; then
        git checkout develop
    else
        git checkout --track -b develop origin/develop
    fi
    # git checkout 43e7027eae61f591b5af3062011156eccad98a5f
    git checkout 95c830c9f6cfe4ba99535ecfba0a700ceb15a25a
    [[ -d ./build ]] && \rm -rf ./build
    meson build
    cd build
    ninja
    sudo ninja install
    cd ..
    [[ -d ./build ]] && \rm -rf ./build
    git checkout develop
    popd >/dev/null
    ################################################################################
    h2 "zathura-djvu"
    [[ ! -d "zathura-djvu-external" ]] && yell "Directory zathura-djvu-external not found!" && return 1
    pushd . >/dev/null
    cd zathura-djvu-external
    check-host-main && git pull
    if git rev-parse --verify develop >/dev/null; then
        git checkout develop
    else
        git checkout --track -b develop origin/develop
    fi
    [[ -d ./build ]] && \rm -rf ./build
    meson build
    cd build
    ninja
    sudo ninja install
    cd ..
    [[ -d ./build ]] && \rm -rf ./build
    git checkout develop
    popd >/dev/null
    ################################################################################
    h2 "zathura-cb"
    [[ ! -d "zathura-cb-external" ]] && yell "Directory zathura-cb-external not found!" && return 1
    pushd . >/dev/null
    cd zathura-cb-external
    if git rev-parse --verify develop >/dev/null; then
        git checkout develop
    else
        git checkout --track -b develop origin/develop
    fi
    check-host-main && git pull
    [[ -d ./build ]] && \rm -rf ./build
    meson build
    cd build
    ninja
    sudo ninja install
    cd ..
    [[ -d ./build ]] && \rm -rf ./build
    git checkout develop
    popd >/dev/null
    ################################################################################
    h2 "zathura-ps"
    [[ ! -d "zathura-ps-external" ]] && yell "Directory zathura-ps-external not found!" && return 1
    pushd . >/dev/null
    cd zathura-ps-external
    check-host-main && git pull
    if git rev-parse --verify develop >/dev/null; then
        git checkout develop
    else
        git checkout --track -b develop origin/develop
    fi
    [[ -d ./build ]] && \rm -rf ./build
    meson build
    cd build
    ninja
    sudo ninja install
    cd ..
    [[ -d ./build ]] && \rm -rf ./build
    git checkout develop
    popd >/dev/null
    # because I've had issues with libraries installed until I run this
    sudo ldconfig
}

# TODO: just install with debian now...
# build-software-xpdf () {
#     # build and installs xpdf
#     h2 "xpdf"
#     [[ ! -d "xpdf-3.04-external" ]] && yell "Directory xpdf-3.04-external not found!" && return 1
#     sudo true || { echo 'Failed to sudo!' 1>&2; return 1; }
#     pushd . >/dev/null
#     cd xpdf-3.04-external
#     make clean
#     ./configure --with-freetype2-library=/usr/lib/x86_64-linux-gnu \
#                 --with-freetype2-includes=/usr/include/freetype2 \
#                 --with-libpng-library=/usr/lib/x86_64-linux-gnu \
#                 --with-libpng-includes=/usr/lib/libpng \
#                 --with-Xm-library=/usr/lib \
#                 --with-Xm-includes=/usr/include/Xm
#     make
#     sudo make install
#     popd >/dev/null
# }


build-software-mupdf () {
    # https://serverfault.com/questions/72476/clean-way-to-write-complex-multi-line-string-to-a-variable
    read -r -d '' MUPDFPATCH << "EOF"
diff -ru mupdf-clean-external/Makerules mupdf-modify-external/Makerules
--- mupdf-clean-external/Makerules	2019-09-26 09:48:41.320010898 -0600
+++ mupdf-modify-external/Makerules	2019-09-26 09:49:58.532566310 -0600
@@ -21,41 +21,41 @@
 SANITIZE_FLAGS += -fsanitize=leak

 ifeq ($(build),debug)
-  CFLAGS += -pipe -g
+  CFLAGS += -fPIC -pipe -g
   LDFLAGS += -g
 else ifeq ($(build),release)
-  CFLAGS += -pipe -O2 -DNDEBUG -fomit-frame-pointer
+  CFLAGS += -fPIC -pipe -O2 -DNDEBUG -fomit-frame-pointer
   LDFLAGS += $(LDREMOVEUNREACH) -Wl,-s
 else ifeq ($(build),small)
-  CFLAGS += -pipe -Os -DNDEBUG -fomit-frame-pointer
+  CFLAGS += -fPIC -pipe -Os -DNDEBUG -fomit-frame-pointer
   LDFLAGS += $(LDREMOVEUNREACH) -Wl,-s
 else ifeq ($(build),valgrind)
-  CFLAGS += -pipe -O2 -DNDEBUG -DPACIFY_VALGRIND -fno-omit-frame-pointer
+  CFLAGS += -fPIC -pipe -O2 -DNDEBUG -DPACIFY_VALGRIND -fno-omit-frame-pointer
   LDFLAGS += $(LDREMOVEUNREACH) -Wl,-s
 else ifeq ($(build),sanitize)
-  CFLAGS += -pipe -g -fno-omit-frame-pointer $(SANITIZE_FLAGS)
+  CFLAGS += -fPIC -pipe -g -fno-omit-frame-pointer $(SANITIZE_FLAGS)
   LDFLAGS += -g $(SANITIZE_FLAGS)
 else ifeq ($(build),sanitize-release)
-  CFLAGS += -pipe -O2 -DNDEBUG -fno-omit-frame-pointer $(SANITIZE_FLAGS)
+  CFLAGS += -fPIC -pipe -O2 -DNDEBUG -fno-omit-frame-pointer $(SANITIZE_FLAGS)
   LDFLAGS += $(LDREMOVEUNREACH) -Wl,-s $(SANITIZE_FLAGS)
 else ifeq ($(build),profile)
-  CFLAGS += -pipe -O2 -DNDEBUG -pg
+  CFLAGS += -fPIC -pipe -O2 -DNDEBUG -pg
   LDFLAGS += -pg
 else ifeq ($(build),coverage)
-  CFLAGS += -pipe -g -pg -fprofile-arcs -ftest-coverage
+  CFLAGS += -fPIC -pipe -g -pg -fprofile-arcs -ftest-coverage
   LIBS += -lgcov
 else ifeq ($(build),native)
-  CFLAGS += -pipe -O2 -DNDEBUG -fomit-frame-pointer -march=native
+  CFLAGS += -fPIC -pipe -O2 -DNDEBUG -fomit-frame-pointer -march=native
   LDFLAGS += $(LDREMOVEUNREACH) -Wl,-s
 else ifeq ($(build),memento)
-  CFLAGS += -pipe -g -DMEMENTO
+  CFLAGS += -fPIC -pipe -g -DMEMENTO
   LDFLAGS += -g -rdynamic
   ifneq ($(HAVE_LIBDL),no)
     CFLAGS += -DHAVE_LIBDL
     LIBS += -ldl
   endif
 else ifeq ($(build),gperf)
-  CFLAGS += -pipe -O2 -DNDEBUG -fomit-frame-pointer -DGPERF
+  CFLAGS += -fPIC -pipe -O2 -DNDEBUG -fomit-frame-pointer -DGPERF
   LIBS += -lprofiler
 else
   $(error unknown build setting: '$(build)')
diff -ru mupdf-clean-external/platform/wasm/Makefile mupdf-modify-external/platform/wasm/Makefile
--- mupdf-clean-external/platform/wasm/Makefile	2019-09-26 09:48:41.684013529 -0600
+++ mupdf-modify-external/platform/wasm/Makefile	2019-09-26 09:51:00.117005210 -0600
@@ -10,13 +10,13 @@
 $(MUPDF_CORE) : .FORCE
 	$(MAKE) -j4 -C ../.. \
 		OUT=wasm build=release \
-		XCFLAGS='-DTOFU -DTOFU_CJK -DFZ_ENABLE_SVG=0 -DFZ_ENABLE_HTML=0 -DFZ_ENABLE_EPUB=0 -DFZ_ENABLE_JS=0' \
+		XCFLAGS='-fPIC -DTOFU -DTOFU_CJK -DFZ_ENABLE_SVG=0 -DFZ_ENABLE_HTML=0 -DFZ_ENABLE_EPUB=0 -DFZ_ENABLE_JS=0' \
 		generate
 	BASH_SOURCE=$(EMSDK_DIR)/emsdk_env.sh; \
 	. $(EMSDK_DIR)/emsdk_env.sh; \
 	$(MAKE) -j4 -C ../.. \
 		OS=wasm build=release \
-		XCFLAGS='-DTOFU -DTOFU_CJK -DFZ_ENABLE_SVG=0 -DFZ_ENABLE_HTML=0 -DFZ_ENABLE_EPUB=0 -DFZ_ENABLE_JS=0' \
+		XCFLAGS='-fPIC -DTOFU -DTOFU_CJK -DFZ_ENABLE_SVG=0 -DFZ_ENABLE_HTML=0 -DFZ_ENABLE_EPUB=0 -DFZ_ENABLE_JS=0' \
 		libs

 wasm: $(MUPDF_JS) $(MUPDF_WASM)
EOF
    # builds and installs mupdf
    # TODO: some of the commands below are probably excessive
    h2 "mupdf"
    [[ ! -d "mupdf-external" ]] && yell "Directory mupdf-external not found!" && return 1
    sudo true || { echo 'Failed to sudo!' 1>&2; return 1; }
    pushd . >/dev/null
    cd mupdf-external
    git checkout b1cc2167d698404014d79b9f3794af03312c7ec6
    make clean
    git reset --hard HEAD
    patch -p1 <<< "$MUPDFPATCH"
    make clean
    [[ -d "thirdparty" ]] && \rm -rf thirdparty
    make clean
    check-host-main && git pull
    git submodule update --init
    # seems to be necessary for this one
    make prefix=/usr/local
    sudo make prefix=/usr/local install
    make clean
    # undo the patch
    git reset --hard HEAD
    make clean
    # get to master in case I checked out wierd branch
    git checkout master
    popd >/dev/null
}

build-software-feh () {
    # builds and installs the feh image viewer
    h2 "feh"
    [[ ! -d "feh-external" ]] && yell "Directory feh-external not found!" && return 1
    sudo true || { echo 'Failed to sudo!' 1>&2; return 1; }
    # must be in proper directory
    pushd . >/dev/null
    cd feh-external
    check-host-main && git pull
    make clean
    make exif=1 help=1 xinerama=0
    sudo make install
    popd >/dev/null
}

build-software-yacreader () {
    h2 "unarr (for yacreader)"
    [[ ! -d "unarr-external" ]] && yell "Directory unarr-external not found!" && return 1
    sudo true || { echo 'Failed to sudo!' 1>&2; return 1; }
    pushd . >/dev/null
    cd unarr-external
    [[ -d "build" ]] && \rm -rf build
    mkdir -p build
    cd build
    cmake ..
    make
    sudo make install
    popd >/dev/null
    h2 "yacreader"
    [[ ! -d "yacreader-external" ]] && yell "Directory yacreader-external not found!" && return 1
    pushd . >/dev/null
    cd yacreader-external
    make clean
    /usr/lib/x86_64-linux-gnu/qt5/bin/qmake PREFIX=/usr/local
    make
    sudo make install
    popd >/dev/null
}

build-software-dockapps () {
    # builds and dockapps for X11
    pushd . >/dev/null
    cd "$HOME/cic-external-vcs/"
    # need proper version of dockapps and wmgeneral built
    # https://unix.stackexchange.com/questions/67781/use-shared-libraries-in-usr-local-lib
    h2 "libdockapps"
    [[ ! -d "dockapps-external" ]] && yell "Directory dockapps-external not found!" && return 1
    sudo true || { echo 'Failed to sudo!' 1>&2; return 1; }
    pushd . >/dev/null
    cd dockapps-external
    check-host-main && git pull
    cd libdockapp
    make clean
    ./configure
    make
    sudo make install
    popd >/dev/null
    sudo ldconfig
    h2 "pywmdockapps"
    pushd . >/dev/null
    cd pywmdockapps-external/pywmdockapps-1.21
    [[ -d ./build ]] && sudo \rm -rf ./build
    sudo python ./setup.py install
    [[ -d ./build ]] && sudo \rm -rf ./build
    popd >/dev/null
    h2 "wmtimer"
    pushd . >/dev/null
    cd wmtimer-external
    check-host-main && git pull
    cd wmtimer
    make clean
    make
    sudo make install
    # TODO: a fix somehow needed
    sudo chmod 755 /usr/local/bin/wmtimer
    popd >/dev/null
    h2 "wmsun"
    pushd . >/dev/null
    cd dockapps-external/wmsun
    make clean
    LDFLAGS="-L/usr/local/lib" make
    sudo make install
    popd >/dev/null
    h2 "wmweather"
    pushd . >/dev/null
    cd wmweather-external/wmweather-2.4.6/src
    make clean
    ./configure
    make
    sudo make install
    popd >/dev/null
    h2 "wmweatherplus"
    pushd . >/dev/null
    cd wmweatherplus-external
    make clean
    ./configure
    make
    sudo make install
    popd >/dev/null
    h2 "wmcalc"
    pushd . >/dev/null
    cd dockapps-external/wmcalc
    make clean
    make
    sudo make install
    popd >/dev/null
    h2 "wmgtemp"
    pushd . >/dev/null
    cd dockapps-external/wmgtemp
    autoreconf -i
    make clean
    ./configure
    make
    sudo make install
    popd >/dev/null
    h2 "wmcpufreq"
    pushd . >/dev/null
    cd dockapps-external/wmcpufreq/wmcpufreq
    make clean
    SYSTEM="-L/usr/local/lib" make
    sudo make install
    popd >/dev/null
    popd >/dev/null
}

main "$@"
