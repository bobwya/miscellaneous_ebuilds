# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6

inherit flag-o-matic libtool multilib multilib-build multilib-minimal toolchain-funcs
FREETYPE_INFINALITY_COMMIT="87ff487b4d724a739185907390e0ededdb1c4ee8"
FREETYPE_INFINALITY_BASE="freetype-infinality-${FREETYPE_INFINALITY_COMMIT}"
FREETYPE_INFINALITY_URL="https://github.com/bobwya/freetype-infinality/archive"
DESCRIPTION="A high-quality and portable font engine"
HOMEPAGE="https://www.freetype.org/"
IUSE="X +adobe-cff bindist bzip2 -cleartype_hinting debug doc fontforge harfbuzz +infinality png static-libs utils"

if [[ "${PV}" != 9999 ]]; then
	MY_PV="${PV}"
	SRC_URI="
		mirror://sourceforge/freetype/${P/_/}.tar.bz2
		mirror://nongnu/freetype/${P/_/}.tar.bz2
		doc? (
			mirror://sourceforge/freetype/${PN}-doc-${PV}.tar.bz2
			mirror://nongnu/freetype/${PN}-doc-${PV}.tar.bz2
		)
		infinality? (
			${FREETYPE_INFINALITY_URL}/${FREETYPE_INFINALITY_COMMIT}.tar.gz -> ${FREETYPE_INFINALITY_BASE}.tar.gz
		)
		utils? (
			mirror://sourceforge/freetype/ft2demos-${PV}.tar.bz2
			mirror://nongnu/freetype/ft2demos-${PV}.tar.bz2
		)
	"
	KEYWORDS="alpha amd64 arm arm64 hppa ia64 ~m68k ~mips ppc ppc64 ~s390 ~sh sparc x86 ~ppc-aix ~x64-cygwin ~amd64-fbsd ~x86-fbsd ~amd64-linux ~arm-linux ~x86-linux ~ppc-macos ~x64-macos ~x86-macos ~m68k-mint ~sparc-solaris ~sparc64-solaris ~x64-solaris ~x86-solaris ~x86-winnt"
	IUSE+=" doc"
else
	MY_PV="2.9.1"
	inherit autotools git-r3
fi

MY_P="${PN}-${MY_PV}"

LICENSE="|| ( FTL GPL-2+ )"
SLOT="2"
RESTRICT="!bindist? ( bindist )" # bug 541408

RDEPEND="
	>=sys-libs/zlib-1.2.8-r1[${MULTILIB_USEDEP}]
	bzip2? ( >=app-arch/bzip2-1.0.6-r4[${MULTILIB_USEDEP}] )
	harfbuzz? ( >=media-libs/harfbuzz-0.9.19[truetype,${MULTILIB_USEDEP}] )
	png? ( >=media-libs/libpng-1.2.51:=[${MULTILIB_USEDEP}] )
	utils? (
		X? (
			>=x11-libs/libX11-1.6.2[${MULTILIB_USEDEP}]
			>=x11-libs/libXau-1.0.7-r1[${MULTILIB_USEDEP}]
			>=x11-libs/libXdmcp-1.1.1-r1[${MULTILIB_USEDEP}]
		)
	)
"
DEPEND="${RDEPEND}
	virtual/pkgconfig"
PDEPEND="infinality? ( media-libs/fontconfig-infinality )"

PATCHES=(
	"${FILESDIR}/${PN}-2.4.11-sizeof-types.patch" # 459966
	"${FILESDIR}/${PN}-2.7-enable-valid.patch"
)

_egit_repo_handler() {
	local phase="${1}"
	case ${phase} in
		fetch|unpack)
			# shellcheck disable=SC2104
			break
		;;
		*)
			die "Please use this function with either \"fetch\" or \"unpack\""
		;;
	esac

	local EGIT_REPO_URI
	EGIT_REPO_URI="https://git.savannah.gnu.org/r/freetype/freetype2.git"
	"git-r3_src_${phase}"
	if use utils ; then
		EGIT_REPO_URI="https://git.savannah.gnu.org/r/freetype/freetype2-demos.git"
		local EGIT_CHECKOUT_DIR="${WORKDIR}/ft2demos-${PV}"
		"git-r3_src_${phase}"
	fi
}

