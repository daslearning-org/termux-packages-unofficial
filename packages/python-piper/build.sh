#!/bin/bash

TERMUX_PKG_HOMEPAGE=https://github.com/OHF-Voice/piper1-gpl
TERMUX_PKG_DESCRIPTION="A fast, local neural text-to-speech engine"
TERMUX_PKG_LICENSE="GPL-3.0-or-later"
TERMUX_PKG_MAINTAINER="@daslearning"
TERMUX_PKG_VERSION=1.3.0
TERMUX_PKG_SRCURL=https://github.com/OHF-Voice/piper1-gpl/archive/refs/tags/v${TERMUX_PKG_VERSION}.tar.gz
TERMUX_PKG_SHA256=b27e318dcbbab8563187da0ef00d443e51f4f6462782befbed54c42539aa41ec
TERMUX_PKG_DEPENDS="espeak-ng"
TERMUX_PKG_BUILD_DEPENDS="python-onnxruntime"
TERMUX_PKG_PYTHON_COMMON_DEPS="packaging, scikit-build, cmake, ninja"
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
    export PYTHON_EXECUTABLE=$(command -v python3)
    export PYTHON_INCLUDE_DIR=$TERMUX_PREFIX/include/python${PYTHON_VERSION}
    export PYTHON_LIBRARY=$TERMUX_PREFIX/lib/libpython${PYTHON_VERSION}.so
    export PYTHON_NUMPY_INCLUDE_DIR=$TERMUX_PREFIX/lib/python${PYTHON_VERSION}/site-packages/numpy/_core/include

    # CMake arguments for Python, espeak-ng, and onnxruntime
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS=""
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPython_EXECUTABLE=${PYTHON_EXECUTABLE}"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPython_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPython_LIBRARY=${PYTHON_LIBRARY}"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPython3_EXECUTABLE=${PYTHON_EXECUTABLE}"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPython3_INCLUDE_DIR=${PYTHON_INCLUDE_DIR}"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPython3_LIBRARY=${PYTHON_LIBRARY}"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DESPEAKNG_INCLUDE_DIR=${TERMUX_PREFIX}/include/espeak-ng"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DESPEAKNG_LIBRARY=${TERMUX_PREFIX}/lib/libespeak-ng.so"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DONNXRUNTIME_DIR=${TERMUX_PREFIX}"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DBUILD_SHARED_LIBS=ON"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DCMAKE_SYSTEM_NAME=Android"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DCMAKE_SYSTEM_VERSION=${TERMUX_PKG_API_LEVEL:-21}"
}

termux_step_make() {
    # Build using scikit-build
    python setup.py build \
        --build-type Release \
        --cmake-args \
        "${TERMUX_PKG_EXTRA_CONFIGURE_ARGS} -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$TERMUX_PREFIX"
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