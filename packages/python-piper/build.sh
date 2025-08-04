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

TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
-DCMAKE_POLICY_VERSION_MINIMUM=3.5
-Dpiper_ENABLE_PYTHON=ON
-Dpiper_BUILD_SHARED_LIB=OFF
-DPYBIND11_USE_CROSSCOMPILING=TRUE
-Dpiper_USE_NNAPI_BUILTIN=ON
-Dpiper_USE_XNNPACK=ON
"

termux_step_pre_configure() {
    # Set up build tools
    termux_setup_cmake
    termux_setup_ninja

    # Compiler and linker flags for Android
    CPPFLAGS+=" -Wno-unused-variable -DANDROID"
    LDFLAGS+=" -llog -landroid"
    export CFLAGS="$CPPFLAGS"
    export LDFLAGS="$LDFLAGS"

    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPYTHON_EXECUTABLE=$(command -v python3)"
	TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DONNX_CUSTOM_PROTOC_EXECUTABLE=$(command -v protoc)"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DPython_NumPy_INCLUDE_DIR=$TERMUX_PREFIX/lib/python$TERMUX_PYTHON_VERSION/site-packages/numpy/_core/include"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DESPEAKNG_INCLUDE_DIR=${TERMUX_PREFIX}/include/espeak-ng"
    TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DESPEAKNG_LIBRARY=${TERMUX_PREFIX}/lib/libespeak-ng.so"
    # TERMUX_PKG_EXTRA_CONFIGURE_ARGS+=" -DONNXRUNTIME_DIR=${TERMUX_PREFIX}"

	local TERMUX_PKG_SRCDIR_SAVE="$TERMUX_PKG_SRCDIR"
	TERMUX_PKG_SRCDIR+="/cmake"
	termux_step_configure_cmake
	TERMUX_PKG_SRCDIR="$TERMUX_PKG_SRCDIR_SAVE"
    cmake --build .
}

termux_step_make() {
    # Build using scikit-build with CMAKE_ARGS
    python -m build --wheel --no-isolatio
}

termux_step_make_install() {
    # Install Python package
    pip install --no-deps --prefix="$TERMUX_PREFIX" .

    local _pyver="${TERMUX_PYTHON_VERSION//./}"
	local _wheel="piper-${TERMUX_PKG_VERSION}-cp${_pyver}-cp${_pyver}-linux_${TERMUX_ARCH}.whl"
	pip install --no-deps --prefix="$TERMUX_PREFIX" "$TERMUX_PKG_SRCDIR/dist/${_wheel}"
    cp build/lib*/piper/espeakbridge*.so $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/ 2>/dev/null || true
}

termux_step_post_massage() {
    # Install package data
    mkdir -p $TERMUX_PREFIX/share/espeak-ng-data
    mkdir -p $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/tashkeel
    cp -r src/piper/espeak-ng-data/* $TERMUX_PREFIX/share/espeak-ng-data/ 2>/dev/null || true
    cp -r src/piper/tashkeel/* $TERMUX_PREFIX/lib/python${TERMUX_PYTHON_VERSION}/site-packages/piper/tashkeel/ 2>/dev/null || true
}
