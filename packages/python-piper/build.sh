#!/bin/bash

TERMUX_PKG_HOMEPAGE=https://github.com/OHF-Voice/piper1-gpl
TERMUX_PKG_DESCRIPTION="A fast, local neural text-to-speech engine"
TERMUX_PKG_LICENSE="GPL-3.0-or-later"
TERMUX_PKG_MAINTAINER="@daslearning"
TERMUX_PKG_VERSION=1.3.0
TERMUX_PREFIX="/data/data/com.termux/files/usr"
TERMUX_PKG_SRCURL=https://github.com/OHF-Voice/piper1-gpl/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=b27e318dcbbab8563187da0ef00d443e51f4f6462782befbed54c42539aa41ec
TERMUX_PKG_DEPENDS="python"
TERMUX_PKG_BUILD_DEPENDS="cmake, ninja, python-onnxruntime"
TERMUX_PKG_PYTHON_COMMON_DEPS="packaging, onnxruntime, scikit-build, cmake, ninja"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_AUTO_UPDATE=true
TERMUX_PKG_UPDATE_TAG_TYPE="latest-release-tag"
TERMUX_PYTHON_VERSION=3.11

termux_step_pre_configure() {
    # Set up build tools
    termux_setup_cmake
    termux_setup_ninja

    # Compiler and linker flags for Android
    CPPFLAGS+=" -Wno-unused-variable -DANDROID"
    LDFLAGS+=" -llog -landroid"
    export CFLAGS="$CPPFLAGS"
    export LDFLAGS="$LDFLAGS"

    # Python paths
    export PYTHON_VERSION="${TERMUX_PYTHON_VERSION}"
    export PYTHON_EXECUTABLE=$(command -v python3.11 || command -v python3)
    export PYTHON_INCLUDE_DIR=$TERMUX_PREFIX/include/python${PYTHON_VERSION}
    export PYTHON_LIBRARY=$TERMUX_PREFIX/lib/libpython${PYTHON_VERSION}.so
    export PYTHON_NUMPY_INCLUDE_DIR=$TERMUX_PREFIX/lib/python${PYTHON_VERSION}/site-packages/numpy/_core/include

    # Ensure Python 3.11 is used
    if ! [[ $($PYTHON_EXECUTABLE --version) =~ 3\.11 ]]; then
        echo "Error: Python 3.11 is required, but $($PYTHON_EXECUTABLE --version) is found."
        exit 1
    fi

    # CMake arguments for scikit-build
    export CMAKE_ARGS=""
    CMAKE_ARGS+=" -DPython_EXECUTABLE=${PYTHON_EXECUTABLE}"
    CMAKE_ARGS+=" -DPython_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}"
    CMAKE_ARGS+=" -DPython_LIBRARY=${PYTHON_LIBRARY}"
    CMAKE_ARGS+=" -DPython3_EXECUTABLE=${PYTHON_EXECUTABLE}"
    CMAKE_ARGS+=" -DPython3_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}"
    CMAKE_ARGS+=" -DPython3_LIBRARY=${PYTHON_LIBRARY}"
    CMAKE_ARGS+=" -DESPEAKNG_INCLUDE_DIR=${TERMUX_PREFIX}/include/espeak-ng"
    CMAKE_ARGS+=" -DESPEAKNG_LIBRARY=${TERMUX_PREFIX}/lib/libespeak-ng.so"
    CMAKE_ARGS+=" -DONNXRUNTIME_DIR=${TERMUX_PREFIX}"
    CMAKE_ARGS+=" -DBUILD_SHARED_LIBS=ON"
    CMAKE_ARGS+=" -DCMAKE_SYSTEM_NAME=Android"
    CMAKE_ARGS+=" -DCMAKE_SYSTEM_VERSION=${TERMUX_PKG_API_LEVEL:-24}"
    CMAKE_ARGS+=" -DCMAKE_BUILD_TYPE=Release"
    CMAKE_ARGS+=" -DCMAKE_INSTALL_PREFIX=$TERMUX_PREFIX"
}

termux_step_make() {
    # Build using scikit-build with CMAKE_ARGS
    python setup.py build \
        --build-type Release
}

termux_step_make_install() {
    # Install Python package
    pip install --no-deps --prefix="$TERMUX_PREFIX" .

    # Ensure espeakbridge.so is installed
    mkdir -p $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper
    cp build/lib*/piper/espeakbridge*.so $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/ 2>/dev/null || true
}

termux_step_post_massage() {
    # Install package data
    mkdir -p $TERMUX_PREFIX/share/espeak-ng-data
    mkdir -p $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/tashkeel
    cp -r src/piper/espeak-ng-data/* $TERMUX_PREFIX/share/espeak-ng-data/ 2>/dev/null || true
    cp -r src/piper/tashkeel/* $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/tashkeel/ 2>/dev/null || true
}