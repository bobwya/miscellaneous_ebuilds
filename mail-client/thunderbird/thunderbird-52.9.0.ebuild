# Copyright 1999-2018 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# shellcheck disable=SC2034
EAPI=6
WANT_AUTOCONF="2.1"
MOZ_ESR=""
MOZ_LIGHTNING_VER="5.4.9"
MOZ_LIGHTNING_GDATA_VER="3.3"

# This list can be updated using scripts/get_langs.sh from the mozilla overlay
MOZ_LANGS=("ar" "ast" "be" "bg" "bn-BD" "br" "ca" "cs" "cy" "da" "de" "el" "en" "en-GB" "en-US" "es-AR"
"es-ES" "et" "eu" "fi" "fr" "fy-NL" "ga-IE" "gd" "gl" "he" "hr" "hsb" "hu" "hy-AM" "id" "is" "it" "ja" "ko" "lt"
"nb-NO" "nl" "nn-NO" "pa-IN" "pl" "pt-BR" "pt-PT" "rm" "ro" "ru" "si" "sk" "sl" "sq" "sr" "sv-SE" "ta-LK" "tr"
"uk" "vi" "zh-CN" "zh-TW" )

# Convert the ebuild version to the upstream mozilla version, used by mozlinguas
MOZ_PV="${PV/_beta/b}"

# Patches
PATCHFF="firefox-52.5-patches-02"

MOZ_HTTP_URI="https://archive.mozilla.org/pub/${PN}/releases"

# Mercurial repository for Mozilla Firefox patches to provide better KDE Integration (developed by Wolfgang Rosenauer for OpenSUSE)
EHG_REPO_URI="https://www.rosenauer.org/hg/mozilla"

# ESR releases have slightly version numbers
if [[ ${MOZ_ESR} == 1 ]]; then
	MOZ_PV="${MOZ_PV}esr"
fi
MOZ_P="${PN}-${MOZ_PV}"

MOZCONFIG_OPTIONAL_GTK2ONLY=1
MOZCONFIG_OPTIONAL_WIFI=1

inherit flag-o-matic toolchain-funcs mozconfig-v6.52 autotools pax-utils check-reqs nsplugins mozlinguas-v2 xdg-utils gnome2-utils mercurial

DESCRIPTION="Thunderbird Mail Client, with SUSE patchset, to provide better KDE integration"
HOMEPAGE="https://www.mozilla.com/en-US/thunderbird
	https://www.rosenauer.org/hg/mozilla"

KEYWORDS="~alpha ~amd64 ~arm ~ppc ~ppc64 ~x86 ~x86-fbsd ~amd64-linux ~x86-linux"
SLOT="0"
LICENSE="MPL-2.0 GPL-2 LGPL-2.1"
IUSE="bindist crypt hardened kde ldap kernel_linux lightning +minimal mozdom rust selinux"
REQUIRED_USE="kde? ( || ( amd64 x86 ) )"
RESTRICT="!bindist? ( bindist )"

