#!/bin/bash

TERMUX_PKG_HOMEPAGE=https://github.com/OHF-Voice/piper1-gpl
TERMUX_PKG_DESCRIPTION="espeakbridge.so for Piper text-to-speech engine"
TERMUX_PKG_LICENSE="GPL-3.0-or-later"
TERMUX_PKG_MAINTAINER="@daslearning"
TERMUX_PKG_VERSION=1.3.0
TERMUX_PKG_DEPENDS="python, espeakng"
TERMUX_PKG_BUILD_DEPENDS="espeakng"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PYTHON_VERSION=3.11
TERMUX_PREFIX=/data/data/com.termux/files/usr

termux_step_pre_configure() {
    # Set up build tools
    termux_setup_cmake

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

    # Verify library architectures
    echo "DEBUG: Checking library architectures:"
    file $NDK_LIB/liblog.so
    file $NDK_LIB/libandroid.so
    file $TERMUX_PREFIX/lib/libpython3.11.so
    file $TERMUX_PREFIX/lib/libespeak-ng.a

    # Copy espeakbridge.c and speak_lib.h to TERMUX_PKG_SRCDIR
    PACKAGE_DIR="$HOME/termux-packages/packages/espeakbridge"
    echo "DEBUG: Copying files from $PACKAGE_DIR to $TERMUX_PKG_SRCDIR"
    cp "$PACKAGE_DIR/espeakbridge.c" "$TERMUX_PKG_SRCDIR/" || {
        echo "Error: Failed to copy espeakbridge.c from $PACKAGE_DIR"
        exit 1
    }
    cp "$TERMUX_PREFIX/include/espeak-ng/speak_lib.h" "$TERMUX_PKG_SRCDIR/" || {
        echo "Error: Failed to copy speak_lib.h from $TERMUX_PREFIX/include/espeak-ng"
        exit 1
    }

    # Compiler and linker flags for Android
    CPPFLAGS="-DANDROID -I${TERMUX_PKG_SRCDIR} -I${NDK_SYSROOT}/usr/include -I${TERMUX_PREFIX}/include/python${TERMUX_PYTHON_VERSION} -I${TERMUX_PREFIX}/include/espeak-ng"
    CFLAGS="-Wno-unused-variable -fPIC --target=aarch64-linux-android28 -D_GNU_SOURCE"
    LDFLAGS="-L${NDK_LIB} -llog -landroid -L${TERMUX_PREFIX}/lib -lpython${TERMUX_PYTHON_VERSION} $TERMUX_PREFIX/lib/libespeak-ng.a -lc -Wl,--verbose"
    export CFLAGS="$CFLAGS $CPPFLAGS"
    export LDFLAGS="$LDFLAGS"

    # Use NDK's clang
    export CC=$NDK_BIN/aarch64-linux-android28-clang
    export CXX=$NDK_BIN/aarch64-linux-android28-clang++

    # Python paths
    export PYTHON_VERSION="${TERMUX_PYTHON_VERSION}"
    export PYTHON_EXECUTABLE=$TERMUX_PREFIX/bin/python3.11
    export PYTHON_INCLUDE_DIR=$TERMUX_PREFIX/include/python${TERMUX_PYTHON_VERSION}
    export PYTHON_LIBRARY=$TERMUX_PREFIX/lib/libpython${TERMUX_PYTHON_VERSION}.so

    # Debug paths
    echo "DEBUG: CC=$CC"
    echo "DEBUG: CXX=$CXX"
    echo "DEBUG: PYTHON_EXECUTABLE=$PYTHON_EXECUTABLE"
    echo "DEBUG: PYTHON_INCLUDE_DIR=$PYTHON_INCLUDE_DIR"
    echo "DEBUG: PYTHON_LIBRARY=$PYTHON_LIBRARY"
    echo "DEBUG: TERMUX_PKG_SRCDIR=$TERMUX_PKG_SRCDIR"
    echo "DEBUG: Files in TERMUX_PKG_SRCDIR:"
    ls -l $TERMUX_PKG_SRCDIR

    # Verify Python development files
    if [ ! -f "$PYTHON_INCLUDE_DIR/pyconfig.h" ]; then
        echo "Error: pyconfig.h not found in $PYTHON_INCLUDE_DIR"
        exit 1
    fi
    if [ ! -f "$PYTHON_LIBRARY" ]; then
        echo "Error: libpython${PYTHON_VERSION}.so not found in $TERMUX_PREFIX/lib"
        exit 1
    fi

    # Verify espeak-ng
    if [ ! -f "${TERMUX_PKG_SRCDIR}/speak_lib.h" ]; then
        echo "Error: speak_lib.h not found in $TERMUX_PKG_SRCDIR"
        exit 1
    fi
    if [ ! -f "$TERMUX_PREFIX/lib/libespeak-ng.a" ]; then
        echo "Error: libespeak-ng.a not found in $TERMUX_PREFIX/lib"
        exit 1
    fi

    # Check for espeak_TextToPhonemesWithTerminator
    echo "DEBUG: Checking for espeak_TextToPhonemesWithTerminator in libespeak-ng.a:"
    nm $TERMUX_PREFIX/lib/libespeak-ng.a | grep espeak_TextToPhonemesWithTerminator || {
        echo "Error: espeak_TextToPhonemesWithTerminator not found in libespeak-ng.a"
        exit 1
    }

    # Check for stderr in libespeak-ng.a
    echo "DEBUG: Checking for stderr in libespeak-ng.a:"
    nm $TERMUX_PREFIX/lib/libespeak-ng.a | grep stderr || echo "No stderr references found in libespeak-ng.a"

    # Hardcode Python compiler and linker flags for aarch64
    PYTHON_CFLAGS="-I${TERMUX_PREFIX}/include/python3.11 -DANDROID -D_GNU_SOURCE -fno-strict-aliasing -DNDEBUG -g -fwrapv -O2 -Wall"
    PYTHON_LDFLAGS="-L${TERMUX_PREFIX}/lib -lpython3.11 -ldl -lm -lc"
    export CFLAGS="$CFLAGS $PYTHON_CFLAGS"
    export LDFLAGS="$LDFLAGS $PYTHON_LDFLAGS"

    # Debug final CFLAGS and LDFLAGS
    echo "DEBUG: Final CFLAGS=$CFLAGS"
    echo "DEBUG: Final LDFLAGS=$LDFLAGS"

    # Check disk space
    echo "DEBUG: Disk space in $TERMUX_PKG_SRCDIR:"
    df -h $TERMUX_PKG_SRCDIR
}

