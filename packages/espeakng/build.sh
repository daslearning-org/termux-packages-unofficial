#!/bin/bash

TERMUX_PKG_HOMEPAGE=https://github.com/espeak-ng/espeak-ng
TERMUX_PKG_DESCRIPTION="Custom eSpeak NG for Piper text-to-speech with additional symbols"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@daslearning"
_COMMIT=a4ca101c99de35345f89df58195b2159748b7092
TERMUX_PKG_VERSION=0.0.0-${_COMMIT:0:7}
TERMUX_PKG_SRCURL=https://github.com/espeak-ng/espeak-ng/archive/${_COMMIT}.tar.gz
TERMUX_PKG_SHA256=c8ed6647d2ebba13015f397eede400262ec02710856d6d08d5a27528765d0be0
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_DEPENDS="libc++"
TERMUX_PKG_BREAKS="espeak-dev"
TERMUX_PKG_REPLACES="espeak-dev"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--disable-shared --enable-static --with-async --without-pcaudiolib"
TERMUX_PREFIX=/data/data/com.termux/files/usr

termux_step_post_get_source() {
    # Certain packages are not safe to build on device
    if ${TERMUX_ON_DEVICE_BUILD}; then
        termux_error_exit "Package '${TERMUX_PKG_NAME}' is not safe for on-device builds."
    fi

    # SOVERSION guard
    local _SOVERSION=1
    local e=$(sed -En 's/^SHARED_VERSION="?([0-9]+):([0-9]+):([0-9]+).*/\1-\3/p' \
                Makefile.am)
    if [ ! "${e}" ] || [ "${_SOVERSION}" != "$(( "${e}" ))" ]; then
        termux_error_exit "SOVERSION guard check failed."
    fi

    ./autogen.sh || {
        echo "Error: autogen.sh failed"
        exit 1
    }
}

termux_step_host_build() {
    cd "${TERMUX_PKG_SRCDIR}" || exit 1
    ./configure --without-pcaudiolib && make
}

termux_step_pre_configure() {
    # Set Android NDK paths for API 28
    export NDK=/home/builder/termux-packages/output/android-ndk-r26d
    export NDK_SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
    export NDK_LIB=$NDK_SYSROOT/usr/lib/aarch64-linux-android/28
    export NDK_BIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin

    # Debug NDK paths
    echo "DEBUG: NDK=$NDK"
    echo "DEBUG: NDK_SYSROOT=$NDK_SYSROOT"
    echo "DEBUG: NDK_LIB=$NDK_LIB"
    echo "DEBUG: NDK_BIN=$NDK_BIN"
    echo "DEBUG: Files in NDK_LIB:"
    ls -l $NDK_LIB

    # Use NDK's clang
    export CC=$NDK_BIN/aarch64-linux-android28-clang
    export CXX=$NDK_BIN/aarch64-linux-android28-clang++

    # Configure flags for static library
    CFLAGS="--target=aarch64-linux-android28 -DANDROID -fPIC -g -Os"
    CXXFLAGS="--target=aarch64-linux-android28 -DANDROID -fPIC -g -Os"
    LDFLAGS="-L${NDK_LIB} -llog -landroid -lc++ -lc"
    export CFLAGS="$CFLAGS"
    export CXXFLAGS="$CXXFLAGS"
    export LDFLAGS="$LDFLAGS"

    # Debug flags
    echo "DEBUG: CC=$CC"
    echo "DEBUG: CXX=$CXX"
    echo "DEBUG: CFLAGS=$CFLAGS"
    echo "DEBUG: CXXFLAGS=$CXXFLAGS"
    echo "DEBUG: LDFLAGS=$LDFLAGS"

    # Check disk space
    echo "DEBUG: Disk space in $TERMUX_PKG_SRCDIR:"
    df -h $TERMUX_PKG_SRCDIR
}

termux_step_make() {
    # Build only the static library
    make -B src/libespeak-ng.la || {
        echo "Error: make failed"
        exit 1
    }
    # Extract libespeak-ng.a from .libs directory
    mv src/.libs/libespeak-ng.a src/libespeak-ng.a || {
        echo "Error: Failed to move libespeak-ng.a"
        exit 1
    }
}

termux_step_make_install() {
    # Install static library and headers
    install -Dm644 src/libespeak-ng.a $TERMUX_PREFIX/lib/libespeak-ng.a || {
        echo "Error: Failed to install libespeak-ng.a"
        exit 1
    }
    install -Dm644 src/include/espeak-ng/*.h $TERMUX_PREFIX/include/espeak-ng/ || {
        echo "Error: Failed to install espeak-ng headers"
        exit 1
    }
    install -Dm644 src/include/espeak/speak_lib.h $TERMUX_PREFIX/include/espeak/speak_lib.h || {
        echo "Error: Failed to install speak_lib.h"
        exit 1
    }
    install -Dm644 espeak-ng.pc $TERMUX_PREFIX/lib/pkgconfig/espeak-ng.pc || {
        echo "Error: Failed to install espeak-ng.pc"
        exit 1
    }
    # Install espeak-ng-data
    rm -rf $TERMUX_PREFIX/share/espeak-ng-data
    mkdir -p $TERMUX_PREFIX/share/espeak-ng-data
    cp -prf espeak-ng-data/* $TERMUX_PREFIX/share/espeak-ng-data || {
        echo "Error: Failed to install espeak-ng-data"
        exit 1
    }
    # Verify installation
    echo "DEBUG: Verifying installed libespeak-ng.a:"
    ls -l $TERMUX_PREFIX/lib/libespeak-ng.a
    echo "DEBUG: Verifying installed speak_lib.h:"
    ls -l $TERMUX_PREFIX/include/espeak/speak_lib.h
    echo "DEBUG: Checking for espeak_TextToPhonemesWithTerminator in libespeak-ng.a:"
    nm $TERMUX_PREFIX/lib/libespeak-ng.a | grep espeak_TextToPhonemesWithTerminator || {
        echo "Error: espeak_TextToPhonemesWithTerminator not found in libespeak-ng.a"
        exit 1
    }
}
