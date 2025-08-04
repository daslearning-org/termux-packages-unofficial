TERMUX_PKG_HOMEPAGE=https://github.com/espeak-ng/espeak-ng
TERMUX_PKG_DESCRIPTION="Compact software speech synthesizer"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="@termux"
# Use eSpeak NG as the original eSpeak project is dead.
_COMMIT=a4ca101c99de35345f89df58195b2159748b7092
TERMUX_PKG_VERSION=0.0.0-${_COMMIT:0:7}
TERMUX_PKG_SRCURL=https://github.com/espeak-ng/espeak-ng/archive/${_COMMIT}.tar.gz
TERMUX_PKG_SHA256=c8ed6647d2ebba13015f397eede400262ec02710856d6d08d5a27528765d0be0
TERMUX_PKG_AUTO_UPDATE=false
TERMUX_PKG_DEPENDS="libc++, pcaudiolib"
TERMUX_PKG_BREAKS="espeak-dev"
TERMUX_PKG_REPLACES="espeak-dev"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_HOSTBUILD=true
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="--with-async --with-pcaudiolib"
TERMUX_PREFIX=/data/data/com.termux/files/usr

termux_step_post_get_source() {
	# Certain packages are not safe to build on device because their
	# build.sh script deletes specific files in $TERMUX_PREFIX.
	if ${TERMUX_ON_DEVICE_BUILD}; then
		termux_error_exit "Package '${TERMUX_PKG_NAME}' is not safe for on-device builds."
	fi

	# Do not forget to bump revision of reverse dependencies and rebuild them
	# after SOVERSION is changed.
	local _SOVERSION=1

	local e=$(sed -En 's/^SHARED_VERSION="?([0-9]+):([0-9]+):([0-9]+).*/\1-\3/p' \
				Makefile.am)
	if [ ! "${e}" ] || [ "${_SOVERSION}" != "$(( "${e}" ))" ]; then
		termux_error_exit "SOVERSION guard check failed."
	fi

	./autogen.sh
}

termux_step_host_build() {
	cd "${TERMUX_PKG_SRCDIR}" || exit 1
	./configure && make
	# Man pages require the ronn ruby program.
	#make src/espeak-ng.1
	#cp src/espeak-ng.1 $TERMUX_PREFIX/share/man/man1
	#(cd $TERMUX_PREFIX/share/man/man1 && ln -s -f espeak-ng.1 espeak.1)
}

termux_step_make() {
	make -B src/{e,}speak-ng
}

termux_step_pre_configure() {
	# Oz flag causes problems. See https://github.com/termux/termux-packages/issues/1680:
	CFLAGS=${CFLAGS/-Oz/-Os}

	# ld.lld: error: non-exported symbol '__umoddi3' in arm and i686
	local _libgcc_file="$($CC -print-libgcc-file-name)"
	local _libgcc_path="$(dirname $_libgcc_file)"
	local _libgcc_name="$(basename $_libgcc_file)"
	LDFLAGS+=" -L$_libgcc_path -l:$_libgcc_name"
}

termux_step_make_install() {
	# Calling make install directly tends to build lang data files again but with cross compiled espeak-ng.
	# So use make install-data which will install the data files compiled with previously built espeak-ng
	# in host build step.
	make install-data install-exec
}