src_prepare() {
	[[ "${PV}" == 9999 ]] && _git_autogen_fix

	enable_option() {
		sed -i -e "/#define ${1}/ { s:/\\* ::; s: \\*/:: }" \
			"include/${PN}/config/ftoption.h" \
			|| die "unable to enable option ${1}"
	}

	disable_option() {
		sed -i -e "/#define ${1}/ { s:^:/* :; s:$: */: }" \
			"include/${PN}/config/ftoption.h" \
			|| die "unable to disable option ${1}"
	}

	if use infinality; then
		local ipatch

		for ipatch in $(seq -w 0001 0024); do
			PATCHES+=( "${WORKDIR}/${FREETYPE_INFINALITY_BASE}/${MY_PV}/${MY_P}-${ipatch}-infinality-ultimate"*".patch" )
		done
	fi

	default

	# Will be the new default for >=freetype-2.7.0
	disable_option "TT_CONFIG_OPTION_SUBPIXEL_HINTING  2"
	if use infinality && use cleartype_hinting; then
		enable_option "TT_CONFIG_OPTION_SUBPIXEL_HINTING  ( 1 | 2 )"
	elif use infinality; then
		enable_option "TT_CONFIG_OPTION_SUBPIXEL_HINTING  1"
	elif use cleartype_hinting; then
		enable_option "TT_CONFIG_OPTION_SUBPIXEL_HINTING  2"
	fi

	# Can be disabled with FREETYPE_PROPERTIES="pcf:no-long-family-names=1"
	# via environment (new since v2.8)
	enable_option PCF_CONFIG_OPTION_LONG_FAMILY_NAMES

	if ! use bindist; then
		# See http://freetype.org/patents.html
		# ClearType is covered by several Microsoft patents in the US
		enable_option FT_CONFIG_OPTION_SUBPIXEL_RENDERING
	fi

	if ! use adobe-cff; then
		enable_option CFF_CONFIG_OPTION_OLD_ENGINE
	fi

	if use debug; then
		enable_option FT_DEBUG_LEVEL_TRACE
		enable_option FT_DEBUG_MEMORY
	fi

	if use utils; then
		cd "${WORKDIR}/ft2demos-${PV}" || die
		# Disable tests needing X11 when USE="-X". (bug #177597)
		if ! use X; then
			sed -i -e "/EXES[ ]+=[ ]ftdiff/ s:^:#:" Makefile \
				|| die "sed failed"
		fi
		cd "${S}" || die "cd failed"
	fi

	# we are using an alternative shell to run configure
	if [[ -n ${CONFIG_SHELL} ]] ; then
		sed -i -e "1s:^#![[:space:]]*/bin/sh:#!$CONFIG_SHELL:" \
			"${S}/builds/unix/configure" \
			|| die "sed failed"
	fi

	elibtoolize --patch-only
}

multilib_src_configure() {
	append-flags -fno-strict-aliasing
	type -P gmake &> /dev/null && export GNUMAKE=gmake
	local -a myeconfargs=(
		"--enable-biarch-config"
		"--enable-shared"
		"$(use_with bzip2)"
		"$(use_with harfbuzz)"
		"$(use_with png)"
		"$(use_enable static-libs static)"

		# avoid using libpng-config
		"LIBPNG_CFLAGS=$($(tc-getPKG_CONFIG) --cflags libpng)"
		"LIBPNG_LDFLAGS=$($(tc-getPKG_CONFIG) --libs libpng)"
	)
	ECONF_SOURCE="${S}" econf "${myeconfargs[@]}"
}

multilib_src_compile() {
	default

	if multilib_is_native_abi && use utils; then
		einfo "Building utils"
		local -a myemakeargs=(
			"X11_PATH=${EPREFIX}/usr/$(get_libdir)"
			"FT2DEMOS=1"
			"TOP_DIR_2=${WORKDIR}/ft2demos-${PV}"
		)
		# shellcheck disable=SC2068
		emake ${myemakeargs[@]}
	fi
}

multilib_src_install() {
	default

	if multilib_is_native_abi && use utils; then
		einfo "Installing utils"
		rm "${WORKDIR}/ft2demos-${PV}/bin/README" || die "rm failed"
		local ft2demo

		dodir "/usr/bin" #654780
		while IFS= read -r -d '' ft2demo; do
			./libtool --mode=install "$(type -P install)" -m 755 "$ft2demo" \
				"${ED%/}/usr/bin" || die "libtool failed"
		done < <(find ../"ft2demos-${PV}/bin/" -type f -maxdepth 1 -printf '%p\0' 2>/dev/null)
	fi
}

multilib_src_install_all() {
	if use fontforge; then
		einfo "Installing internal headers required for fontforge"
		local fontforge_dir header
		while IFS= read -r -d '' header; do
			fontforge_dir="usr/include/freetype2/internal4fontforge/$(dirname "${header}")"
			mkdir -p "${ED%/}/${fontforge_dir}/$(dirname "${header}")" || die "mkdir failed"
			cp "${header}" "${ED%/}/${fontforge_dir}/$(dirname "${header}")" || die "cp failed"
		done < <(find "src/truetype" "include/freetype/internal" -name '*.h' -printf '%p\0' 2>/dev/null)
	fi

	if [[ "${PV}" != 9999 ]] && use doc; then
		docinto html
		dodoc -r docs/*
	fi

	find "${ED}" -name '*.la' -delete || die "find failed"
	if ! use static-libs; then
		find "${ED}" -name '*.a' -delete || die "find failed"
	fi
}
