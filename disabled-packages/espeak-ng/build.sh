#!/bin/bash

TERMUX_PKG_HOMEPAGE=https://github.com/OHF-Voice/espeak-ng
TERMUX_PKG_DESCRIPTION="eSpeak NG text-to-speech engine for Piper"
TERMUX_PKG_LICENSE="GPL-3.0-or-later"
TERMUX_PKG_MAINTAINER="@daslearning"
TERMUX_PKG_VERSION=1.52.0
TERMUX_PKG_SRCURL=https://github.com/OHF-Voice/espeak-ng/archive/master.tar.gz
TERMUX_PKG_SHA256=skip
TERMUX_PKG_DEPENDS="libc++"
TERMUX_PKG_BUILD_IN_SRC=true

termux_step_pre_configure() {
    # Set NDK paths for API 28
    export NDK=/home/builder/termux-packages/output/android-ndk-r26d
    export NDK_SYSROOT=$NDK/toolchains/llvm/prebuilt/linux-x86_64/sysroot
    export NDK_LIB=$NDK_SYSROOT/usr/lib/aarch64-linux-android/28
    export NDK_BIN=$NDK/toolchains/llvm/prebuilt/linux-x86_64/bin

    # Install autoconf tools
    apt install autoconf automake libtool -y

    # Run autoconf to generate configure script
    cd $TERMUX_PKG_SRCDIR
    ./autogen.sh
}

termux_step_configure() {
    ./configure \
        --prefix=$TERMUX_PREFIX \
        --host=aarch64-linux-android \
        --disable-static \
        --with-pic \
        CC=$NDK_BIN/aarch64-linux-android28-clang \
        CXX=$NDK_BIN/aarch64-linux-android28-clang++ \
        CFLAGS="-DANDROID -fPIC --target=aarch64-linux-android28 -D_GNU_SOURCE" \
        LDFLAGS="-L${NDK_LIB} -llog -landroid"
}

termux_step_make() {
    make -j$(nproc)
}

termux_step_make_install() {
    make install
}