termux_step_make() {
    # Compile espeakbridge.c to espeakbridge.so
    echo "DEBUG: Compiling with command: $CC $CFLAGS -c ${TERMUX_PKG_SRCDIR}/espeakbridge.c -o espeakbridge.o"
    $CC $CFLAGS -c ${TERMUX_PKG_SRCDIR}/espeakbridge.c -o espeakbridge.o || {
        echo "Error: Compilation failed"
        exit 1
    }
    echo "DEBUG: Checking for espeakbridge.o:"
    ls -l espeakbridge.o
    echo "DEBUG: Linking with command: $CC -shared $LDFLAGS espeakbridge.o -o espeakbridge.so"
    $CC -shared $LDFLAGS espeakbridge.o -o espeakbridge.so 2> linker_errors.log || {
        echo "Error: Linking failed, see linker_errors.log"
        cat linker_errors.log
        exit 1
    }
    echo "DEBUG: Checking for espeakbridge.so:"
    ls -l espeakbridge.so
}

termux_step_make_install() {
    # Install espeakbridge.so
    echo "DEBUG: Installing espeakbridge.so to $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/"
    mkdir -p $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper
    cp espeakbridge.so $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/ || {
        echo "Error: Failed to copy espeakbridge.so to $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/"
        exit 1
    }
    echo "DEBUG: Verifying installed espeakbridge.so:"
    ls -l $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/espeakbridge.so
}