# shellcheck disable=SC2206
PATCH_URIS=( https://dev.gentoo.org/~{anarchy,axs,polynomial-c}/mozilla/patchsets/${PATCHFF}.tar.xz )
# shellcheck disable=SC2124
SRC_URI="${SRC_URI}
	${MOZ_HTTP_URI}/${MOZ_PV}/source/${MOZ_P}.source.tar.xz
	https://dev.gentoo.org/~axs/distfiles/lightning-${MOZ_LIGHTNING_VER}.tar.xz
	lightning? ( https://dev.gentoo.org/~axs/distfiles/gdata-provider-${MOZ_LIGHTNING_GDATA_VER}.tar.xz )
	${PATCH_URIS[@]}"

ASM_DEPEND=">=dev-lang/yasm-1.1"

CDEPEND="
	>=dev-libs/nss-3.28.3
	>=dev-libs/nspr-4.13.1
	"

DEPEND="rust? ( dev-lang/rust )
	amd64? ( ${ASM_DEPEND}
		virtual/opengl )
	x86? ( ${ASM_DEPEND}
		virtual/opengl )"

RDEPEND="${CDEPEND}
	selinux? ( sec-policy/selinux-thunderbird )
	crypt? ( >=x11-plugins/enigmail-2.0.5 )
	kde? ( kde-misc/kmozillahelper:= )"
S="${WORKDIR}/${MOZ_P}"

BUILD_OBJ_DIR="${S}/tbird"

pkg_setup() {
	moz_pkgsetup

	export MOZILLA_DIR="${S}/mozilla"

	if ! use bindist; then
		elog "You are enabling official branding. You may not redistribute this build"
		elog "to any users on your network or the internet. Doing so puts yourself into"
		elog "a legal problem with Mozilla Foundation"
		elog "You can disable it by emerging ${PN} _with_ the bindist USE-flag"
		elog
	fi
}

pkg_pretend() {
	# Ensure we have enough disk space to compile
	CHECKREQS_DISK_BUILD="4G"
	check-reqs_pkg_setup
}

src_unpack() {
	default

	# Unpack language packs
	mozlinguas_src_unpack
	if use kde; then
		if [[ ${MOZ_PV} =~ ^\(10|17|24\)\..*esr$ ]]; then
			EHG_REVISION="esr${MOZ_PV%%.*}"
		else
			EHG_REVISION="firefox${MOZ_PV%%.*}"
		fi
		KDE_PATCHSET="firefox-kde-patchset"
		EHG_CHECKOUT_DIR="${WORKDIR}/${KDE_PATCHSET}"
		mercurial_fetch "${EHG_REPO_URI}" "${KDE_PATCHSET}"
	fi

	# this version of lightning is a .tar.xz, no xpi needed
	#xpi_unpack lightning-${MOZ_LIGHTNING_VER}.xpi

	# this version of gdata-provider is a .tar.xz , no xpi needed
	#use lightning && xpi_unpack gdata-provider-${MOZ_LIGHTNING_GDATA_VER}.xpi
}

src_prepare() {
	local -a PATCHES
	PATCHES+=( "${FILESDIR}/1000_fix_gentoo_preferences.patch" )

	rm -f "${WORKDIR}/firefox/2007_fix_nvidia_latest.patch" || die "rm failed"
	pushd "${S}/mozilla" &>/dev/null || die "pushd failed"
	if use kde; then
		# Gecko/toolkit OpenSUSE KDE integration patchset
		eapply "${EHG_CHECKOUT_DIR}/mozilla-kde.patch"
		eapply "${EHG_CHECKOUT_DIR}/mozilla-nongnome-proxies.patch"
		# Uncomment the next line to enable KDE support debugging (additional console output)...
		#PATCHES+=( "${FILESDIR}/${PN}-kde-debug.patch" )
		# Uncomment the following patch line to force Plasma/Qt file dialog for Thunderbird...
		#PATCHES+=( "${FILESDIR}/${PN}-force-qt-dialog.patch" )
		# ... _OR_ install the patch file as a User patch (/etc/portage/patches/mail-client/thunderbird/)
	fi
	# Apply our patchset from firefox to thunderbird as well
	eapply "${WORKDIR}/firefox"
	popd &>/dev/null || die "popd failed"

	# Ensure that are plugins dir is enabled as default
	sed -i -e "s:/usr/lib/mozilla/plugins:/usr/lib/nsbrowser/plugins:" \
		"${S}/mozilla/xpcom/io/nsAppFileLocationProvider.cpp" || die "sed failed to replace plugin path for 32bit!"
	sed -i -e "s:/usr/lib64/mozilla/plugins:/usr/lib64/nsbrowser/plugins:" \
		"${S}/mozilla/xpcom/io/nsAppFileLocationProvider.cpp" || die "sed failed to replace plugin path for 64bit!"

	# Don't exit with error when some libs are missing which we have in
	# system.
	sed '/^MOZ_PKG_FATAL_WARNINGS/s@= 1@= 0@' \
		-i "${S}/mail/installer/Makefile.in" || die "sed failed"

	# Don't error out when there's no files to be removed:
	sed 's@\(xargs rm\)$@\1 -f@' \
		-i "${S}/mozilla/toolkit/mozapps/installer/packager.mk" || die "sed failed"

	# Shell scripts sometimes contain DOS line endings; bug 391889
	grep -rlZ --include="*.sh" $'\r$' . |
	while read -r -d $'\0' file ; do
		einfo edos2unix "${file}"
		edos2unix "${file}"
	done

	default

	# Confirm the version of lightning being grabbed for langpacks is the same
	# as that used in thunderbird
	local THIS_MOZ_LIGHTNING_VER
	THIS_MOZ_LIGHTNING_VER=$(python "${S}/calendar/lightning/build/makeversion.py" "${PV}")
	if [[ "${MOZ_LIGHTNING_VER}" != "${THIS_MOZ_LIGHTNING_VER}" ]]; then
		eqawarn "The version of lightning used for localization differs from the version"
		eqawarn "in thunderbird.  Please update MOZ_LIGHTNING_VER in the ebuild from ${MOZ_LIGHTNING_VER}"
		eqawarn "to ${THIS_MOZ_LIGHTNING_VER}"
	fi

	eautoreconf
	# Ensure we run eautoreconf in mozilla to regenerate configure
	cd "${S}/mozilla" || die "cd failed"
	eautoconf
	cd "${S}/mozilla/js/src" || die "cd failed"
	eautoconf
}

src_configure() {
	MEXTENSIONS="default"

	####################################
	#
	# mozconfig, CFLAGS and CXXFLAGS setup
	#
	####################################

	mozconfig_init
	mozconfig_config

	# It doesn't compile on alpha without this LDFLAGS
	use alpha && append-ldflags "-Wl,--no-relax"

	# Add full relro support for hardened
	use hardened && append-ldflags "-Wl,-z,relro,-z,now"

	mozconfig_annotate '' --enable-extensions="${MEXTENSIONS}"
	mozconfig_annotate '' --enable-calendar

	# Other tb-specific settings
	mozconfig_annotate '' --with-user-appdir=.thunderbird

	mozconfig_use_enable ldap
	mozconfig_use_enable rust

	mozlinguas_mozconfig

	# Bug #72667
	if use mozdom; then
		MEXTENSIONS="${MEXTENSIONS},inspector"
	fi

	# Use an objdir to keep things organized.
	echo "mk_add_options MOZ_OBJDIR=${BUILD_OBJ_DIR}" >> "${S}/.mozconfig"
	echo "mk_add_options XARGS=/usr/bin/xargs" >> "${S}/.mozconfig"

	# Finalize and report settings
	mozconfig_final

	####################################
	#
	#  Configure and build
	#
	####################################

	# Disable no-print-directory
	MAKEOPTS="${MAKEOPTS/--no-print-directory/}"

	if [[ $(gcc-major-version) -lt 4 ]]; then
		append-cxxflags -fno-stack-protector
	fi

	# workaround for funky/broken upstream configure...
	SHELL="${SHELL:-${EPREFIX}/bin/bash}" \
	emake V=1 -f client.mk configure
}

src_compile() {
	MOZ_MAKE_FLAGS="${MAKEOPTS}" SHELL="${SHELL:-${EPREFIX}/bin/bash}" \
	emake V=1 -f client.mk
}

src_install() {
	declare emid
	cd "${BUILD_OBJ_DIR}" || die "cd failed"

	# Pax mark xpcshell for hardened support, only used for startupcache creation.
	pax-mark m "${BUILD_OBJ_DIR}/dist/bin/xpcshell"

	# Copy our preference before omnijar is created.
	cp "${FILESDIR}/thunderbird-gentoo-default-prefs-1.js-1" \
		"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js" \
		|| die "cp failed"

	mozconfig_install_prefs \
		"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js"

	# dev-db/sqlite does not have FTS3_TOKENIZER support.
	# gloda needs it to function, and bad crashes happen when its enabled and doesn't work
	if in_iuse system-sqlite && use system-sqlite; then
		echo "sticky_pref(\"mailnews.database.global.indexer.enabled\", false);" \
			>>"${BUILD_OBJ_DIR}/dist/bin/defaults/pref/all-gentoo.js" || die "echo failed"
	fi

	MOZ_MAKE_FLAGS="${MAKEOPTS}" \
	emake DESTDIR="${D}" install

	# Install language packs
	mozlinguas_src_install

	local size sizes icon_path icon
	if ! use bindist; then
		icon_path="${S}/other-licenses/branding/thunderbird"
		icon="${PN}-icon"

		domenu "${FILESDIR}/icon/${PN}.desktop"
	else
		icon_path="${S}/mail/branding/aurora"
		icon="${PN}-icon-unbranded"

		newmenu "${FILESDIR}/icon/${PN}-unbranded.desktop" \
			"${PN}.desktop"

		sed -i -e "s:Mozilla Thunderbird:EarlyBird:g" \
			"${ED}/usr/share/applications/${PN}.desktop"
	fi

	# Install a 48x48 icon into /usr/share/pixmaps for legacy DEs
	newicon "${icon_path}/mailicon48.png" "${icon}.png"
	# Install icons for menu entry
	sizes="16 22 24 32 48 256"
	for size in ${sizes}; do
		newicon -s "${size}" "${icon_path}/mailicon${size}.png" "${icon}.png"
	done

	local emid
	# stage extra locales for lightning and install over existing
	mozlinguas_xpistage_langpacks "${BUILD_OBJ_DIR}/dist/xpi-stage/lightning" \
		"${WORKDIR}/lightning-${MOZ_LIGHTNING_VER}" lightning calendar

	emid='{e2fda1a4-762b-4020-b5ad-a41df1933103}'
	mkdir -p "${T}/${emid}" || die "sed failed"
	cp -RLp -t "${T}/${emid}" "${BUILD_OBJ_DIR}/dist/xpi-stage/lightning"/* || die "cp failed"
	insinto "${MOZILLA_FIVE_HOME}/distribution/extensions"
	doins -r "${T}/${emid}"

	if use lightning; then
		# move lightning out of distribution/extensions and into extensions for app-global install
		mv "${ED}/${MOZILLA_FIVE_HOME}"/{distribution,}/extensions/${emid} || die "doins failed"

		# stage extra locales for gdata-provider and install app-global
		mozlinguas_xpistage_langpacks "${BUILD_OBJ_DIR}/dist/xpi-stage/gdata-provider" \
			"${WORKDIR}/gdata-provider-${MOZ_LIGHTNING_GDATA_VER}"
		emid='{a62ef8ec-5fdc-40c2-873c-223b8a6925cc}'
		mkdir -p "${T}/${emid}" || die "doins failed"
		cp -RLp -t "${T}/${emid}" "${BUILD_OBJ_DIR}/dist/xpi-stage/gdata-provider"/* || die "cp failed"
		insinto "${MOZILLA_FIVE_HOME}/extensions"
		doins -r "${T}/${emid}"
	fi

	# Required in order to use plugins and even run thunderbird on hardened.
	pax-mark pm "${ED}${MOZILLA_FIVE_HOME}"/{thunderbird,thunderbird-bin,plugin-container}

	if use minimal; then
		# shellcheck disable=SC2115
		rm -r "${ED}/usr/include" "${ED}${MOZILLA_FIVE_HOME}"/{idl,include,lib,sdk} || \
			die "Failed to remove sdk and headers"
	fi
}

pkg_preinst() {
	gnome2_icon_savelist
}

pkg_postinst() {
	xdg_desktop_database_update
	gnome2_icon_cache_update

	if use crypt; then
		elog
		elog "USE=crypt will be dropped from thunderbird with version 52.6.0 as"
		elog "x11-plugins/enigmail-1.9.8.3-r1 and above is now a fully standalone"
		elog "package.  For continued enigmail support in thunderbird please add"
		elog "x11-plugins/enigmail to your @world set."
	fi

	elog
	elog "If you experience problems with plugins please issue the"
	elog "following command : rm \${HOME}/.thunderbird/*/extensions.sqlite ,"
	elog "then restart thunderbird"

	if ! use lightning; then
		elog
		elog "If calendar fails to show up in extensions please open config editor"
		elog "and set extensions.lastAppVersion to 38.0.0 to force a reload. If this"
		elog "fails to show the calendar extension after restarting with above change"
		elog "please file a bug report."
	fi
}

pkg_postrm() {
	xdg_desktop_database_update
	gnome2_icon_cache_update
}
